#!/bin/bash

sudo yum update -y 
sudo yum install docker git -y
sudo service docker start

# install amazon credential helper for pulling ECR images
git clone https://github.com/awslabs/amazon-ecr-credential-helper
cd amazon-ecr-credential-helper
sudo make docker
sudo cp bin/local/docker-credential-ecr-login /usr/bin/

# configure credential helper
cd ~
sudo echo '{"credsStore": "ecr-login"}' > ~/config.json
sudo mkdir -p /root/.docker
sudo cp ~/config.json /root/.docker/config.json

#sudo echo 'DOCKER_STORAGE_OPTIONS=--storage-opt dm.basesize=250G' > ~/docker-storage
#sudo cp ~/docker-storage /etc/sysconfig/docker-storage

#sudo service docker start

# install docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose