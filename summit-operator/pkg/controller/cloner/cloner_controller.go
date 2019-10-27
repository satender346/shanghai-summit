package cloner

import (
	"context"
	"fmt"
	"time"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller"
	"sigs.k8s.io/controller-runtime/pkg/event"
	"sigs.k8s.io/controller-runtime/pkg/predicate"

	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/handler"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
	logf "sigs.k8s.io/controller-runtime/pkg/runtime/log"
	"sigs.k8s.io/controller-runtime/pkg/source"

	clonerv1alpha1 "github.com/example-inc/pkg/apis/cloner/v1alpha1"
)

var log = logf.Log.WithName("controller_cloner")

// Add creates a new Cloner Controller and adds it to the Manager. The Manager will set fields on the Controller
// and Start it when the Manager is Started.
func Add(mgr manager.Manager) error {
	return add(mgr, newReconciler(mgr))
}

// newReconciler returns a new reconcile.Reconciler
func newReconciler(mgr manager.Manager) reconcile.Reconciler {
	return &ReconcileCloner{client: mgr.GetClient(), scheme: mgr.GetScheme()}
}

// add adds a new Controller to mgr with r as the reconcile.Reconciler
func add(mgr manager.Manager, r reconcile.Reconciler) error {
	// Create a new controller
	c, err := controller.New("cloner-controller", mgr, controller.Options{Reconciler: r})
	if err != nil {
		return err
	}

	// Watch for changes to primary resource Cloner
	err = c.Watch(&source.Kind{Type: &clonerv1alpha1.Cloner{}}, &handler.EnqueueRequestForObject{})
	if err != nil {
		return err
	}

	// Watch for changes to secondary resource Pods and requeue the owner Cloner
	err = c.Watch(&source.Kind{Type: &corev1.Pod{}},
		&handler.EnqueueRequestForOwner{
			IsController: true,
			OwnerType:    &clonerv1alpha1.Cloner{},
		},
		predicate.Funcs{
			// We only care about the deletion of our owned Pods,
			// so let's ignore create and update events
			DeleteFunc: func(_ event.DeleteEvent) bool { return true },
			CreateFunc: func(_ event.CreateEvent) bool { return true },
			UpdateFunc: func(_ event.UpdateEvent) bool { return false },
		},
	)
	if err != nil {
		return err
	}

	return nil
}

// blank assignment to verify that ReconcileCloner implements reconcile.Reconciler
var _ reconcile.Reconciler = &ReconcileCloner{}

// ReconcileCloner reconciles a Cloner object
type ReconcileCloner struct {
	// This client, initialized using mgr.Client() above, is a split client
	// that reads objects from the cache and writes to the apiserver
	client client.Client
	scheme *runtime.Scheme
}

// Reconcile reads that state of the cluster for a Cloner object and makes changes based on the state read
// and what is in the Cloner.Spec
// Note:
// The Controller will requeue the Request to be processed again if the returned error is non-nil or
// Result.Requeue is true, otherwise upon completion it will remove the work from the queue.
func (r *ReconcileCloner) Reconcile(request reconcile.Request) (reconcile.Result, error) {
	reqLogger := log.WithValues("Request.Namespace", request.Namespace, "Request.Name", request.Name)

	// Fetch the Cloner instance
	instance := &clonerv1alpha1.Cloner{}
	err := r.client.Get(context.TODO(), request.NamespacedName, instance)
	if err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted after reconcile request.
			// Owned objects are automatically garbage collected. For additional cleanup logic use finalizers.
			// Return and don't requeue
			return reconcile.Result{}, nil
		}
		// Error reading the object - requeue the request.
		return reconcile.Result{}, err
	}
	podList := &corev1.PodList{}
	listOpts := client.MatchingLabels(instance.Spec.Selector.MatchLabels)
	err = r.client.List(context.TODO(), listOpts, podList)
	if err != nil {
		reqLogger.Info("Failed to list pods: %v", err.Error())
		return reconcile.Result{}, err
	}

	availablePods := getAvailablePods(podList)
	numMatchingPods := len(availablePods.Items)

	if int32(numMatchingPods) < instance.Spec.Clones {
		reqLogger.Info("NOT ENOUGH PODS", "Required", instance.Spec.Clones, "Actual", numMatchingPods)
		// Define a new Pod object
		pod := newPodForCR(instance)

		if err := controllerutil.SetControllerReference(instance, pod, r.scheme); err != nil {
			return reconcile.Result{}, err
		}

		reqLogger.Info("Creating a new Pod", "Pod.Namespace", pod.Namespace, "Pod.Name", pod.Name)
		err = r.client.Create(context.TODO(), pod)
		if err != nil {
			return reconcile.Result{}, err
		}
	} else if int32(numMatchingPods) > instance.Spec.Clones {
		reqLogger.Info("TOO MANY PODS", "Required", instance.Spec.Clones, "Actual", numMatchingPods)
		pod := availablePods.Items[0]

		reqLogger.Info("Deleting a Pod", "Pod.Namespace", pod.Namespace, "Pod.Name", pod.Name)
		err := r.client.Delete(context.TODO(), &pod)
		if err != nil {
			return reconcile.Result{}, err
		}
	} else {
		reqLogger.Info("Found a sufficient number of pods, ignoring this request")
	}

	return reconcile.Result{}, nil
}

// newPodForCR returns a pod with the same name/namespace as the cr, using the cr's PodTemplate
func newPodForCR(cr *clonerv1alpha1.Cloner) *corev1.Pod {
	uniqueName := fmt.Sprintf("%s-clone-%d", cr.Name, time.Now().UnixNano())
	pod := &corev1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			Name:      uniqueName,
			Namespace: cr.Namespace,
			Labels:    cr.Spec.Selector.MatchLabels,
		},
		Spec: *cr.Spec.Template.Spec.DeepCopy(),
	}
	return pod
}

func getAvailablePods(podList *corev1.PodList) *corev1.PodList {
	availablePods := &corev1.PodList{}
	for _, pod := range podList.Items {
		if isPodAvailable(&pod) {
			availablePods.Items = append(availablePods.Items, pod)
		}
	}
	return availablePods
}

func isPodAvailable(pod *corev1.Pod) bool {
	if pod.GetDeletionTimestamp() != nil {
		// This pod is being deleted
		return false
	}

	return pod.Status.Phase == corev1.PodPending || pod.Status.Phase == corev1.PodRunning
}
