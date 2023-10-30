---
title: MySQL Replication
category: note
slug: mysql-replication
date: 2019-07-24
---
Standard asynchronous replication is not a synchronous cluster. Keep in mind
that stand and semi synchronous replication do not guarantee that the
environments replication data coherence data integrity

-  Statement-Based
-  Row-Based
-  Mixed replication

First fact you absolutely need to remember is MySQL Replication is single
threaded, which means if you have any long running write query it clogs
replication stream and small and fast updates which go after it in MySQL binary
log can't proceed.

Master:

-  Dump thread

Slave:

-  IO thread
-  SQL thread

In `/etc/my.cnf`:

```text
slave_parallel_workers = N
```

Worker threads are visible with `SHOW PROCESSLIST;`. On master:

```sql
mysql> SHOW PROCESSLIST;
+-------+------+-----------------+-------+-------------+--------+---------------------------------------------------------------+------------------+
| Id    | User | Host            | db    | Command     | Time   | State                                                         | Info             |
+-------+------+-----------------+-------+-------------+--------+---------------------------------------------------------------+------------------+
|  5923 | repl | victor:39884    | NULL  | Binlog Dump | 145429 | Master has sent all binlog to slave; waiting for more updates | NULL             |
| 51098 | root | localhost:48238 | bampi | Sleep       |    206 |                                                               | NULL             |
| 89478 | root | localhost       | bampi | Query       |      0 | starting                                                      | SHOW PROCESSLIST |
| 91879 | root | localhost:38758 | bampi | Sleep       |      6 |                                                               | NULL             |
+-------+------+-----------------+-------+-------------+--------+---------------------------------------------------------------+------------------+
4 rows in set (0.00 sec)
```

On slave:

```sql
mysql> SHOW PROCESSLIST;
+--------+-------------+-----------+-------+---------+--------+--------------------------------------------------------+------------------+
| Id     | User        | Host      | db    | Command | Time   | State                                                  | Info             |
+--------+-------------+-----------+-------+---------+--------+--------------------------------------------------------+------------------+
|   2060 | system user |           | NULL  | Connect | 145420 | Waiting for master to send event                       | NULL             |
|   2061 | system user |           | NULL  | Connect |    129 | Slave has read all relay log; waiting for more updates | NULL             |
| 270102 | root        | localhost | bampi | Query   |      0 | starting                                               | SHOW PROCESSLIST |
+--------+-------------+-----------+-------+---------+--------+--------------------------------------------------------+------------------+
3 rows in set (0.00 sec)
```

## Reset MySQL Slave

Sometimes when something went wrong with MySQL slave, for example the slave
cannot be started by Pacemaker resource agent, could be a very serious problem.
Entries being inserted/updated/deleted on master cannot synchronize to slave. A
brutal but simple solution is to reset the slave, forcing it to re-synchronize
from a specified binlog position.

First, check MySQL master's status. We're going to use these information on the
slave.

```sql
mysql> SHOW MASTER STATUS\\G
*************************** 1. row ***************************
             File: binlog.000038
         Position: 569781
     Binlog_Do_DB:
 Binlog_Ignore_DB:
Executed_Gtid_Set:
1 row in set (0.05 sec)
```

Then bring up MySQL service on the slave node. Reset the slave with the binlog
file and position we got from the above command.

```sql
mysql> RESET SLAVE;
mysql> CHANGE MASTER TO
    -> MASTER_HOST='bampi-2',
    -> MASTER_USER='repl',
    -> MASTER_PASSWORD='reppass',
    -> MASTER_LOG_FILE='binlog.000038',
    -> MASTER_LOG_POS=569781;
mysql> START SLAVE;
mysql> SHOW SLAVE STATUS\\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: bampi-1
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: binlog.000038
          Read_Master_Log_Pos: 569781
               Relay_Log_File: mysqld-relay-bin.000002
                Relay_Log_Pos: 424226
        Relay_Master_Log_File: binlog.000038
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 569781
              Relay_Log_Space: 424434
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
                  Master_UUID: 3b63306e-7e96-11e8-b7bd-ea448e98a451
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)

mysql> STOP SLAVE;
```

## References

-  [NicolasTrutet/Linux-HA-MySQL-Replication: How to set up 2 nodes failover
   with a MySQL master-master
   replication](https://github.com/NicolasTrutet/Linux-HA-MySQL-Replication)
-  [How does MySQL Replication really work?](https://www.percona.com/blog/2013/01/09/how-does-mysql-replication-really-work/)
-  [Overview of Different MySQL Replication Solutions](https://www.percona.com/blog/2017/02/07/overview-of-different-mysql-replication-solutions/)
-  [MySQL 平行執行的 Replication...](https://blog.gslin.org/archives/2013/01/09/3117/mysql-%E5%B9%B3%E8%A1%8C%E5%9F%B7%E8%A1%8C%E7%9A%84-replication/)
-  [Multi-Threaded Replication in MySQL 5.6 and MySQL 5.7](https://www.percona.com/live/mysql-conference-2015/sites/default/files/slides/MySQL_MultiThreaded_Replication.pdf)
