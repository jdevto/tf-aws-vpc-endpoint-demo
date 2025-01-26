# Jumphost EC2 Instance
resource "aws_instance" "jumphost" {
  ami           = data.aws_ami.amzn2023.id
  instance_type = "t3.micro"
  subnet_id     = element(aws_subnet.private[*].id, 0)

  user_data = <<-EOF
    #!/bin/bash
    set -ex

    hostnamectl set-hostname jumphost
    yum update -y
    yum install -y nmap-ncat mtr
  EOF

  vpc_security_group_ids = [aws_security_group.ec2_connect.id]

  tags = { Name = "${local.name}-jumphost" }
}
