# Security Policy

## Overview

This repository contains infrastructure-as-code for deploying a WireGuard VPN server on AWS. Security is a critical priority given the sensitive nature of VPN infrastructure. This document outlines our security policies, practices, and guidelines for reporting vulnerabilities.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

We provide security updates for the latest version on the `main` branch.

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please follow these steps:

1. **Do not** disclose the vulnerability publicly until it has been addressed.
2. Report the vulnerability by opening a [private security advisory](../../security/advisories/new) or emailing the repository owner directly.
3. Include the following information in your report:
   - A clear description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact of the vulnerability
   - Any suggested remediation (if applicable)

### Response Timeline

- **Acknowledgment**: Within 48 hours of receiving your report
- **Initial Assessment**: Within 7 days
- **Resolution**: Dependent on severity, typically within 30 days

## Security Best Practices

When using this infrastructure, please adhere to the following security practices:

### Key Management

- **Unique Keys**: Each WireGuard peer (server and clients) MUST have unique key pairs. Never share private keys between peers.
- **Key Rotation**: Rotate WireGuard keys every 90 days.
- **Secure Storage**: Store all keys with restrictive permissions (`chmod 600`) and use Ansible Vault for encrypted secrets.
- **Preshared Keys**: Use preshared keys (PSK) for additional post-quantum security.

### AWS Security

- **IAM Least Privilege**: Use IAM roles with minimum required permissions.
- **MFA**: Enable Multi-Factor Authentication for AWS account access.
- **Separate Accounts**: Use dedicated AWS accounts for production environments.
- **VPC Flow Logs**: Enable VPC Flow Logs for network traffic auditing.
- **Encryption**: Ensure EBS volumes and CloudWatch Logs are encrypted with KMS.

### Network Security

- **Security Groups**: Restrict security group rules to specific IP addresses when possible.
- **Fail2ban**: The playbook includes fail2ban to prevent brute force attacks.
- **SSH Access**: Prefer AWS SSM Session Manager over SSH for server access.
- **Port Restriction**: Only expose the WireGuard port (51820/UDP) publicly.

### Infrastructure as Code

- **No Secrets in Code**: Never commit sensitive data (private keys, passwords, tokens) to version control.
- **State File Security**: Terraform state files are stored in S3 with encryption enabled.
- **Input Validation**: Validate all Terraform and Ansible input variables.

### Monitoring and Auditing

- **CloudWatch Alerts**: Configure alerts for suspicious activity.
- **Security Hub**: Regularly audit with AWS Security Hub.
- **Log Retention**: Maintain audit logs for compliance requirements.

## Security Features

This infrastructure includes the following security hardening:

- **Automatic Updates**: Security patches are applied automatically via `unattended-upgrades`.
- **Encrypted Storage**: EBS volumes are encrypted at rest.
- **Encrypted Logs**: CloudWatch Logs are encrypted with KMS.
- **Backup Retention**: Daily snapshots with 7-day retention.
- **Fail2ban Protection**: Automated intrusion prevention.
- **Minimal Attack Surface**: Uses ARM-based Graviton2 instances with minimal installed packages.

## Sensitive Files

The following files contain or may contain sensitive information and should **never** be committed to version control:

- `ansible/.vault_pass` - Ansible Vault password file
- `ansible/group_vars/all/vault.yml` - Encrypted secrets (should be encrypted with Ansible Vault)
- `*.key` - WireGuard private keys, public keys, and preshared keys
- `*.pem` - SSH private keys
- `terraform.tfvars` - May contain sensitive configuration
- `terraform.tfstate*` - Terraform state files (stored in S3)

## Dependencies

We recommend regularly updating the following components:

- Terraform providers (AWS, random, etc.)
- Ansible collections and roles
- WireGuard packages on the server
- Operating system packages

## Additional Resources

- [WireGuard Security Model](https://www.wireguard.com/protocol/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [Terraform Security Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices/security)
- [Ansible Security Automation](https://www.ansible.com/use-cases/security-automation)

## Acknowledgments

We appreciate the security research community and individuals who help improve the security of this project through responsible disclosure.
