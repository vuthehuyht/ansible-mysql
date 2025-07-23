# Ansible MySQL 8.0.42 Installation Project - Ubuntu/Debian (Binary Install)

Dự án Ansible này được thiết kế để tự động cài đặt và cấu hình MySQL 8.0.42 từ binary trên các server Ubuntu/Debian với 2 playbook chính hoàn chỉnh.

## Cấu trúc Project (Refactored - 2 Playbooks Model)

```
ansible-mysql/
├── ansible.cfg                     # Cấu hình Ansible
├── inventory                       # Danh sách servers
├── deploy-dev.yml                 # 🚀 MAIN: Complete Development Deployment (All-in-one)
├── deploy-prod.yml                # 🚀 MAIN: Complete Production Deployment (All-in-one)
├── setup-sudo.yml                # Utility: Setup passwordless sudo
├── check-access.yml               # Utility: Kiểm tra quyền truy cập
├── check-mysql.yml                # Utility: Kiểm tra trạng thái MySQL
├── uninstall-mysql.yml            # Utility: Gỡ cài đặt MySQL (cẩn thận!)
├── scripts/
│   └── backup-mysql.sh            # Script backup MySQL
└── roles/
```
ansible-mysql/
├── ansible.cfg                     # Cấu hình Ansible
├── inventory                       # Danh sách servers
├── deploy-dev.yml                 # 🚀 MAIN: Complete Development Deployment (All-in-one)
├── deploy-prod.yml                # 🚀 MAIN: Complete Production Deployment (All-in-one)
├── uninstall-mysql.yml            # Utility: Gỡ cài đặt MySQL (cẩn thận!)
├── group_vars/
│   └── all/
│       ├── common.yml             # Biến chung cho tất cả environments
│       ├── dev.yml                # Biến riêng cho Development environment
│       ├── prod.yml               # Biến riêng cho Production environment
│       ├── README.md              # Hướng dẫn tạo vault file
│       └── vault.yml              # Ansible Vault cho production (tạo thủ công)
├── scripts/
│   └── backup-mysql.sh            # Script backup MySQL
└── roles/
    └── mysql/
        ├── defaults/main.yml       # Biến mặc định cho tasks
        ├── handlers/main.yml       # Handlers cho restart/reload
        ├── tasks/
        │   ├── main.yml           # Tasks chính (legacy)
        │   ├── check-permissions.yml # Permission validation
        │   ├── sync-time.yml      # Time synchronization
        │   ├── optimize-os.yml    # OS performance tuning
        │   ├── update-system.yml  # System update tasks
        │   ├── cleanup-old-mysql.yml # Cleanup MySQL cũ
        │   ├── debian.yml         # Download và cài đặt binary
        │   ├── configure-mysql.yml # Cấu hình và systemd service
        │   └── secure-installation.yml # MySQL secure installation
        └── templates/
            ├── my.cnf.j2          # Template cấu hình MySQL
            ├── mysql.service.j2   # Template systemd service
            └── helper_scripts.j2  # Template helper scripts
```

## 🚀 2-Playbook Model - Complete Deployment với Variable Management

Project này sử dụng hệ thống quản lý variables tối ưu:

### 📋 Variable Architecture
- **`group_vars/all/common.yml`**: Chứa tất cả variables chung cho cả 2 environments
- **`group_vars/all/dev.yml`**: Variables riêng cho development (extends common.yml)
- **`group_vars/all/prod.yml`**: Variables riêng cho production (extends common.yml)
- **`group_vars/all/vault.yml`**: Encrypted passwords cho production

### 📋 deploy-dev.yml - Development Environment
- **Mục đích**: Triển khai hoàn chỉnh cho môi trường development
- **Variables**: Load từ `common.yml` + `dev.yml`
- **Đặc điểm**: 
  - Cấu hình tối ưu cho development workload
  - Performance settings vừa phải (256M buffer pool)
  - Logging chi tiết để debug (general log enabled)
  - Remote connections từ any host (0.0.0.0)
  - Passwords không mã hóa (development only)
- **Bao gồm**: 10 bước triển khai hoàn chỉnh

### 🔒 deploy-prod.yml - Production Environment  
- **Mục đích**: Triển khai hoàn chỉnh cho môi trường production
- **Variables**: Load từ `common.yml` + `prod.yml` + `vault.yml`
- **Đặc điểm**:
  - Security hardening cao cấp
  - Performance optimization mạnh mẽ (2G buffer pool)
  - Local connections only (127.0.0.1)
  - Ansible Vault cho passwords
  - General logging disabled (performance)
- **Bao gồm**: 10 bước triển khai hoàn chỉnh với production-grade security

## ⚙️ Variable Management

### 🔧 Common Variables (common.yml)
```yaml
# Shared across all environments
mysql_version: "8.0.42"
mysql_basedir: "/usr/local/mysql"
mysql_timezone: "Asia/Ho_Chi_Minh"
mysql_character_set: "utf8mb4"
# ... và nhiều settings chung khác
```

### 🔧 Development Variables (dev.yml)
```yaml
# Development-specific overrides
mysql_bind_address: "0.0.0.0"        # Remote access allowed
mysql_innodb_buffer_pool_size: "256M" # Moderate resources
mysql_general_log: 1                  # Debug logging enabled
mysql_root_password: "DevPassword123!" # Plain text (dev only)
```

### 🔧 Production Variables (prod.yml)  
```yaml
# Production-specific overrides
mysql_bind_address: "127.0.0.1"       # Local only
mysql_innodb_buffer_pool_size: "2G"   # High performance
mysql_general_log: 0                  # Logging disabled
mysql_root_password: "{{ vault_mysql_root_password }}" # Encrypted
```

## Yêu cầu

- Ansible 2.9+
- Python 3.6+
- SSH access đến target servers
- Sudo privileges trên target servers

## 🚀 Hướng dẫn triển khai nhanh

### 1. Chuẩn bị inventory

Tạo file `inventory` với user sudo (không dùng root):

```ini
[mysql_servers]
# Sử dụng user thường có sudo thay vì root
mysql-server-01 ansible_host=192.168.1.100 ansible_user=ubuntu ansible_become=yes
mysql-server-02 ansible_host=192.168.1.101 ansible_user=deployer ansible_become=yes

