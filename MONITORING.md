# MySQL Monitoring with Prometheus and Grafana

This document provides instructions for setting up comprehensive monitoring for your MySQL servers using Prometheus exporters.

## 🎯 Architecture Overview

```
MySQL Server (Database + Agents)     Monitoring Server (Separate)
├── MySQL 8.0.42                    ├── Prometheus Server
├── mysqld_exporter (Port 9104)     ├── Grafana Dashboard  
└── node_exporter (Port 9100)       └── AlertManager
```

## 🚀 Quick Setup

### 1. Deploy Monitoring Agents on MySQL Servers

```bash
# Deploy monitoring agents to all MySQL servers
ansible-playbook deploy-monitoring.yml

# Deploy with verbose output
ansible-playbook deploy-monitoring.yml -vv

# Deploy only to specific host
ansible-playbook deploy-monitoring.yml --limit="mysql-server-01"
```

### 2. Verify Installation

```bash
# Check services status
ansible mysql_servers -m systemd -a "name=mysqld_exporter"
ansible mysql_servers -m systemd -a "name=node_exporter"

# Test metrics endpoints
ansible mysql_servers -m uri -a "url=http://localhost:9104/metrics"
ansible mysql_servers -m uri -a "url=http://localhost:9100/metrics"
```

## 📊 What Gets Installed

### MySQL Exporter (mysqld_exporter)
- **Port**: 9104
- **Purpose**: MySQL-specific metrics (queries, connections, InnoDB, etc.)
- **Metrics**: 200+ MySQL performance indicators
- **User**: Creates dedicated `mysql_monitor` MySQL user with minimal privileges

### Node Exporter (node_exporter) - Optional
- **Port**: 9100  
- **Purpose**: System metrics (CPU, memory, disk, network)
- **Metrics**: 1000+ system performance indicators
- **Security**: Runs as unprivileged user with systemd hardening

## 🔧 Configuration

### Customize Monitoring Settings

Edit `group_vars/all/monitoring.yml`:

```yaml
# Enable/disable components
install_node_exporter: true          # Set false if you don't want system metrics

# Security - Add your Prometheus server IP
monitoring_allowed_networks:
  - "192.168.1.0/24"                 # Your network
  - "10.100.0.50/32"                 # Specific Prometheus server IP

# MySQL monitoring user credentials
mysqld_exporter_password: "YourSecurePassword123!"
```

### Network Security

The playbook automatically configures firewall rules to allow monitoring traffic from specified networks. Update `monitoring_allowed_networks` in `monitoring.yml` to include your Prometheus server IP.

## 📡 Prometheus Server Configuration

Add these job configurations to your Prometheus server's `prometheus.yml`:

```yaml
scrape_configs:
  # MySQL Metrics
  - job_name: 'mysql-exporter'
    static_configs:
      - targets: 
          - 'mysql-server-01:9104'
          - 'mysql-server-02:9104'
    scrape_interval: 30s
    scrape_timeout: 10s

  # System Metrics (if node_exporter installed)
  - job_name: 'mysql-servers-system'
    static_configs:
      - targets:
          - 'mysql-server-01:9100'
          - 'mysql-server-02:9100'
    scrape_interval: 30s
```

## 📊 Grafana Dashboards

Import these recommended dashboards in Grafana:

### MySQL Dashboards
- **MySQL Overview**: Dashboard ID `7362`
- **MySQL Exporter Quickstart**: Dashboard ID `11323`  
- **MySQL InnoDB Metrics**: Dashboard ID `12826`
- **MySQL Performance Schema**: Dashboard ID `12859`

### System Dashboards (if node_exporter enabled)
- **Node Exporter Full**: Dashboard ID `1860`
- **Linux Host Metrics**: Dashboard ID `10242`

### Import Instructions
1. Go to Grafana → Dashboards → Import
2. Enter Dashboard ID
3. Configure data source (Prometheus)
4. Customize as needed

## 🚨 Alerting Rules

Example Prometheus alerting rules (`mysql_alerts.yml`):

```yaml
groups:
  - name: mysql_alerts
    rules:
      - alert: MySQLDown
        expr: mysql_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "MySQL is down on {{ $labels.instance }}"

      - alert: MySQLSlowQueries
        expr: rate(mysql_global_status_slow_queries[5m]) > 10
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High slow queries on {{ $labels.instance }}"

      - alert: MySQLConnectionsHigh
        expr: mysql_global_status_threads_connected / mysql_global_variables_max_connections * 100 > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "MySQL connections usage > 80% on {{ $labels.instance }}"

      - alert: MySQLInnoDBBufferPoolHitRate
        expr: mysql_global_status_innodb_buffer_pool_read_requests / (mysql_global_status_innodb_buffer_pool_read_requests + mysql_global_status_innodb_buffer_pool_reads) * 100 < 95
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "InnoDB buffer pool hit rate < 95% on {{ $labels.instance }}"
```

## 🔍 Key Metrics to Monitor

### MySQL Performance
- `mysql_global_status_queries` - Query rate
- `mysql_global_status_slow_queries` - Slow queries
- `mysql_global_status_threads_connected` - Active connections
- `mysql_global_status_innodb_buffer_pool_read_requests` - InnoDB efficiency
- `mysql_global_status_bytes_sent` / `mysql_global_status_bytes_received` - Network traffic

### System Performance (Node Exporter)
- `node_cpu_seconds_total` - CPU usage
- `node_memory_MemAvailable_bytes` - Available memory
- `node_filesystem_avail_bytes` - Disk space
- `node_network_receive_bytes_total` - Network I/O

## 🛠️ Troubleshooting

### Common Issues

**mysqld_exporter can't connect to MySQL:**
```bash
# Check MySQL monitoring user
mysql -u mysql_monitor -p -e "SHOW GRANTS;"

# Check exporter logs
journalctl -u mysqld_exporter -f
```

**Metrics endpoint not accessible:**
```bash
# Check service status
systemctl status mysqld_exporter

# Check firewall
ufw status
iptables -L
```

**Missing metrics:**
```bash
# Test manual connection
curl http://localhost:9104/metrics | grep mysql_up
```

### Verify Monitoring Setup

```bash
# Complete monitoring verification
ansible-playbook verify-monitoring.yml
```

## 🗑️ Uninstallation

```bash
# Remove all monitoring agents
ansible-playbook uninstall-monitoring.yml
```

This will:
- Stop and disable services
- Remove binaries and config files
- Delete system users
- Remove MySQL monitoring user
- Clean up firewall rules

## 🎯 Production Recommendations

### Security
- Use strong passwords in `monitoring.yml`
- Restrict `monitoring_allowed_networks` to specific IPs
- Enable HTTPS for Grafana and Prometheus
- Use Ansible Vault for sensitive monitoring credentials

### Performance  
- Set appropriate scrape intervals (30s recommended)
- Monitor the monitoring - track exporter resource usage
- Use recording rules for complex queries
- Set up proper retention policies

### High Availability
- Run Prometheus in HA mode
- Use remote storage for long-term retention
- Set up Grafana HA with shared database
- Monitor the monitoring stack itself

## 📚 Additional Resources

- [Prometheus MySQL Exporter](https://github.com/prometheus/mysqld_exporter)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [Grafana MySQL Dashboards](https://grafana.com/grafana/dashboards/?search=mysql)
- [Prometheus Alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
