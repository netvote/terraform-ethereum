sudo yum install -y amazon-efs-utils
sudo mkdir -p ${directory}
sudo mount -t efs ${file_system_id}:/ ${directory}