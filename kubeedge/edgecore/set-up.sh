#!/bin/bash

# Script Name: pre_deployment_setup.sh
# Description: This script is used to perform pre-deployment setup tasks before installing the business application.

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}


# Function to install necessary packages
install_packages() {
    log_message "Install containerd ..."
    wget https://github.com/containerd/containerd/releases/download/v1.7.20/containerd-1.7.20-linux-amd64.tar.gz
    tar Cxzvf /usr/local  containerd-1.7.20-linux-amd64.tar.gz
    sudo mkdir /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml
    sudo curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service
    systemctl enable containerd 

    log_message "Install runc ..."
    wget https://github.com/opencontainers/runc/releases/download/v1.1.13/runc.amd64
    sudo install -m 755 runc.amd64 /usr/local/sbin/runc

    log_message "Install CNI ..."

    wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz 
    mkdir -p /opt/cni/bin
    tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.1.tgz



    log_message "Install nvidia-container-toolkit ..."

    # Nvidia-Container-Toolkit 
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    apt-get update
    
    apt-get install -y nvidia-container-toolkit
    nvidia-ctk runtime configure --runtime=containerd
    systemctl restart containerd


    log_message "download kubeedge"

    wget https://github.com/kubeedge/kubeedge/releases/download/v1.17.1/keadm-v1.17.1-linux-amd64.tar.gz
    tar -zxvf keadm-v1.17.1-linux-amd64.tar.gz
    cp keadm-v1.17.1-linux-amd64/keadm/keadm /usr/local/bin/keadm
    chmod +x /usr/local/bin/keadm

}

# Function to perform system checks
perform_system_checks() {
    log_message "Performing system checks..."
    ctr --version
    cat /etc/containerd/config.toml
    systemctl status containerd
}

configure() {
log_message "Configuring CNI"
mkdir -p /etc/cni/net.d/ 
cat >/etc/cni/net.d/10-containerd-net.conflist <<EOF
{
  "cniVersion": "1.0.0",
  "name": "containerd-net",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "promiscMode": true,
      "ipam": {
        "type": "host-local",
        "ranges": [
          [{
            "subnet": "10.244.0.0/16"
          }]
        ],
        "routes": [
          { "dst": "0.0.0.0/0" }
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {"portMappings": true}
    }
  ]
}
EOF

log_message "Configuring edgecore"
mkdir -p /etc/kubeedge/config
cat <<EOF | sudo tee /etc/kubeedge/config/edgecore.yaml
modules:
  edged:
    rootDirectory: /var/lib/kubelet
EOF

}

# Main function
main() {
    log_message "Starting pre-deployment setup..."

    install_packages

    configure

    perform_system_checks



    echo 'export CLOUD_CORE_ENDPOINT=124.243.152.69:10000 && TOKEN=580b9281b443cd2a85a6857f6f1b4b1206d6a51fa22890a2cdb642078ae51f80.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MjE2NjAxNTR9.QJUeoLLHmzNdHSjiYt-W6QyDZ_fni3V5oexTeRzKdO4 && keadm deprecated join --cloudcore-ipport=$CLOUD_CORE_ENDPOINT --kubeedge-version=1.17.1 --token=$TOKEN'

}
main
# CLOUD_CORE_ENDPOINT="your_cloud_core_endpoint" TOKEN="your_token"