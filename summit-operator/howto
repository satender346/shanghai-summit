export KUBECONFIG="$(kind get kubeconfig-path --name="operatorTest")"

operator-sdk build summit-operator:v1.0.0 && kind load docker-image --name operatorTest summit-operator:v1.0.0

ka deploy/crds/cloner_v1alpha1_cloner_crd.yaml

kubectl create -f deploy/service_account.yaml
kubectl create -f deploy/role.yaml
kubectl create -f deploy/role_binding.yaml
kubectl create -f deploy/operator.yam

k logs -f summit-operator-57c778b68-xxt7k

ka deploy/crds/cloner_v1alpha1_cloner_cr.yaml

kgpo

krm -f deploy/crds/cloner_v1alpha1_cloner_cr.yaml

kubectl delete -f deploy/service_account.yaml
kubectl delete -f deploy/role.yaml
kubectl delete -f deploy/role_binding.yaml
kubectl delete -f deploy/operator.yaml
