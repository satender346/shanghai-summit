#!/bin/bash
set +e

BASEPATH=$HOME/src
OPENINFRAPATH=$HOME/src/openinfra-summit

function step1 () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)=========================== Step1 =============================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"

  printf "$(tput setaf 2)Runs 'operator-sdk new openinfra-summit' command to create new project called openinfra-summit \n \n$(tput setaf 9)"
  cd $BASEPATH
  operator-sdk new openinfra-summit
  cd $OPENINFRAPATH
  printf "$(tput setaf 2)Runs 'go mod tidy' to install dependencies \n \n$(tput setaf 9)"
  go mod tidy

}


function step2 () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)============================ Step2 ============================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"

  printf "$(tput setaf 2)Executes 'operator-sdk add api --api-version=kubedge.cloud.com/v1alpha1 --kind=Cloner' to add a new Custom Resource Definition API called Cloner \n
      with APIVersion kubedge.cloud.com/v1alpha1 and Kind Cloner \n \n$(tput setaf 9)"
  cd $OPENINFRAPATH
  operator-sdk add api --api-version=kubedge.cloud.com/v1alpha1 --kind=Cloner

  printf "$(tput setaf 2)Modify pkg/apis/kubedge/v1alpha1/cloner_types.go to define new fields for Cloner spec and status \n \n$(tput setaf 9)"
  wget https://raw.githubusercontent.com/kvenkata986/shanghai-summit/master/summit-operator/pkg/apis/cloner/v1alpha1/cloner_types.go -O $OPENINFRAPATH/pkg/apis/kubedge/v1alpha1/cloner_types.go
  printf "$(tput setaf 2)Executes 'operator-sdk generate k8s' after modifying the cloner_types.go file to update the generated code for that resource type \n \n$(tput setaf 9)"
  operator-sdk generate k8s

  printf "$(tput setaf 2)Executes 'operator-sdk generate openapi' to automatically generate the OpenAPI validations \n \n$(tput setaf 9)"
  operator-sdk generate openapi

}

function step3 () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)============================ Step3 ============================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"

  printf "$(tput setaf 2)Executes 'operator-sdk add controller --api-version=kubedge.cloud.com/v1alpha1 --kind=Cloner' to add a new Controller to the project that will watch and reconcile the Cloner resource \n \n$(tput setaf 9)"
  cd $OPENINFRAPATH
  operator-sdk add controller --api-version=kubedge.cloud.com/v1alpha1 --kind=Cloner

  printf "$(tput setaf 2)Execute 'kubectl create -f deploy/crds/kubedge_v1alpha1_cloner_crd.yaml' to register the CRD with Kubernetes apiserver \n \n$(tput setaf 9)"
  kubectl create -f deploy/crds/kubedge_v1alpha1_cloner_crd.yaml

  printf "$(tput setaf 2)Update 'deploy/operator.yaml' with openinfra-summit image \n \n$(tput setaf 9)"
  sed -i 's|REPLACE_IMAGE|kvenkata986/shanghai-summit:v0.0.2|g' deploy/operator.yaml

}

function step4 () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)============================ Step4 ============================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"

  cd $OPENINFRAPATH

  printf "$(tput setaf 2)Creates Service Account by executing 'kubectl create -f deploy/service_account.yaml' \n \n$(tput setaf 9)"
  kubectl create -f deploy/service_account.yaml

  printf "$(tput setaf 2)Creates Role by executing 'kubectl create -f deploy/role.yaml' \n \n$(tput setaf 9)"
  kubectl create -f deploy/role.yaml

  printf "$(tput setaf 2)Creates RoleBinding Account by executing 'kubectl create -f deploy/role_binding.yaml' \n \n$(tput setaf 9)"
  kubectl create -f deploy/role_binding.yaml

  printf "$(tput setaf 2)Deploy openinfra-summit Controller 'kubectl create -f deploy/operator.yaml' \n \n$(tput setaf 9)"
  kubectl create -f deploy/operator.yaml

}

function step5 () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)============================ Step5 ============================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"

  cd $OPENINFRAPATH
  printf "$(tput setaf 2)Update the CR to match with latest temaplate Spec \n \n$(tput setaf 9)"
  wget https://raw.githubusercontent.com/kvenkata986/shanghai-summit/master/summit-operator/deploy/crds/cloner_v1alpha1_cloner_cr.yaml -O $OPENINFRAPATH/deploy/crds/kubedge_v1alpha1_cloner_cr.yaml
  printf "$(tput setaf 2)Create the example Cloner CR that was generated at deploy/crds/kubedge_v1alpha1_cloner_cr.yaml \n \n$(tput setaf 9)"
  sed -i 's|cloner.example.com|kubedge.cloud.com|g' deploy/crds/kubedge_v1alpha1_cloner_cr.yaml
  sed -i 's|example|summit-cloner|g' deploy/crds/kubedge_v1alpha1_cloner_cr.yaml
  kubectl apply -f  deploy/crds/kubedge_v1alpha1_cloner_cr.yaml

}


function main () {

  step1
  step2
  step3
  step4
  step5

}

if [ $# -eq 0 ]; then
  $COMMAND
else
  case $1 in
  step1 ) step1
  ;;
  step2 ) step2
  ;;
  step3 ) step3
  ;;
  step4 ) step4
  ;;
  step5 ) step5
  ;;
  *)
  usage
  exit 1
  ;;
  esac
fi
