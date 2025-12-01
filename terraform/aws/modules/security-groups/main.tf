# Security Groups Module - Creates security groups for WireGuard VPN server

resource "aws_security_group" "wireguard" {
  name_prefix = "${var.name_prefix}-wireguard-"
  description = "Security group for WireGuard VPN server"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-wireguard-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# WireGuard UDP port
resource "aws_vpc_security_group_ingress_rule" "wireguard" {
  security_group_id = aws_security_group.wireguard.id
  description       = "WireGuard VPN UDP port"

  from_port   = var.wireguard_port
  to_port     = var.wireguard_port
  ip_protocol = "udp"
  cidr_ipv4   = "0.0.0.0/0" # WireGuard clients can be anywhere
}

# SSH access (optional, prefer SSM Session Manager)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count = length(var.allowed_ssh_cidrs) > 0 ? length(var.allowed_ssh_cidrs) : 0

  security_group_id = aws_security_group.wireguard.id
  description       = "SSH access from ${var.allowed_ssh_cidrs[count.index]}"

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_ssh_cidrs[count.index]
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.wireguard.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
