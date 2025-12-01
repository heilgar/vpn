# WireGuard VPN Infrastructure

Automated WireGuard VPN server deployment on AWS using Terraform and Ansible.

## Architecture

- **Terraform**: Provisions AWS infrastructure (VPC, EC2, IAM, Security Groups)
- **Ansible**: Configures WireGuard VPN server with security hardening
- **State Management**: S3 backend with native state locking

## Prerequisites

- AWS account with appropriate permissions
- Terraform >= 1.5.0
- Ansible >= 2.14
- AWS CLI configured
- WireGuard client tools

## Quick Start

### 1. Bootstrap S3 Backend

```bash
cd terraform/aws/bootstrap
terraform init
terraform apply
```

### 2. Deploy Infrastructure

```bash
cd ../
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration

terraform init
terraform plan
terraform apply
```

### 3. Generate WireGuard Keys

**CRITICAL**: Each peer (server and clients) MUST have unique key pairs. Never share private keys between peers.

```bash
cd ../../ansible

# Create vault password file
echo "your-secure-vault-password" > .vault_pass
chmod 600 .vault_pass

# Generate SERVER keys
wg genkey | tee server_private.key | wg pubkey > server_public.key

# Generate CLIENT 1 (m1) keys
wg genkey | tee client1_private.key | wg pubkey > client1_public.key
wg genpsk > client1_psk.key

# Generate CLIENT 2 (p1) keys
wg genkey | tee client2_private.key | wg pubkey > client2_public.key
wg genpsk > client2_psk.key

# Save keys securely (you'll need them for client configs)
echo "Server Public Key: $(cat server_public.key)"
echo "Client 1 Private Key: $(cat client1_private.key)"
echo "Client 2 Private Key: $(cat client2_private.key)"

# Create encrypted vault
ansible-vault create group_vars/all/vault.yml --vault-password-file .vault_pass
```

Add to `group_vars/all/vault.yml`:
```yaml
vault_wg_server_private_key: "<content of server_private.key>"
vault_wg_peer_m1_public_key: "<content of client1_public.key>"
vault_wg_peer_m1_preshared_key: "<content of client1_psk.key>"
vault_wg_peer_p1_public_key: "<content of client2_public.key>"
vault_wg_peer_p1_preshared_key: "<content of client2_psk.key>"
```

### 4. Configure Network Interface

Update `ansible/group_vars/all/vars.yml` with your server's primary network interface:
```yaml
wg_out_iface: "ens5"  # Change to your actual interface (eth0, ens5, etc.)
```

To find your interface on the server:
```bash
# SSH into server and run:
ip route | grep default  # Look for 'dev <interface_name>'
# or
ip addr show  # Find the interface with your public IP
```

### 5. Update Ansible Inventory

Get the public IP from Terraform output:
```bash
cd ../terraform/aws
terraform output instance_public_ip
```

Update `ansible/inventory/aws.ini`:
```ini
[wireguard_servers]
wireguard-server ansible_host=<PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/wireguard-vpn-key.pem
```

### 6. Deploy WireGuard Configuration

```bash
cd ../../ansible
ansible-playbook -i inventory/aws.ini playbooks/setup-wireguard.yml --vault-password-file .vault_pass
```

## Project Structure

```
.
├── ansible/
│   ├── group_vars/
│   │   ├── all.yml                    # Non-sensitive variables
│   │   ├── aws.yml                    # AWS-specific config
│   │   └── vault.yml                  # Encrypted secrets (create this)
│   ├── inventory/
│   │   └── aws.ini                    # Ansible inventory
│   ├── playbooks/
│   │   └── setup-wireguard.yml        # Main playbook
│   └── roles/
│       └── wireguard/
│           ├── tasks/
│           │   ├── main.yml           # Main tasks
│           │   └── security.yml       # Security hardening
│           ├── templates/
│           │   └── wg0.conf.j2        # WireGuard config template
│           └── handlers/
│               └── main.yml           # Service handlers
└── terraform/
    └── aws/
        ├── backend.tf                 # S3 backend config
        ├── main.tf                    # Root module
        ├── variables.tf               # Input variables
        ├── outputs.tf                 # Outputs
        ├── terraform.tfvars.example   # Example variables
        ├── bootstrap/                 # S3 backend setup
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── modules/
        │   ├── vpc/                   # VPC module
        │   ├── security-groups/       # Security groups module
        │   ├── iam/                   # IAM roles module
        │   └── ec2/                   # EC2 instance module
        └── templates/
            └── ansible-inventory.tpl  # Dynamic inventory template
```

## Accessing the Server

### SSM Session Manager (Recommended)
```bash
aws ssm start-session --target <INSTANCE_ID> --region us-east-1
```

### SSH (if enabled)
```bash
ssh -i ~/.ssh/wireguard-vpn-key.pem ubuntu@<PUBLIC_IP>
```

