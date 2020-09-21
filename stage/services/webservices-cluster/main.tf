terraform {
  backend "s3" {
    key = "stage/services/webservices-cluster/terraform.tfstate"
  }
}

provider "aws" {  
region = "us-east-2"
shared_credentials_file = "~/.aws/credentials"
}

data "template_file" "user_data" {
  template = file("user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}


resource "aws_instance" "example" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data               = data.template_file.user_data.rendered

  tags = {
    Name = "terraform-example"
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "tf-state-2020"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}