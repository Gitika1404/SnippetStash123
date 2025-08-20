provider "aws" {
  region = var.region
}

resource "aws_key_pair" "snippet_key" {
  key_name   = "snippetstash-key"
  public_key = file("${path.module}/snippetstash-key.pub")
}

resource "aws_security_group" "snippet_sg" {
  name        = "snippetstash-sg"
  description = "Allow SSH, HTTP, and Jenkins"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH access
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Web app
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Jenkins
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get default VPC (if needed)
data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "snippetstash_server" {
  ami                         = var.ami_id
  instance_type               = var.aws_ec2_instance_type
  vpc_security_group_ids      = [aws_security_group.snippet_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.snippet_key.key_name

  # Install Docker, Jenkins, then run your app's script
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu

              # Install Java for Jenkins
              sudo apt install fontconfig openjdk-21-jre -y

              # Install Jenkins
              sudo mkdir -p /etc/apt/keyrings
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null
              echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update
              sudo apt-get install -y jenkins
              sudo usermod -aG docker jenkins
              sudo systemctl enable jenkins
              sudo systemctl start jenkins

              # Run your application setup
              bash /home/ubuntu/script.sh
              EOF

  tags = {
    Name = "snippetstash-server"
  }
}
