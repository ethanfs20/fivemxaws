#!/bin/bash
# ----------------------------------------------------------
#  ______ _           __  ____   __     __          _______ 
# |  ____(_)         |  \/  \ \ / /    /\ \        / / ____|
# | |__   ___   _____| \  / |\ V /    /  \ \  /\  / / (___  
# |  __| | \ \ / / _ \ |\/| | > <    / /\ \ \/  \/ / \___ \ 
# | |    | |\ V /  __/ |  | |/ . \  / ____ \  /\  /  ____) |
# |_|    |_| \_/ \___|_|  |_/_/ \_\/_/    \_\/  \/  |_____/ 
# ----------------------------------------------------------
# Author: Ethan Shearer | https://github.com/ethanfs20
# Date: 2023-01-01
# Description: This script will create a VPC, subnet, internet gateway, route table, key pair, and security group for a FiveM server.
# Version: 1.0.0
# -------------------------------------------- #
# __      __        _       _     _            #
# \ \    / /       (_)     | |   | |           #
#  \ \  / /_ _ _ __ _  __ _| |__ | | ___  ___  #
#   \ \/ / _` | '__| |/ _` | '_ \| |/ _ \/ __| #
#    \  / (_| | |  | | (_| | |_) | |  __/\__ \ #
#     \/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/ #
# -------------------------------------------- #                                                                                                              

Access_Key="REPLACE ME!!!" # Replace with your own Access Key
Secret_Access_Key="REPLACE ME!!!" # Replace with your own Secret Access Key
Default_Region_Name="us-east-1" # Region name for your AWS account (e.g. us-east-1). https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions
Default_Output_Format="json" # Output format for AWS CLI (e.g. json, text, table). https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-output-format.html
AMI_ID="ami-08e637cea2f053dfa" # AMI ID for the Amazon Linux 2 AMI. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html
Instance_Type="t2.medium" # Instance type for your EC2 instance. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
cidr_block="10.0.0.0/24" # CIDR block for your VPC. https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html
linux_user="ec2-user" # Linux user for your EC2 instance. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html
key_pair="MyKeyPair.pem" # Name of your key pair. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

printf "Checking if the key pair already exists...\n"
if [ -f $key_pair ]; then # Check if the key pair already exists.
  printf "Key pair already exists. Exiting script.\n" 
  exit 1 # Exit the script.
else
  echo "Key pair does not exist already. Continuing script."
fi

printf "Checking if the known_hosts file exists...\n"
if [ ! -f ~/.ssh/known_hosts ]; then # Check if the known_hosts file exists.
    touch ~/.ssh/known_hosts # Create the known_hosts file.
    chmod 600 ~/.ssh/known_hosts # Change the permissions of the known_hosts file.
fi