[mysql_servers:vars]
ansible_become=yes
ansible_become_method=sudo
```

**Thay `ubuntu` bằng username thực tế của server.**

### 2. Setup Passwordless Sudo (Bắt buộc)

**QUAN TRỌNG**: Project này sử dụng security best practice - kết nối với user thường và sudo lên root khi cần.

#### Security Model:
- ✅ **Connect**: User thường (ubuntu, deployer) qua SSH
- ✅ **Execute**: Tasks chạy với root privileges thông qua sudo
- ❌ **KHÔNG**: Kết nối trực tiếp với root user

#### Setup Commands:
```bash
# Method 1: Using Ansible ad-hoc commands (connect as root first time only)
ansible mysql_servers -m user -a "name=ubuntu groups=sudo append=yes" -u root -k
ansible mysql_servers -m lineinfile -a "path=/etc/sudoers.d/ubuntu line='ubuntu ALL=(ALL) NOPASSWD:ALL' create=yes" -u root -k

# Method 2: Manual setup on each server
# ssh root@server
# usermod -aG sudo ubuntu  
# echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu

# Method 3: Test sudo configuration
ansible mysql_servers -m command -a "sudo whoami"
# Output mong đợi: root
```

#### Connection Flow:
```
Your Machine → SSH (ubuntu@server) → sudo (become root) → MySQL installation tasks
```

### 3. Kiểm tra quyền truy cập

```bash
# Kiểm tra kết nối và quyền
ansible-playbook check-access.yml

# Test với user sudo
ansible mysql_servers -m command -a "sudo whoami"
```

✅ **Ưu điểm security model này:**
- Không dùng root trực tiếp (root login có thể bị disable)
- Audit trail đầy đủ qua sudo logs
- User accountability (biết ai làm gì)
- Dễ quản lý quyền truy cập (revoke user khỏi sudo group)
- Phù hợp với security best practices
- Hỗ trợ SSH key authentication

### 4. Cấu hình biến

Project sử dụng system environment variables trong `group_vars/all/`:
- `common.yml`: Cấu hình chung cho tất cả environments
- `dev.yml`: Development environment - cấu hình tối thiểu
- `prod.yml`: Production environment - tối ưu hiệu năng và bảo mật

### 5. Sử dụng Environments

Dự án hỗ trợ 2 environments:
- **dev**: Development environment - cấu hình tối thiểu để phát triển
- **prod**: Production environment - cấu hình tối ưu cho production

#### Triển khai với Environment Flag:
```bash
# Development environment
ansible-playbook install-mysql.yml -e "environment=dev"

# Production environment
ansible-playbook install-mysql.yml -e "environment=prod"
```

#### Hoặc sử dụng Playbook riêng:
```bash
# Development
ansible-playbook deploy-dev.yml

# Production (yêu cầu vault password)
ansible-playbook deploy-prod.yml --ask-vault-pass
```

### 4. Sử dụng Environments

Dự án hỗ trợ 2 environments:
- **dev**: Development environment - cấu hình tối thiểu để phát triển
## 🎯 Triển khai MySQL (2-Playbook Model)

### 📋 Development Environment

```bash
# Triển khai development (tất cả bước trong 1 playbook)
ansible-playbook deploy-dev.yml

# Chi tiết deployment với verbose
ansible-playbook deploy-dev.yml -vv

