#可通过访问https://www.postgresql.org/ftp/source/确定所需版本，以下使用10.9版本进行安装。

#1 安装必要软件
rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid
yum groupinstall -y "Development tools"
yum install -y bison flex readline-devel zlib-devel gcc systemtap-sdt-devel.x86_64
yum -y install coreutils glib2 lrzsz mpstat dstatsysstat e4fsprogs xfsprogs ntp readline-devel zlib-devel openssl-develpam-devel libxml2-devel libxslt-devel python-devel tcl-devel gcc makesmartmontools flex bison perl-devel perl-Ext Utils* openldap-devel jadetex openjade bzip2

#2 创建用户
groupadd -g 2000 postgres
useradd -g 2000 -u 2000 postgres
id postgres
# uid=2000(postgres) gid=2000(postgres) groups=2000(postgres)

#3 获取Postgres资源并编译安装
#cd /usr/local/src
#wget https://ftp.postgresql.org/pub/source/v10.9/postgresql-10.9.tar.gz
cd /usr/local/src/postgresql-10.9
tar -zxvf postgresql-10.9.tar.gz 
cd postgresql-10.9/
./configure --prefix=/home/postgres/postgresql  --with-tcl --with-python  --without-ldap --with-libxml --with-libxslt --enable-thread-safety --with-wal-blocksize=16 --with-blocksize=16 --enable-dtrace --enable-debug 
make && make install
/home/postgres/postgresql/bin/postgres --version

#4 创建路径及权限修改
mkdir -p /home/postgres/postgresql/log
mkdir -p /home/postgres/postgresql/pgdata/{data,backups,scripts,archive_wals}
chown -R postgres:postgres /home/postgres
chmod 0700 /home/postgres/postgresql/pgdata

#5 环境变量 
echo 'export PATH=/home/postgres/postgresql/bin:$PATH' > /etc/profile.d/postgresql.sh 
source /etc/profile.d/postgresql.sh
ln -sv /home/postgres/postgresql/include /usr/include/postgresql
echo '/home/postgres/postgresql/lib' > /etc/ld.so.conf.d/postgresql.conf
ldconfig


#6 初始化数据库
su - postgres -c "/home/postgres/postgresql/bin/initdb -D /home/postgres/postgresql/pgdata/data/ -W"
postgresql


#7 修改白名单
#PG默认不允许远程访问数据库，可以通过修改监听地址、修改pg_hba.conf文件来实现远程访问。
cp /home/postgres/postgresql/pgdata/data/postgresql.conf /home/postgres/postgresql/pgdata/data/postgresql.conf.bak
sed -i "s|#listen_addresses = 'localhost'|listen_addresses = '*' |" /home/postgres/postgresql/pgdata/data/postgresql.conf
cp /home/postgres/postgresql/pgdata/data/pg_hba.conf /home/postgres/postgresql/pgdata/data/pg_hba.conf.bak
echo "host    all        all        0.0.0.0/0               md5" >> /home/postgres/postgresql/pgdata/data/pg_hba.conf

sed -i "s|#log_destination = 'stderr'|#og_destination = 'stderr'|" /home/postgres/postgresql/pgdata/data/postgresql.conf
sed -i "s|#logging_collector = off|logging_collector = on|" /home/postgres/postgresql/pgdata/data/postgresql.conf
sed -i "s|#log_directory = 'log'|log_directory = 'log'|" /home/postgres/postgresql/pgdata/data/postgresql.conf
sed -i "s|#log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'|log_filename = 'postgresql-%a.log'|" /home/postgres/postgresql/pgdata/data/postgresql.conf
sed -i "s|#log_truncate_on_rotation = off|log_truncate_on_rotation = on|" /home/postgres/postgresql/pgdata/data/postgresql.conf
sed -i "s|#log_rotation_age = 1d|log_rotation_age = 1d|" /home/postgres/postgresql/pgdata/data/postgresql.conf
sed -i "s|#log_rotation_size = 10MB|log_rotation_size = 0|" /home/postgres/postgresql/pgdata/data/postgresql.conf
sed -i "s|#log_line_prefix = '%m [%p] '|log_line_prefix = '%m [%p] '|" /home/postgres/postgresql/pgdata/data/postgresql.conf
sed -i "s|log_timezone = 'PRC'|log_timezone = 'Asia/Shanghai'|" /home/postgres/postgresql/pgdata/data/postgresql.conf
sed -i "s|timezone = 'PRC'|timezone = 'Asia/Shanghai'|" /home/postgres/postgresql/pgdata/data/postgresql.conf

#编写开机自动启动服务脚本
cat > /usr/lib/systemd/system/postgresql.service <<EOF
[Unit]
Description=PostgreSQL database server
After=network.target
 
[Service]
Type=forking
User=postgres
Group=postgres
ExecStart=/home/postgres/postgresql/bin/pg_ctl -D /home/postgres/postgresql/pgdata/data/ -l /home/postgres/postgresql/log/logfile start
ExecStop=/home/postgres/postgresql/bin/pg_ctl -D /home/postgres/postgresql/pgdata/data/ -ms stop
ExecReload=/home/postgres/postgresql/bin/pg_ctl -D /home/postgres/postgresql/pgdata/data/ reload

# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=300
 
[Install]
WantedBy=multi-user.target
EOF

chmod 754 /usr/lib/systemd/system/postgresql.service 
systemctl enable postgresql.service
systemctl restart postgresql.service
firewall-cmd --permanent --zone=public --add-port=5432/tcp --permanent
firewall-cmd --permanent --query-port=5432/tcp
firewall-cmd --reload
ps -ef|grep postgres


#8 启动命令\关闭命令\登录验证
#su - postgres -c "/home/postgres/postgresql/bin/pg_ctl -D /home/postgres/postgresql/pgdata/data/ -ms stop"
#su - postgres -c "/home/postgres/postgresql/bin/pg_ctl -D /home/postgres/postgresql/pgdata/data/ -l /home/postgres/postgresql/log/logfile start"
#su - postgres -c "/home/postgres/postgresql/bin/pg_ctl -D /home/postgres/postgresql/pgdata/data/ reload"
#su - postgres -c "/home/postgres/postgresql/bin/pg_isready -p 5432"
#su - postgres
#psql -p 5432 -U postgres -d postgres
#postgres=# \q


#用户名:postgres 密码:postgresql 初始数据库:postgres 端口:5432



#查看编译信息：pg_config  --configure 