printf "Configuring AWS CLI...\n"
printf "$Access_Key\n$Secret_Access_Key\n$Default_Region_Name\n$Default_Output_Format" | aws configure # Configure AWS CLI with your credentials and default region name
echo ""
# ---------------------------------------------------------------------------------------------- #
# __      ___      _               _ _____      _            _        _____ _                 _  #
# \ \    / (_)    | |             | |  __ \    (_)          | |      / ____| |               | | #
#  \ \  / / _ _ __| |_ _   _  __ _| | |__) | __ ___   ____ _| |_ ___| |    | | ___  _   _  __| | #
#   \ \/ / | | '__| __| | | |/ _` | |  ___/ '__| \ \ / / _` | __/ _ \ |    | |/ _ \| | | |/ _` | #
#    \  /  | | |  | |_| |_| | (_| | | |   | |  | |\ V / (_| | ||  __/ |____| | (_) | |_| | (_| | #
#     \/   |_|_|   \__|\__,_|\__,_|_|_|   |_|  |_| \_/ \__,_|\__\___|\_____|_|\___/ \__,_|\__,_| #
# ---------------------------------------------------------------------------------------------- #
printf "Creating the virtual private cloud...\n"
create_vpc=$(aws ec2 create-vpc --cidr-block $cidr_block --query Vpc.VpcId --output text) # Create a VPC with the CIDR block specified.
printf "Virtual Private Cloud Identification: $create_vpc\n" # Print the VPC ID.
subnet=$(aws ec2 create-subnet --vpc-id $create_vpc --cidr-block $cidr_block --query Subnet.SubnetId --output text) # Create a subnet with the CIDR block specified.
printf "Subnet Identification: $subnet\n" # Print the subnet ID.
internet_gateway=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text) # Create an internet gateway.
printf "Internet Gateway Identification: $internet_gateway\n" # Print the internet gateway ID.
aws ec2 attach-internet-gateway --vpc-id $create_vpc --internet-gateway-id $internet_gateway # Attach the internet gateway to the VPC.
route_table=$(aws ec2 create-route-table --vpc-id $create_vpc --query RouteTable.RouteTableId --output text) # Create a route table.
printf "Route Table Identification: $route_table\n" # Print the route table ID.
aws ec2 create-route --route-table-id $route_table --destination-cidr-block 0.0.0.0/0 --gateway-id $internet_gateway >/dev/null # Create a route for the internet gateway.
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$create_vpc" >/dev/null # Describe the subnets in the VPC.
aws ec2 associate-route-table --subnet-id $subnet --route-table-id $route_table >/dev/null # Associate the route table with the subnet.
aws ec2 modify-subnet-attribute --subnet-id $subnet --map-public-ip-on-launch >/dev/null # Modify the subnet attribute to map public IP on launch.
# ------------------------------------------------------ #
#   _____ _____ _    _ _  __          _____      _       #
#  / ____/ ____| |  | | |/ /         |  __ \    (_)      #
# | (___| (___ | |__| | ' / ___ _   _| |__) |_ _ _ _ __  #
#  \___ \\___ \|  __  |  < / _ \ | | |  ___/ _` | | '__| #
#  ____) |___) | |  | | . \  __/ |_| | |  | (_| | | |    #
# |_____/_____/|_|  |_|_|\_\___|\__, |_|   \__,_|_|_|    #
#                                __/ |                   #
#                               |___/                    #
# ------------------------------------------------------ #
printf "Creating the key pair...\n"
aws ec2 create-key-pair --key-name MyKeyPair --query "KeyMaterial" --output text >$key_pair # Create a key pair and save it to a file.
chmod 400 $key_pair # Change the permissions of the key pair file.
# ---------------------------------------------------------------------- #
#  _____                      _ _          _____                         #
#  / ____|                    (_) |        / ____|                       #
# | (___   ___  ___ _   _ _ __ _| |_ _   _| |  __ _ __ ___  _   _ _ __   #
#  \___ \ / _ \/ __| | | | '__| | __| | | | | |_ | '__/ _ \| | | | '_ \  #
#  ____) |  __/ (__| |_| | |  | | |_| |_| | |__| | | | (_) | |_| | |_) | #
# |_____/ \___|\___|\__,_|_|  |_|\__|\__, |\_____|_|  \___/ \__,_| .__/  #
#                                     __/ |                      | |     #
#                                    |___/                       |_|     #
# ---------------------------------------------------------------------- #
printf "Creating the security group...\n"
security_group=$(aws ec2 create-security-group --group-name ssh-security-group --description "Security group for Minecraft access" --vpc-id $create_vpc | sed 's/[^sg]*\(sg[^ .]*\)/\1\n/g' | grep sg | sed 's/.$//') # Create a security group for SSH access.
printf "Security Group Identification: $security_group\n" # Print the security group ID.
aws ec2 authorize-security-group-ingress --group-id $security_group --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null # Authorize SSH access to the security group.
aws ec2 authorize-security-group-egress --group-id $security_group --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null # Authorize SSH access to the security group.
aws ec2 authorize-security-group-egress --group-id $security_group --protocol tcp --port 30120 --cidr 0.0.0.0/0 >/dev/null # Authorize FiveM access to the security group.
aws ec2 authorize-security-group-egress --group-id $security_group --protocol tcp --port 40120 --cidr 0.0.0.0/0 >/dev/null # Authorize FiveM txAdmin access to the security group.
aws ec2 authorize-security-group-ingress --group-id $security_group --protocol tcp --port 30120 --cidr 0.0.0.0/0 >/dev/null # Authorize FiveM access to the security group.
aws ec2 authorize-security-group-ingress --group-id $security_group --protocol tcp --port 40120 --cidr 0.0.0.0/0 >/dev/null # Authorize FiveM txAdmin access to the security group.
# ----------------------------------------------------------- #
#  ______ _____ ___  _____           _                        #
# |  ____/ ____|__ \|_   _|         | |                       #
# | |__ | |       ) | | |  _ __  ___| |_ __ _ _ __   ___ ___  #
# |  __|| |      / /  | | | '_ \/ __| __/ _` | '_ \ / __/ _ \ #
# | |___| |____ / /_ _| |_| | | \__ \ || (_| | | | | (_|  __/ #
# |______\_____|____|_____|_| |_|___/\__\__,_|_| |_|\___\___| #
# ----------------------------------------------------------- #
printf "Creating the instance...\n"
instance_id=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $Instance_Type --key-name MyKeyPair --security-group-ids $security_group --subnet-id $subnet --query 'Instances[*].InstanceId' --output text) # Create an EC2 instance with the AMI ID specified.
printf "Instance Identification: $instance_id\n" # Print the instance ID.
public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[*].Instances[*].PublicIpAddress' --output text) # Get the public IP address of the instance.
printf "Instance Public IPv4: $public_ip\n" # Print the public IP address of the instance.

printf "Waiting for the instance to boot up...\n"
sleep_time=120 # Sleep for 2 minutes to allow the instance to boot up.
interval=30 # Check every 30 seconds.
while [ "$sleep_time" -gt 0 ]; do # Wait for the instance to boot up.
    echo "Sleeping for $sleep_time seconds..." # Print the time left to sleep.
    sleep $interval # Sleep for the interval.
    sleep_time=$((sleep_time - interval)) # Subtract the interval from the sleep time.
done

printf "Remoting into the instance and configuring it...\n"
ssh-keyscan -H $public_ip >>~/.ssh/known_hosts # Add the public IP address of the instance to the known_hosts file.
ssh -i MyKeyPair.pem $linux_user@$public_ip << EOF 
cat << EOF2 > podman-compose.yml
---
version: '3'

services:
  fivem:
    image: docker.io/spritsail/fivem:latest
    container_name: fivem
    restart: always
    stdin_open: true
    tty: true
    volumes:
      - "/volumes/fivem:/config"
      - "/volumes/fivem:/txData"
    ports:
      - "30120:30120"
      - "30120:30120/udp"
      - "40120:40120"
    environment:
      LICENSE_KEY: "REPLACE MEEE!!"
      NO_DEFAULT_CONFIG: "true"
EOF2
sudo dnf update -y
sudo dnf install podman python3 firewalld python3-pip -y
pip3 install --user podman-compose
sudo systemctl enable --now firewalld
sudo firewall-cmd --zone=public --add-port=30120/tcp --permanent
sudo firewall-cmd --zone=public --add-port=30120/udp --permanent
sudo firewall-cmd --zone=public --add-port=40120/tcp --permanent
sudo firewall-cmd --reload
sudo mkdir -p /volumes/fivem
sudo chmod -R 777 /volumes/fivem
sudo chcon -R -t svirt_sandbox_file_t -l s0 /volumes/fivem
podman-compose up
EOF