provider "aws" {
  region = var.region
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
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


resource "aws_instance" "application" {
  ami           = var.linux_image_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.demo_subnet.id

  tags = {
    Project = var.project_name
    Name    = "App Server"
  }
}

resource "aws_instance" "vault" {
  ami           = var.linux_image_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.demo_subnet.id

  tags = {
    Project = var.project_name
    Name    = "Vault Server"
  }
}

resource "aws_db_instance" "football_db" {
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "postgres"
  instance_class    = "db.t2.micro"
  name              = "football"
  username          = var.db_user
  password          = var.db_pass
  #vpc_security_group_ids = [data.main_vpc.id]
  tags = {
    Project = var.project_name
    Name    = "Database"
  }
}
