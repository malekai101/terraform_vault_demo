provider "aws" {
  region = var.region
}

data aws_ami "linux_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

data aws_ami "vault_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["csmith-vault*"]
  }

  owners = ["self"]
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Project = var.project_name
    Name    = "Football VPC"
  }
}

resource "aws_subnet" "demo_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Project = var.project_name
    Name    = "tf-example1"
  }
}

resource "aws_subnet" "db_only_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Project = var.project_name
    Name    = "tf-example2"
  }
}

resource "aws_internet_gateway" "main_gate" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Internet-gateway"
  }
}

resource "aws_route_table" "out_route" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gate.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.demo_subnet.id
  route_table_id = aws_route_table.out_route.id
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

resource "aws_security_group" "allow_pg" {
  name        = "allow_pg"
  description = "Allow pg traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "pg from demo"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.demo_subnet.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_db"
  }
}

resource "aws_eip" "application" {
  instance   = aws_instance.application.id
  vpc        = true
  depends_on = [aws_internet_gateway.main_gate]
}

resource "aws_eip_association" "application" {
  instance_id   = aws_instance.application.id
  allocation_id = aws_eip.application.id
}

resource "aws_instance" "application" {
  ami                         = data.aws_ami.linux_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.demo_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = var.key
  associate_public_ip_address = true

  tags = {
    Project = var.project_name
    Name    = "App Server"
  }
}

resource "aws_eip" "vault" {
  instance   = aws_instance.application.id
  vpc        = true
  depends_on = [aws_internet_gateway.main_gate]
}

resource "aws_eip_association" "vault" {
  instance_id   = aws_instance.vault.id
  allocation_id = aws_eip.vault.id
}

resource "aws_instance" "vault" {
  ami                         = data.aws_ami.vault_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.demo_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id, aws_security_group.allow_vault_http.id]
  key_name                    = var.key
  associate_public_ip_address = true

  tags = {
    Project = var.project_name
    Name    = "Vault Server"
  }
}

resource "aws_db_subnet_group" "db_subnet" {
  subnet_ids = [aws_subnet.demo_subnet.id, aws_subnet.db_only_subnet.id]

  tags = {
    Project = var.project_name
    Name    = "Database subnet group"
  }
}


resource "aws_db_instance" "football_db" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  instance_class         = "db.t2.micro"
  name                   = "football"
  username               = var.db_user
  password               = var.db_pass
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.allow_pg.id]
  skip_final_snapshot    = true
  tags = {
    Project = var.project_name
    Name    = "Database"
  }
}
