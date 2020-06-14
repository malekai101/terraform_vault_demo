provider "aws" {
  region = var.region
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Project = var.project_name
    Name    = "App Server"
  }
}

resource "aws_subnet" "demo_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_security_group" "allow_vault_http" {
  name        = "allow_vault_http"
  description = "Allow vault inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Vault UI"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_vault_http"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}



resource "aws_instance" "application" {
  ami                    = var.linux_image_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.demo_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = var.key

  tags = {
    Project = var.project_name
    Name    = "App Server"
  }
}

resource "aws_instance" "vault" {
  ami                    = var.linux_image_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.demo_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_vault_http.id]
  key_name               = var.key

  tags = {
    Project = var.project_name
    Name    = "Vault Server"
  }
}

resource "aws_db_subnet_group" "db_subnet" {
  subnet_ids = [aws_subnet.demo_subnet.id]

  tags = {
    Project = var.project_name
    Name    = "Database subnet"
  }
}


resource "aws_db_instance" "football_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  instance_class       = "db.t2.micro"
  name                 = "football"
  username             = var.db_user
  password             = var.db_pass
  db_subnet_group_name = aws_db_subnet_group.db_subnet.name
  tags = {
    Project = var.project_name
    Name    = "Database"
  }
}
