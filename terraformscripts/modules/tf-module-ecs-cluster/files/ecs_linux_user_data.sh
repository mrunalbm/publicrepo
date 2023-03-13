#!/bin/bash

sudo amazon-linux-extras disable docker
sudo amazon-linux-extras install -y ecs; sudo systemctl enable --now ecs

echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=10m >> /etc/ecs/ecs.config
echo ECS_IMAGE_CLEANUP_INTERVAL=10m >> /etc/ecs/ecs.config

yum -y install perl-CPAN perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https unzip
chown ec2-user:ec2-user /home/ec2-user/aws-scripts-mon
echo "*/5 * * * * /home/ec2-user/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --auto-scaling=only" >> /var/spool/cron/ec2-user

# Install SSM Agent
curl https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm > /home/ec2-user/amazon-ssm-agent.rpm
yum install -y /home/ec2-user/amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
