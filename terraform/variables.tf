variable "region" {
  default = "us-east-1"
  type = string
}

variable "aws_ec2_instance_type" {
  default = "t3.micro"
  type = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-020cba7c55df1f615" # Ubuntu 22.04 for us-east-1
  type        = string
}

variable "jenkins_port" {
  default = 8080
}

variable "jenkins_instance_type" {
  default = "t3.micro"
  type    = string
}