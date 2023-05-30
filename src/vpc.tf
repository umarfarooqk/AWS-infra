# vpc.tf 
# Create VPC/Subnet/Security Group/Network ACL
provider "aws" {
  version = "~> 3.0"
  access_key = var.access_key 
  secret_key = var.secret_key
  region     = var.region
}
# create the VPC
resource "aws_vpc" "My_VPC" {
  cidr_block           = var.vpcCIDRblock
  instance_tenancy     = var.instanceTenancy 
  enable_dns_support   = var.dnsSupport 
  enable_dns_hostnames = var.dnsHostNames
tags = {
    Name = "My VPC"
}
} # end resource
# create the Subnet
resource "aws_subnet" "My_VPC_Subnet" {
  vpc_id                  = aws_vpc.My_VPC.id
  cidr_block              = var.subnetCIDRblock
  map_public_ip_on_launch = var.mapPublicIP 
  availability_zone       = var.availabilityZone
tags = {
   Name = "My VPC Subnet"
}
} # end resource
# Create the Security Group
resource "aws_security_group" "My_VPC_Security_Group" {
  vpc_id       = aws_vpc.My_VPC.id
  name         = "My VPC Security Group"
  description  = "My VPC Security Group"
  
  # allow ingress of port 22
  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  } 

  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  } 

  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
  } 

  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  } 

  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
  } 
  
  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
   Name = "My VPC Security Group"
   Description = "My VPC Security Group"
}
} 
# Create the Internet Gateway
resource "aws_internet_gateway" "My_VPC_GW" {
 vpc_id = aws_vpc.My_VPC.id
 tags = {
        Name = "My VPC Internet Gateway"
}
} # end resource
# Create the Route Table
resource "aws_route_table" "My_VPC_route_table" {
 vpc_id = aws_vpc.My_VPC.id
 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.My_VPC_GW.id    
  }
 tags = {
        Name = "My VPC Route Table"
}
} # end resource
# Create the Internet Access
resource "aws_route" "My_VPC_internet_access" {
  route_table_id         = aws_route_table.My_VPC_route_table.id
  destination_cidr_block = var.destinationCIDRblock
  gateway_id             = aws_internet_gateway.My_VPC_GW.id
} # end resource
# Associate the Route Table with the Subnet
resource "aws_route_table_association" "My_VPC_association" {
  subnet_id      = aws_subnet.My_VPC_Subnet.id
  route_table_id = aws_route_table.My_VPC_route_table.id
} # end resource
# end vpc.tf

resource "aws_key_pair" "ec2-keys" {
  key_name   = "ec2-keys"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSbp8aFCuLVOKfEssmLi7Krf2phW4yAjQqvoY8RObtzNsf6uPbL5WCjB1QRaOchq1HdoYSntVK0uGwX17kEx5wweN2VKXU33fcUGOxmrK5mzq99AxYJ4QycqMk1Zvd+ND0JbHl3i44RgqwMVj1KEorS4oM/JDpa/f5VAnLD6/KnWVj+v0fEJ3c+nIcnMbZAWmoCOelPOpI095wvC5RLMNUjs5ZZyQfoXLJtLr5TI++LabI/r25oYTT++LMhenegrRK3/1I5tlhDz2dLBjvYB8fvTa7OeFTblazYaSC4tRNJQc9awRtTYTqGzIWw4yTkaOsuS5TC7G++0/jf9FDduIh Ummar.Kovvuru@SCS-MJ88"
}

resource "aws_instance" "web01" {
  ami = "ami-0889a44b331db0194"
  key_name = aws_key_pair.ec2-keys.key_name
  instance_type = "t2.micro"
  subnet_id = aws_subnet.My_VPC_Subnet.id
  security_groups = [aws_security_group.My_VPC_Security_Group.id]

  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo yum update -y
  sudo yum install -y httpd
  sudo systemctl start httpd
  sudo systemctl enable httpd
  echo "*** Completed Installing apache2"
  EOF
  
}

resource "aws_instance" "web02" {
  ami = "ami-0d86c69530d0a048e"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2-keys.key_name
  subnet_id = aws_subnet.My_VPC_Subnet.id
  security_groups = [aws_security_group.My_VPC_Security_Group.id]

  user_data = <<-EOF
    <powershell>
    $ErrorActionPreference = 'Stop'
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools -Verbose
    </powershell>
  EOF

}

resource "aws_ebs_volume" "vol1" {
  availability_zone = aws_instance.web01.availability_zone
  size = 1
  tags = {
     Name = "ebs vol1"
  }
}


resource "aws_volume_attachment" "attach_vol1" {
  device_name = "/dev/sdh"
  volume_id = aws_ebs_volume.vol1.id
  instance_id = aws_instance.web01.id
}


resource "aws_ebs_volume" "vol2" {
  availability_zone = aws_instance.web02.availability_zone
  size = 8
  tags = {
     Name = "ebs vol2"
  }
}

resource "aws_volume_attachment" "attach_vol2" {
  device_name = "xvdj"
  volume_id   = aws_ebs_volume.vol2.id
  instance_id = aws_instance.web01.id
}