# Chỉ chạy một số bước cụ thể
ansible-playbook deploy-dev.yml --tags="step1,step2,step3"
```

**Tính năng Development:**
- ✅ OS optimization cho development workload
- ✅ Remote connections cho development  
- ✅ Chi tiết logging để debug
- ✅ Performance settings vừa phải
- ✅ Database tự động tạo: dev_db, test_db
- ✅ User development với quyền phù hợp

### 🔒 Production Environment

```bash
# Setup Ansible Vault (lần đầu)
ansible-vault create group_vars/all/vault.yml
# Thêm các biến:
# vault_mysql_root_password: "YourSecureRootPassword"
# vault_mysql_app_password: "YourSecureAppPassword" 
# vault_mysql_readonly_password: "YourSecureReadOnlyPassword"

# Triển khai production (tất cả bước trong 1 playbook)
ansible-playbook deploy-prod.yml --ask-vault-pass

# Chi tiết deployment với verbose
ansible-playbook deploy-prod.yml --ask-vault-pass -vv

# Chỉ chạy một số bước cụ thể
ansible-playbook deploy-prod.yml --ask-vault-pass --tags="step6,step7,step8"
```

**Tính năng Production:**
- 🔒 Security hardening cao cấp
- 🔒 Local connections only (127.0.0.1)
- 🔒 Ansible Vault cho passwords
- ⚡ Performance optimization mạnh mẽ
- ⚡ Production database: production_db, app_db
- ⚡ Minimal privilege users
- 📊 Monitoring và logging production-grade

## 📊 10-Step Deployment Process

Cả 2 playbook đều thực hiện 10 bước triển khai hoàn chỉnh:

1. **🔐 Permission Validation** - Kiểm tra quyền sudo và access
2. **🕐 Time Synchronization** - Đồng bộ thời gian với chrony
3. **⚡ OS Optimization** - Tối ưu kernel và system parameters
4. **🧹 System Updates** - Cập nhật hệ thống và packages
5. **🗑️ MySQL Cleanup** - Cleanup MySQL cũ (nếu có)
6. **📦 MySQL Installation** - Download và cài đặt MySQL 8.0.42 binary
7. **⚙️ MySQL Configuration** - Cấu hình MySQL với environment-specific settings
8. **🔒 Security Hardening** - Secure installation và hardening
9. **🗄️ Database Setup** - Tạo databases và users
10. **✅ Final Validation** - Kiểm tra và báo cáo trạng thái final

## 🛠️ Utility Playbooks (Hỗ trợ)

Chỉ còn 1 playbook utility duy nhất:

```bash
# Gỡ cài đặt MySQL hoàn toàn (CẨN THẬN!)
ansible-playbook uninstall-mysql.yml
```

### Kiểm tra hệ thống bằng lệnh Ansible trực tiếp:

```bash
# Kiểm tra kết nối cơ bản
ansible mysql_servers -m ping

# Kiểm tra quyền sudo
ansible mysql_servers -m command -a "sudo whoami"

# Kiểm tra MySQL service status
ansible mysql_servers -m systemd -a "name=mysql"

# Kiểm tra MySQL processes
ansible mysql_servers -m shell -a "ps aux | grep mysql"

# Setup passwordless sudo (nếu cần)
ansible mysql_servers -m user -a "name={{ ansible_user }} groups=sudo append=yes" -u root -k
ansible mysql_servers -m lineinfile -a "path=/etc/sudoers.d/{{ ansible_user }} line='{{ ansible_user }} ALL=(ALL) NOPASSWD:ALL' create=yes" -u root -k
```
ansible mysql_servers -m reboot
```

### 6. Cập nhật hệ thống (khuyến nghị)

```bash
# Chỉ update/upgrade hệ thống
ansible-playbook update-system.yml

# Reboot nếu cần thiết
ansible mysql_servers -m reboot
```

### 7. Kiểm tra kết nối

```bash
ansible mysql_servers -m ping
```

### 8. Chạy Playbook

```bash
# Cách 1: Sử dụng environment flag
ansible-playbook install-mysql.yml -e "environment=dev"     # Development
ansible-playbook install-mysql.yml -e "environment=prod"    # Production

# Cách 2: Sử dụng playbook riêng
ansible-playbook deploy-dev.yml                             # Development
ansible-playbook deploy-prod.yml --ask-vault-pass           # Production

# Cách 2: Từng bước chi tiết
ansible-playbook cleanup-mysql.yml      # Cleanup MySQL cũ
ansible-playbook update-system.yml      # Update system
ansible mysql_servers -m reboot         # Reboot nếu cần
ansible-playbook install-mysql.yml      # Cài MySQL

# Dry run (kiểm tra trước)
ansible-playbook install-mysql.yml --check

# Chạy với verbose output
ansible-playbook install-mysql.yml -v
```