## Connecting to the VPN

### 1. Get Server Connection Details

From Terraform outputs:
```bash
cd terraform/aws
terraform output instance_public_ip
```

### 2. Create Client Configuration

**Client 1 (m1)** - Create at `/etc/wireguard/wg0.conf`:
```ini
[Interface]
PrivateKey = <client1_private.key content>
Address = 10.8.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = <server_public.key content>
PresharedKey = <client1_psk.key content>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

**Client 2 (p1)** - Create at `/etc/wireguard/wg0.conf`:
```ini
[Interface]
PrivateKey = <client2_private.key content>
Address = 10.8.0.3/32
DNS = 1.1.1.1

[Peer]
PublicKey = <server_public.key content>
PresharedKey = <client2_psk.key content>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

**Important**: Use the keys generated in step 3. Each client uses its OWN private key and the SERVER's public key.

### 3. Connect

**Linux/macOS:**
```bash
# Start VPN
sudo wg-quick up wg0

# Check status
sudo wg show

# Stop VPN
sudo wg-quick down wg0
```

**Windows/macOS GUI:**
1. Import the configuration file
2. Click "Activate" to connect

### 4. Verify Connection

```bash
# Check your public IP (should show VPN server IP)
curl ifconfig.me

# Ping VPN server
ping 10.8.0.1
```

## Cleanup

```bash
# Destroy infrastructure
cd terraform/aws
terraform destroy

# Remove backend (optional)
cd bootstrap
terraform destroy
```

## Security Best Practices

### Critical Security Requirements

1. **Unique Keys for Each Peer**:
   - NEVER share private keys between server and clients
   - Each client MUST have its own unique key pair
   - Rotate keys every 90 days

2. **Key Management**:
   ```bash
   # Generate unique keys for EACH peer
   wg genkey | tee private.key | wg pubkey > public.key

   # Store keys securely
   chmod 600 *.key
   ```

3. **Network Security**:
   - Restrict security group to specific IPs when possible
   - Use fail2ban to prevent brute force attacks
   - Enable VPC Flow Logs for audit trail

4. **Infrastructure Security**:
   - **Secrets Management**: All sensitive data in Ansible Vault
   - **Access Control**: Use SSM Session Manager (no SSH keys)
   - **Encryption**: EBS and CloudWatch Logs with KMS
   - **Monitoring**: VPC Flow Logs and CloudWatch alerts
   - **Updates**: Automatic security patches enabled
   - **Backups**: Automated daily snapshots with 7-day retention

5. **Additional Hardening**:
   - Enable MFA for AWS account access
   - Use separate AWS account for production
   - Implement CloudWatch alerts for suspicious activity
   - Regular security audits with AWS Security Hub

## Cost Estimate

- EC2 t4g.nano: ~$3/month (ARM-based Graviton2, $0.0042/hr)
- EBS 20GB: ~$2/month
- Data transfer: Variable (100GB/month free)
- Elastic IP: Free when attached
- CloudWatch Logs: ~$0.50/month
- S3 state storage: <$0.10/month

**Total**: ~$6/month (excluding additional data transfer)

**Note**: t4g.nano is NOT covered by AWS Free Tier. If using Free Tier, t4g.micro (~$0.60/month) is cheaper.

## Troubleshooting

### WireGuard Connection Not Working

1. **Check Key Configuration**:
   ```bash
   # On server
   sudo wg show
   # Verify each peer has UNIQUE public key
   ```

2. **Common Issues**:
   - **Same private key on server and client**: Each peer MUST have unique keys
   - **Duplicate public keys**: Each client needs its own key pair
   - **Wrong network interface**: Check `wg_out_iface` in vars.yml matches server's interface
   - **Broken iptables rules**: Ensure PostUp/PostDown commands are complete

3. **Restart WireGuard**:
   ```bash
   # On server
   sudo systemctl restart wg-quick@wg0
   # or
   sudo wg-quick down wg0 && sudo wg-quick up wg0

   # Check status
   sudo wg show
   ```

4. **Debug Connection**:
   ```bash
   # On client
   sudo tcpdump -i any -n port 51820  # Watch for packets

   # On server
   sudo journalctl -u wg-quick@wg0 -f  # Watch logs
   sudo iptables -L -n -v  # Check firewall rules
   ```

### Terraform fails with "bucket does not exist"
Run bootstrap first: `cd terraform/aws/bootstrap && terraform apply`

### Ansible cannot connect
- Check security group allows SSH from your IP
- Verify instance is running: `aws ec2 describe-instances`
- Use SSM instead: `aws ssm start-session --target <INSTANCE_ID>`

### Server iptables rules not working
Verify the correct format in Ansible template:
```bash
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o <interface> -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o <interface> -j MASQUERADE
```

### IP Forwarding not enabled
```bash
# Check status
sysctl net.ipv4.ip_forward

# Enable permanently
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

## License

MIT

