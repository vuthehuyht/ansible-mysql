# MySQL 8.0.42 Ansible Project - Quick Reference

## 🚀 Quick Deployment Commands

### Development Environment
```bash
# Complete development deployment
ansible-playbook deploy-dev.yml

# With detailed output
ansible-playbook deploy-dev.yml -vv

# Run specific steps only
ansible-playbook deploy-dev.yml --tags="step1,step2,step3"

# Override variables
ansible-playbook deploy-dev.yml -e "mysql_bind_address=192.168.1.100"
```

### Production Environment
```bash
# Setup vault first (one time only)
ansible-vault create group_vars/all/vault.yml

# Complete production deployment
ansible-playbook deploy-prod.yml --ask-vault-pass

# With detailed output
ansible-playbook deploy-prod.yml --ask-vault-pass -vv

# Run specific steps only
ansible-playbook deploy-prod.yml --ask-vault-pass --tags="step6,step7,step8"

# Override variables for testing
ansible-playbook deploy-prod.yml --ask-vault-pass -e "mysql_max_connections=300"
```

## 📁 Variable Architecture

### File Structure
```
group_vars/all/
├── common.yml     # Base configuration
├── dev.yml        # Development overrides
├── prod.yml       # Production overrides  
└── vault.yml      # Encrypted passwords
```

### Loading Order
1. **common.yml** - Base configuration loaded first
2. **{env}.yml** - Environment-specific overrides
3. **vault.yml** - Encrypted variables (production only)
4. **Command line** - Runtime overrides with `-e`

## 🔧 Variable Management

### View Variables
```bash
# Check loaded variables
ansible-inventory --host mysql-server-01 --vars

# View configuration files
cat group_vars/all/common.yml
cat group_vars/all/dev.yml
cat group_vars/all/prod.yml
```

## 📋 Deployment Process

### 10-Step Installation
1. **🔐 Permission Validation** - Check sudo access and user permissions
2. **🕐 Time Synchronization** - Setup chrony time sync (Asia/Ho_Chi_Minh)
3. **⚡ OS Optimization** - Kernel tuning and system parameters optimization
4. **🧹 System Updates** - Update packages and system components
5. **🗑️ MySQL Cleanup** - Remove old MySQL installations (if any)
6. **📦 MySQL Installation** - Download and install MySQL 8.0.42 binary
7. **⚙️ MySQL Configuration** - Configure MySQL with environment-specific settings
8. **🔒 Security Hardening** - Secure installation and user setup
9. **🗄️ Database Setup** - Create databases and users with proper privileges
10. **✅ Final Validation** - Verify installation and provide status report

### Utility Commands
```bash
# Uninstall MySQL completely (DANGEROUS!)
ansible-playbook uninstall-mysql.yml
```

## 🔒 Vault Management

### Setup Vault
```bash
# Create vault file
ansible-vault create group_vars/all/vault.yml

# Add these variables:
vault_mysql_root_password: "YourSuperSecureRootPassword123!@#"
vault_mysql_app_password: "YourSecureAppPassword123!@#"
vault_mysql_readonly_password: "YourSecureReadOnlyPassword123!@#"
```

### Vault Operations
```bash
# Edit vault
ansible-vault edit group_vars/all/vault.yml

# View vault content
ansible-vault view group_vars/all/vault.yml

# Change vault password
ansible-vault rekey group_vars/all/vault.yml
```

## 🌍 Environment Comparison

| Feature | Development | Production |
|---------|-------------|------------|
| **Remote Access** | ✅ Enabled (192.168.0.0/16) | ❌ Disabled (localhost only) |
| **Performance** | Moderate settings | High-performance optimization |
| **Logging** | Detailed debugging | Production-grade (slow queries) |
| **Security** | Basic security | Maximum security hardening |
| **Databases** | dev_db, test_db | production_db, app_db |
| **Users** | dev_user, test_user | app_user, readonly_user |

## 🐛 Troubleshooting

### Debug Commands
```bash
# Maximum verbosity for debugging
ansible-playbook deploy-dev.yml -vvv

# Check specific host
ansible-playbook deploy-prod.yml --ask-vault-pass --limit="mysql-server-01"

# Re-run specific steps
ansible-playbook deploy-dev.yml --tags="step7"
ansible-playbook deploy-prod.yml --ask-vault-pass --tags="step8,step9"
```

## 📁 Important File Locations
- **MySQL Binary**: `/usr/local/mysql/`
- **Data Directory**: `/usr/local/mysql/data/`
- **Configuration**: `/etc/my.cnf`
- **Service File**: `/etc/systemd/system/mysql.service`
- **Error Log**: `/var/log/mysql/error.log`
- **Slow Query Log**: `/var/log/mysql/slow.log`
- **Socket**: `/var/run/mysqld/mysqld.sock`

## ⚡ Performance Settings

| Setting | Development | Production |
|---------|-------------|------------|
| **Buffer Pool** | 1G | 2G |
| **Max Connections** | 200 | 500 |
| **Query Cache** | 128M | 256M |
| **OS Tuning** | Moderate | Aggressive |
| **Remote Access** | ✅ Enabled | ❌ Disabled |
| **I/O Scheduler** | Default | Optimized |
| **CPU Governor** | Default | Performance |

## 🔒 Security Model

### How It Works
1. **SSH Connection** → Connect as regular user (ubuntu, deployer, etc.)
2. **Privilege Escalation** → Use `sudo` when root privileges needed
3. **Task Execution** → Run MySQL tasks with root privileges
4. **Security** → Never connect directly as root user

### Connection Flow
```
Your Machine → SSH (ubuntu@server) → sudo (become root) → Execute MySQL tasks
```

### Security Benefits
- ✅ No direct root login (root login disabled)
- ✅ All actions logged through sudo
- ✅ User accountability (track who did what)
- ✅ Easy access revocation (remove from sudo group)
- ✅ SSH key authentication (no passwords)

## 🔧 Inventory Management
```bash
# List all hosts
ansible-inventory --list

# Show host variables
ansible-inventory --host mysql-server-01

# Test inventory parsing
ansible-inventory --graph
```