### 7. Kiểm tra cài đặt

```bash
# Kiểm tra MySQL service
ansible mysql_servers -m service -a "name=mysql state=started"

# Kiểm tra phiên bản MySQL
ansible mysql_servers -m shell -a "mysql --version"
```

## Cấu hình

### Biến quan trọng

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `mysql_version` | 8.0.42 | Phiên bản MySQL |
| `mysql_root_password` | SecurePassword123! | Root password |
| `mysql_port` | 3306 | Port MySQL |
| `mysql_bind_address` | 0.0.0.0 | Bind address |
| `mysql_innodb_buffer_pool_size` | 512M | InnoDB buffer pool |

### Databases và Users

Cấu hình trong `group_vars/mysql_servers.yml`:

```yaml
mysql_databases:
  - name: production_db
    encoding: utf8mb4
    collation: utf8mb4_unicode_ci

mysql_users:
  - name: app_user
    password: "AppPassword123!"
    priv: "production_db.*:ALL"
    host: "%"
```

## 📦 Phương pháp cài đặt

Project này sử dụng **MySQL Binary Installation** thay vì package manager:

1. **Tải MySQL Binary**: Download từ MySQL official website
2. **Cài đặt thủ công**: Giải nén và cấu hình tại `/usr/local/mysql`
3. **Tạo systemd service**: Tự động tạo service file
4. **Cấu hình hoàn chỉnh**: Setup user, group, permissions, và config

**Lợi ích**:
- ✅ Phiên bản chính xác MySQL 8.0.42
- ✅ Không phụ thuộc vào package repository
- ✅ Kiểm soát hoàn toàn quá trình cài đặt
- ✅ Dễ dàng nâng cấp hoặc downgrade

## 🗂️ Cấu trúc installation

```
/usr/local/mysql/          # MySQL installation directory
├── bin/                   # MySQL executables
├── data/                  # MySQL data directory
├── mysql-files/           # Secure file directory
└── ...

/etc/my.cnf               # MySQL configuration file
/etc/systemd/system/      # systemd service files
/var/log/mysql/           # MySQL log files
```

- ✅ Ubuntu 18.04 LTS (Bionic Beaver)
- ✅ Ubuntu 20.04 LTS (Focal Fossa)  
- ✅ Ubuntu 22.04 LTS (Jammy Jellyfish)
- ✅ Ubuntu 24.04 LTS (Noble Numbat)
- ✅ Debian 10 (Buster)
- ✅ Debian 11 (Bullseye)
- ✅ Debian 12 (Bookworm)

**Lưu ý**: Project này được tối ưu hóa cho Ubuntu/Debian và không hỗ trợ CentOS/RHEL/Rocky Linux.

## Bảo mật

- Tự động thực hiện MySQL secure installation
- Xóa anonymous users
- Xóa test database
- Chỉ cho phép root login từ localhost
- Cấu hình strong password policy

## Troubleshooting

### MySQL service không start

```bash
# Kiểm tra logs
ansible mysql_servers -m shell -a "journalctl -u mysql -n 50"

# Kiểm tra cấu hình
ansible mysql_servers -m shell -a "mysql --help --verbose | grep -A 1 'Default options'"

# Kiểm tra MySQL syntax
ansible mysql_servers -m shell -a "mysqld --help --verbose"
```

### Connection refused

- Kiểm tra firewall settings
- Kiểm tra bind-address trong cấu hình
- Kiểm tra MySQL user permissions

## 📊 Monitoring Setup

Dự án hỗ trợ cài đặt monitoring agents để theo dõi MySQL và system metrics:

```bash
# Cài đặt monitoring agents (mysqld_exporter + node_exporter)
ansible-playbook deploy-monitoring.yml

# Kiểm tra monitoring services
ansible mysql_servers -m systemd -a "name=mysqld_exporter"
ansible mysql_servers -m systemd -a "name=node_exporter"

# Gỡ cài đặt monitoring (nếu cần)
ansible-playbook uninstall-monitoring.yml
```

**Tính năng Monitoring:**
- 📊 **mysqld_exporter** (Port 9104): MySQL metrics cho Prometheus
- 📊 **node_exporter** (Port 9100): System metrics cho Prometheus  
- 🔒 **Security**: Monitoring user với quyền tối thiểu
- 🔥 **Firewall**: Tự động cấu hình firewall rules
- 📋 **Ready-to-use**: Tương thích với Prometheus + Grafana

Chi tiết xem: [MONITORING.md](MONITORING.md)

## Backup

Enable backup trong `group_vars/all/common.yml`:

```yaml
mysql_backup_enabled: true
mysql_backup_dir: "/var/backups/mysql"
mysql_backup_retention_days: 7
```

## Liên hệ

Nếu có vấn đề hoặc câu hỏi, vui lòng tạo issue trong repository này.
