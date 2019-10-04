provider "aws" {
  profile = "default"
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }

  owners = [
    "099720109477"]
  # Canonical
}

resource "aws_instance" "grafana-instance" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.grafana-key.key_name

  tags = {
    Name = "grafana-instance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y adduser libfontconfig1",
      "wget https://dl.grafana.com/oss/release/grafana_6.4.1_amd64.deb",
      "sudo dpkg -i grafana_6.4.1_amd64.deb",
//      "sudo setcap 'cap_net_bind_service=+ep' /usr/sbin/grafana-server", //Run grafana on port 80
      "sudo service grafana-server start"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("~/.ssh/grafana_instance")
      host = aws_instance.grafana-instance.public_ip
    }
  }

  security_groups = [
    aws_security_group.allow_ssh.name,
    aws_security_group.allow_grafana.name,
    aws_security_group.allow_outbound.name
  ]
}

resource "aws_eip" "test-eip" {
  instance = aws_instance.grafana-instance.id
}

resource "aws_security_group" "allow_ssh" {
  name = "allow-ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_grafana" {
  name = "allow-grafana"
  description = "Allow  inbound traffic"

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_outbound" {
  name = "allow-all-outbound"
  description = "Allow all outbound traffic"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_key_pair" "grafana-key" {
  key_name = "grafana-key"
  public_key = file("grafana_instance.pub")
}

output "server-ip" {
  value = aws_eip.test-eip.public_ip
}