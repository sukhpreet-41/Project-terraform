locals {
  ssh_user = "ubuntu"
  keyname = "awskey"
  private_key_path = "/home/sukh/Desktop/myFolder/projects/terraform/awskey.pem"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true



  tags = {
    "Name" = "dev"
  }

}

//creating public subnet 

resource "aws_subnet" "my_vpc_publicsubnet" {
  vpc_id                  = aws_vpc.my_vpc.id //appending id of VPC 
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  //labeling of vpc
  tags = {
    "name" = "dev-public"
  }

}

//creating internet gateway 

resource "aws_internet_gateway" "my_vpc_ig" {

  vpc_id = aws_vpc.my_vpc.id
  tags = {
    "Name" = "igw"
  }
}

//creating route table for vpv

resource "aws_route_table" "my_vpc_rt" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    "name" = "my_vpc_rt"
  }

}

//specifing route 

resource "aws_route" "name" {
  route_table_id         = aws_route_table.my_vpc_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_vpc_ig.id

}


// connecting vpc withh route table with route table association 

resource "aws_route_table_association" "my_vpc_rta" {
  subnet_id      = aws_subnet.my_vpc_publicsubnet.id
  route_table_id = aws_route_table.my_vpc_rt.id
}



//creating security group for vpc
resource "aws_security_group" "my_vpc_sg" {
  name        = "dev_sg"
  description = "dev security grp"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

//creating a key pair through ssh-keygen ; then assigning a key pair 
# resource "aws_key_pair" "my_vpc_key" {
#   key_name   = "my_vpc_key"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFkf6p/OI9bbu1bAdPyzIdNsWAYG82534lfRLGdQDx6xdPxsbYF8dy/sxS5qkkFUT/uqIOxRM/ZWMDEz8S3MlU8Cxus4/R/z/WyhxoAthF9uO6GgL3hMIdTScdlZp1S4my5oq6FPt6u6bLuzHXmqWfOEPe4HOIkh5cY6H+SYlCAuHfxxaPHNS/5qpHxNvujBOn41KMD3irhdDEggWCWFCcmQgHfvW3pBSSPN2ffszQZkaJHPRkSKJLPRl+YSseuL5oCeAH1INqx/c39pg7dQHjRBEHsIJYbMlnpEfVDxxnavJRFgyM/pJVnxLU0LdbvYr9da8pAHNrwMc2fTZFkKcznGI84kIvrFYlxBBuX02jHb00upYOQfZofiOpkkcCl6ravXSEpVjlNwWsAWr9se6n/vf2S4Bg4iyYwG6116pOVEcUC0ZVAvqhattd2vmrDxEnIpBClEh680Jzt8DjzPw0FLTY8ZlLitmBqmeA0hm178RrTgJFJ73OCwB63Di+72E= sukh@asus"
#  }


//ec2 instance configuration 

resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = local.keyname
  vpc_security_group_ids = [aws_security_group.my_vpc_sg.id]
  subnet_id              = aws_subnet.my_vpc_publicsubnet.id
  # user_data = file("${path.module}/userdata.txt")

  # user_data = file("${path.module}/userdata.sh")

  provisioner "remote-exec" {

    inline = [
      "echo 'wait until ssh is ready'"
    ]
    
  }

  connection {
    type = "ssh"
    user = local.ssh_user
    private_key = file("${path.module}/awskey.pem")
    host = aws_instance.dev_node.public_ip
  }

  provisioner "local-exec" {

    command = "ansible-playbook -i ${aws_instance.dev_node.public_ip}, --private-key ${local.private_key_path} nginx.yml"
    
  }


  tags = {
    "Name" = "dev-node" //instance name 

  }


  root_block_device {
    volume_size = 10 //specifing root volume to 10 
  }
}

