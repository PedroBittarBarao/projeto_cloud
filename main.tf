terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_instance" "app_server" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
 name      = "my_db_subnet_group"
 subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]

 tags = {
   Name = "My DB subnet group"
 }
}


resource "aws_security_group" "ec2_sg" {
 name       = "ec2_sg"
 description = "Allow inbound traffic from EC2 instances"

 ingress {
   from_port  = 22
   to_port    = 22
   protocol   = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }

 egress {
   from_port  = 0
   to_port    = 0
   protocol   = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_security_group" "rds_sg" {
 name       = "rds_sg"
 description = "Allow inbound traffic from EC2 instances"

 ingress {
   from_port  = 3306
   to_port    = 3306
   protocol   = "tcp"
   security_groups = [aws_security_group.ec2_sg.id]
 }

 egress {
   from_port  = 0
   to_port    = 0
   protocol   = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_db_instance" "default" {
 allocated_storage   = 20
 storage_type        = "gp2"
 engine              = "mysql"
 engine_version      = "5.7"
 instance_class      = "db.t2.micro"
 db_name                = "mydb"
 username            = "dbuser"
 password            = "dbpassword"
 parameter_group_name = "default.mysql5.7"
 backup_retention_period = 7
 maintenance_window  = "Mon:00:00-Mon:03:00"
 multi_az            = true
 vpc_security_group_ids = [aws_security_group.rds_sg.id]
 db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
 skip_final_snapshot = true
}





