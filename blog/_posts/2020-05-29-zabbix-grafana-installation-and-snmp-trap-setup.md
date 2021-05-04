---
layout: post
title: 'Zabbix/Grafana Installation and SNMP Trap Setup'
category: memo
slug: zabbix-grafana-installation-and-snmp-trap-setup
---
CentOS 7 + Zabbix 4.0

```bash
# yum install epel-release
# yum install yum-utils
# yum-config-manager --enable rhel-7-server-optional-rpms
```

## Zabbix Installation

### Adding Zabbix Repository

```bash
# rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm
```

### MySQL

```bash
# rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-3.noarch.rpm
# sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
# yum --enablerepo=mysql80-community install mysql-community-server
# systemctl start mysqld.service
# grep "A temporary password" /var/log/mysqld.log
# mysql_secure_installation
# systemctl restart mysqld.service
# systemctl enable mysqld.service
```

```sql
mysql> create database zabbix character set utf8 collate utf8_bin;
mysql> create user 'zabbix'@'localhost' identified by '<password>';
mysql> grant all privileges on zabbix.* to 'zabbix'@'localhost';
mysql> alter user 'zabbix'@'localhost' identified with mysql_native_password by '<password>';
mysql> quit;
```

### Zabbix Server

```bash
# yum install zabbix-server-mysql zabbix-web-mysql
# zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix
# firewall-cmd --zone=public --add-port=80/tcp --permanent
# firewall-cmd --reload
```

`/etc/zabbix/zabbix_server.conf`

```
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=<password>
```

`/etc/httpd/conf.d/zabbix.conf`

```
php_value max_execution_time 300
php_value memory_limit 128M
php_value post_max_size 16M
php_value upload_max_filesize 2M
php_value max_input_time 300
php_value max_input_vars 10000
php_value always_populate_raw_post_data -1
php_value date.timezone Asia/Taipei
```

Following up by frontend installation steps.

### SELinux Configuration

```bash
# setsebool -P httpd_can_connect_zabbix on
```

### Zabbix Agent

```bash
# yum install zabbix-agent
# systemctl enable zabbix-agent.service
# systemctl start zabbix-agent.service
```

## Grafana Installation

`/etc/yum.repos.d/grafana.repo`

```
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
```

```bash
# yum install grafana
# yum install fontconfig freetype* urw-fonts
```

```bash
# systemctl enable grafana-server.service
# systemctl start grafana-server.service
```

```bash
# firewall-cmd --zone=public --add-port=3000/tcp --permanent
# firewall-cmd --reload
```

```bash
# grafana-cli plugins install alexanderzobnin-zabbix-app
# systemctl restart grafana-server
```

The plugins are installed under `/var/lib/grafana/plugins`.

Zabbix HTTP URL is `http://<zabbix-server-ip>/zabbix/api_jsonrpc.php`.

## SNMP Trap Setup

```bash
# yum install net-snmp net-snmp-utils net-snmp-perl
# yum install perl-Config-IniFiles perl-Sys-Syslog
```

## References

- [Zabbix Documentation 4.0](https://www.zabbix.com/documentation/4.0/manual/installation/install_from_packages/rhel_centos)
- [i received an zabbix server start error and shared solition](https://stackoverflow.com/questions/59356695/i-received-an-zabbix-server-start-error-and-shared-solition)
- [How to install and configure Grafana on CentOS 7 \| FOSS Linux](https://www.fosslinux.com/8328/how-to-install-and-configure-grafana-on-centos-7.htm)
- [Tutorial - Zabbix IPMI Monitor Configuration](https://techexpert.tips/zabbix/zabbix-ipmi-monitor/)
- [SNMP Traps in Zabbix](https://blog.zabbix.com/snmp-traps-in-zabbix/)
- [Zabbix4.0 をRHEL8 へインストール（仮）- SNMPTT設定もするよ - Qiita](https://qiita.com/mgmjoke/items/0cedf8eee419b7504a09)
- [SNMP Traps - Standard Handler vs Embedded Handler](https://support.nagios.com/kb/article.php?id=557)
- [[ NetSNMP ] snmptrapd.conf 設定](https://blog.xuite.net/aflyfish/blog/86126735-%5B+NetSNMP+%5D+snmptrapd.conf+設定)
