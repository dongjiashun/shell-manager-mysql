ALTER USER 'root'@'localhost' IDENTIFIED  BY 'xxxxxxx';
GRANT all  ON *.* TO 'root'@'localhost' IDENTIFIED BY 'xxxxxxx' with grant option;
GRANT all  ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY 'xxxxxxx' with grant option;
GRANT all  ON *.* TO 'mstdba_mgr'@'127.0.0.1' IDENTIFIED BY 'xxxxxxx' with grant option;
GRANT all  ON *.* TO 'mstdba_mgr'@'172.26.%' IDENTIFIED BY 'xxxxxxx' with grant option;
GRANT all  ON *.* TO 'mstdba_mgr'@'%' IDENTIFIED BY 'xxxxxxx' with grant option;
GRANT REPLICATION SLAVE,REPLICATION CLIENT ON *.* TO 'mreplic'@'172.26.0.%' IDENTIFIED BY 'xxxxxxx';
GRANT DELETE, INSERT, REPLICATION CLIENT, SELECT, SUPER, UPDATE ON *.* TO 'mst_monitor'@'127.0.0.1' IDENTIFIED BY 'xxxxxxx';
GRANT DELETE, INSERT, REPLICATION CLIENT, SELECT, SUPER, UPDATE ON *.* TO 'mst_monitor'@'172.26.%' IDENTIFIED BY 'xxxxxxx';


