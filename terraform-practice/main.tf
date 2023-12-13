provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main vpc"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "main subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main Internet gateway"
  }
}



resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "private route table"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "public route table"
  }

}


resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

}


resource "aws_security_group" "main_sg" {
  name   = "allow_http"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

 

  tags = {
    Name = "main security group"
  }
}


resource "aws_instance" "main_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.main_subnet.id
  vpc_security_group_ids      = [aws_security_group.main_sg.id]
  associate_public_ip_address = true

  user_data = file("./user_data.sh")

  tags = {
    Name = "main server"
  }
}


# secondary volume to be attached to the main server
resource "aws_ebs_volume" "secondary_volume"{
  availability_zone = "us-east-1a"
  encrypted = "true"
  type = "gp3"
  size = 100

  tags = {
    Name = "secondary ebs volume"
  }

}


# attach the volume to the web server
resource "aws_volume_attachment" "attach_volume"{
  instance_id = aws_instance.main_server.id
  volume_id = aws_ebs_volume.secondary_volume.id
  device_name = "/dev/sdf"
}