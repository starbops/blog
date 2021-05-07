---
layout: post
title: 'MySQL Cheatsheet'
category: note
slug: mysql-cheatsheet
---
Note: This article assumes you are using MySQL 5.7.6 and later.

## Default Root Password of Newly Installed MySQL 5.7

After you installed MySQL community server 5.7 on fresh Linux, you will need to find out the temporary password from `/var/log/mysqld.log` to login as root.

1. `grep 'temporary password' /var/log/mysqld.log`
2. Run `mysql_secure_installation` to change new password

The above method is for normal procedure. If you have other scenario, e.g. automate the MySQL server installation, please refer to the following section.

## Make MySQL Root Accessible from Elsewhere

To remote access MySQL server with `root` account, you need the following trick (disclaimer: this is considered DANGEROUS!):

```sql
$ mysql -u root -p
mysql> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password';
```

After that, you can connect to remote MySQL server with this command:

```bash
$ mysql -h 10.0.0.1 -u root -p
mysql>
```

## Resetting MySQL Root Password

So how to force change MySQL root password even if you don't know the password?

Stop the MySQL server if necessary, then restart it with the `--skip-grant-tables` option. This enables anyone to connect without a password and with all privileges, and disables account-management statement such as `ALTER USER` and `SET PASSWORD`. Because this is insecure, you might want to use `--skip-grant-tables` in conjunction with `--skip-networking` to prevent
remote clients from connecting.

```bash
$ sudo service mysqld stop
$ sudo mysqld_safe --skip-grant-tables --skip-networking
$ mysql -u root --connect-expired-password
```

After connecting to MySQL server with root account, tell the server to reload the grant tables so that account-management statements work:

```sql
mysql> FLUSH PRIVILEGES;
```

Then change the `'root'@'localhost'` account password:

```sql
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
```

You should now be able to connect to MySQL server as `root` using the new password. Stop the server and restart it normally (without the `--skip-grant-tables` and `--skip-networking` options).

## Type of MySQL Table Engine

You can easily check what engine type is used for every tables by doing following:

```sql
mysql> SHOW TABLE STATUS WHERE Name = 'table_name';
```

If you want to change it, e.g. from MyIASM to InnoDB, try this:

```sql
mysql> ALTER TABLE table_name ENGINE=InnoDB;
```

## References

- [What is the default root password for MySQL 5.7](https://stackoverflow.com/questions/33991228/what-is-the-default-root-pasword-for-mysql-5-7)
- [MySQL root access from all host](https://stackoverflow.com/questions/11223235/mysql-root-access-from-all-hosts)
- [How to Reset the Root Password](https://dev.mysql.com/doc/refman/5.7/en/resetting-permissions.html)
- [How can I check MySQL engine type for a specific table?](https://stackoverflow.com/questions/213543/how-can-i-check-mysql-engine-type-for-a-specific-table)
