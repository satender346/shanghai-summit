package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	corev1 "k8s.io/api/core/v1"
)

// Important: Run "operator-sdk generate k8s" to regenerate code after modifying this file

// ClonerSpec defines the desired state of Cloner
// +k8s:openapi-gen=true
type ClonerSpec struct {
	// Clones is the number of desired clones.
	Clones int32 `json:"clones"`

	// Selector is a label query over pods that should match the clone count.
	// Must match in order to be controlled.
	// If empty, defaulted to labels on pod template.
	// +optional
	Selector *metav1.LabelSelector `json:"selector"`

	// Template is the object that describes the pod that will be created if
	// insufficient clones are detected.
	// +optional
	Template corev1.PodTemplateSpec `json:"template"`
}

// ClonerStatus defines the observed state of Cloner
// +k8s:openapi-gen=true
type ClonerStatus struct {
	// Clones is the number of actual clones.
	Clones int32 `json:"clones"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// Cloner is the Schema for the cloners API
// +k8s:openapi-gen=true
// +kubebuilder:subresource:status
type Cloner struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ClonerSpec   `json:"spec,omitempty"`
	Status ClonerStatus `json:"status,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// ClonerList contains a list of Cloner
type ClonerList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Cloner `json:"items"`
}

func init() {
	SchemeBuilder.Register(&Cloner{}, &ClonerList{})
}
