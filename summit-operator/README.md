# Overview

In this demo, we will build a GO-based Operator called Cloner. The project name is `openinfra-summit`. kind is `kind: Cloner`

## Goal

Create a simple Go-based Operator where the custom resource for the application is `Kind: Cloner`. Cloner is a simple nignx based application.

## Overview
- Create a project called `openinfra-summit` using the `operator-sdk` command line.

- The main program for the operator is `cmd/manager/main.go` that initializes and runs the Manager. The Manager will automatically register the scheme for all CR defined under `pkg/apis/...` and run all controllers under `pkg/controller/...`

- Add a new CRD API called Cloner, with APIVersion `kubedge.cloud.com/v1alpha1` and `Kind: Cloner` using the `operator-sdk` command line.

- Update `pkg/apis/kubedge/v1alpha1/cloner_types.go` as required with custom `Specs` and `Status` to deploy our application `Cloner`. After updating `cloner_types.go` run `operator-sdk generate k8s` and `operator-sdk generate openapi` to update the generated code for that resource type.

- Add a new Controller for our project `openinfra-summit` which watches and reconciles the `Cloner` resource, this is done using the operator-sdk command line. This will scaffold a new Controller implementation under `pkg/controller/cloner/`.

- Register our new CRD with Kubernetes APIServer.

- Setup RBAC and deploy `openinfra-summit`.

- Deploy our new CR or application called Cloner.

## Getting Started

Login to server with username `summit` and password as `summit`.

	ssh summit@IPADRESS

Naviagte to `/home/summit/src`

	cd /home/summit/src

## Steps to Execute

1. Step1 implements,
   1. Executes `operator-sdk new openinfra-summit` command to create a new Project called `openinfra-summit`.
   2. Executes `go mod tidy` from the folder the `openinfra-summit` folder to install all dependencies  required for `GO`.

			./operator.sh step1

2. Step2 implements,
   1. Executes `operator-sdk add api --api-version=kubedge.cloud.com/v1alpha1 --kind=Cloner` to add a new Custom Resource Definition API called Cloner with APIVersion kubedge.cloud.com/v1alpha1 and Kind Cloner.
   2. Modifies `pkg/apis/kubedge/v1alpha1/cloner_types.go` to define new fields for `Cloner` `spec` and `status`.
   3. Executes `operator-sdk generate k8s` after modifying the `cloner_types.go` file to update the generated code for that resource type.
   4. Executes `operator-sdk generate openapi` to automatically generate the OpenAPI validations.

			./operator.sh step2

3. Step3 implements,
   1. Executes `operator-sdk add controller --api-version=kubedge.cloud.com/v1alpha1 --kind=Cloner` to add a new Controller to the project that will watch and reconcile the `Cloner` resource.
   2. Execute `kubectl create -f deploy/crds/kubedge_v1alpha1_cloner_crd.yaml` to register the CRD with Kubernetes apiserver.
   3. Update `deploy/operator.yaml` with openinfra-summit image.

			./operator.sh step3

4. Step4 implements,
   1. Creates Service Account by executing `kubectl create -f deploy/service_account.yaml`.
   2. Creates Role by executing `kubectl create -f deploy/role.yaml`.
   3. Creates RoleBinding Account by executing `kubectl create -f deploy/role_binding.yaml`.
   4. Deploy openinfra-summit Controller `kubectl create -f deploy/operator.yaml`.

			./operator.sh step4

  Verify that the `openinfra-summit` Deployment is up and running:

	kubectl get deployment
	NAME               READY   UP-TO-DATE   AVAILABLE   AGE
	openinfra-summit   1/1     1            1           29m


5. Step5 implements,
   1. Update the CR to match with the latest template Spec.
   2. Create the Cloner CR that was generated at `kubectl apply -f deploy/crds/kubedge_v1alpha1_cloner_cr.yaml`

			./operator.sh step5

  Check if the pods and CR status to confirm the status is updated with the `Cloner` pod names

	kubectl get pods
	NAME                                READY   STATUS    RESTARTS   AGE
	summit-cloner-pod                   1/1     Running   0          7s
	openinfra-summit-5f5d76564d-f45tx   1/1     Running   0          25s

  Check our newly created operator called `Cloner` 

	kubectl get cloner
	NAME            AGE
	summit-cloner   10s

