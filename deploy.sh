#! /bin/bash

sudo yum update -y && \
sudo yum install ruby wget -y && \
cd /home/ec2-user && \
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install && \
chmod +x ./install && \
sudo ./install auto && \
sudo systemctl enable codedeploy-agent