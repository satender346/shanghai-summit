#!/bin/bash
set -ex
COMMAND="${@:-main}"

function create_user () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)========================= Create User =========================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  pass=$(perl -e 'print crypt($ARGV[0], "password")' summit)
  useradd -m -s /bin/bash -p $pass summit
  echo 'summit  ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
  [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  sed -i 's/#   PasswordAuthentication yes/   PasswordAuthentication yes/g' /etc/ssh/ssh_config
  service ssh reload

}

function install_kubernetes () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)===================== Install Kubernetes ======================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  apt-get update && apt-get -y install docker.io apt-transport-https
  systemctl enable docker.service
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  echo deb http://apt.kubernetes.io/ kubernetes-xenial main | tee /etc/apt/sources.list.d/kubernetes.list
  apt-get update && apt-get install -y kubelet kubeadm
  kubeadm init --node-name master --pod-network-cidr=10.244.0.0/16
  sleep 10

}

function setup_kubectl () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)======================== Setup Kubectl ========================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  su - summit -c "mkdir -p /home/summit/.kube"
  su - summit -c "sudo cp -i /etc/kubernetes/admin.conf /home/summit/.kube/config"
  su - summit -c "sudo chown summit:summit /home/summit/.kube/config"
  su - summit -c "kubectl taint nodes master node-role.kubernetes.io/master-"
  su - summit -c "kubectl apply -f  https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml"

}

function setup_go () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)========================== Setup Go ===========================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  su - summit -c "wget https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz"
  su - summit -c "tar -xvf go1.12.7.linux-amd64.tar.gz"
  su - summit -c "sudo mv go /usr/local"
  su - summit -c "echo 'export GOROOT=/usr/local/go' >> ~/.bashrc"
  su - summit -c "echo 'export GOPATH=/home/summit' >> ~/.bashrc"
  su - summit -c "echo 'export PATH=/home/summit/bin:/usr/local/go/bin:$PATH' >> ~/.bashrc"
  su - summit -c "go version >> /tmp/go_version"

}

function kubeadm_reset () {

  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  echo "$(tput setaf 2)======================= Kubeadm Reset =========================$(tput setaf 9)"
  echo "$(tput setaf 2)===============================================================$(tput setaf 9)"
  kubeadm reset --force
  if [[ $(docker rm $(sudo docker ps -qa)) ]]; then
      docker image rm -f $(sudo docker image list -qa)
  else
      echo "No Docker Images found"
  fi

}


function main () {

  create_user
  install_kubernetes
  setup_kubectl
  setup_go

}

if [ $# -eq 0 ]; then
  $COMMAND
else
  case $1 in
  create_user ) create_user
  ;;
  install_kubernetes ) install_kubernetes
  ;;
  setup_kubectl ) setup_kubectl
  ;;
  setup_go ) setup_go
  ;;
  kubeadm_reset ) kubeadm_reset
  ;;
  *)
  usage
  exit 1
  ;;
  esac
fi
