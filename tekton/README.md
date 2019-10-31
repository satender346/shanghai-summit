# Overview

In this demo, we will go through the basics of Google Tekton and build Tekton pipeline to build container images using Kaniko and publish them to dockerhub.

## Goal

Creating a pipeline for building and publishing Container images.

## Overview
Tekton Pipelines is an OpenSource project by Google to Build, Run and Maintain CI/CD pipelines for Kubernetes Apps and provides k8s-style resources declaration for CI/CD-style pipelines. Tekton Pipelines are built using Kubernetes CRD’s, it is based on Operator model.

- Steps are fundamental blocks of Pipelines. A step is actually an instance of an image and it is Kubernetes container spec. step contains the actual work to be done.

- Tasks contain a series of steps to be executed in sequential order on the same node, so they can share resources i.e. output/artifacts/parameters of one step to another. Tasks can exist and be invoked completely independently of Pipelines; they are highly cohesive and loosely coupled. Tasks can be invoked via TaskRuns

- Pipelines lets you put together the tasks, so they can run concurrently/Sequentially. They are not guaranteed to execute on the same node, it depends on K8S’s scheduling of pods. But you can have inputs for one task that come from the output of another task, which is specified in the pipeline. They can be triggered by events or by manually creating PipelineRuns

- Pipelines and tasks are declared once and they are used again and again. We create TaskRuns and PipelineRuns to invoke Tasks and PipelineRuns.

- PipelineResources are the artifacts used as inputs and outputs of Tasks.


## Getting Started

Login to server with username `summit` and password as `summit`.

	ssh summit@IPADRESS

Naviagte to `/home/summit/src`

	cd /home/summit/src/shanghai-summit/tekton

Let’s set your name variable as a environment variable, So docker image can be pushed with your name as tag. Note: Replace <username> with your name.

	export name=<YOURNAME>
	Example: export name=chris

## Steps to Execute

1. Install Tekton. This command downloads and Installs `v0.7.0` version of Tekton

		./tekton.sh deploy_tekton

2. Create Docker Registry Secret and Service Account

		./tekton.sh docker_registry

3. Now create `PipelineResource` for Github and DockerHub. Here we specify our git repository and Project in DockerHub where images are pushed

		./tekton.sh create_PipelineResource

4. Now Create a `Task` which downloads our repo specified in above step from github and using the `Dockerfile` from the downloaded repo, it builds Image using kaniko.

		./tekton.sh create_Task

5. Now Create `TaskRun` to run above pipeline

		./tekton.sh create_TaskRun

6. To see all the resource created so far as part of Tekton Pipelines, run the command

		kubectl get tekton-pipelines

`welcome` image is pushed with your name as tag. Check [DockerHub](https://hub.docker.com/r/summit2019/welcome/tags "DockerHub") for the image with your tag  
