# 大数据环境搭建部分

### 注意：

- 所有的安装包默认放在虚拟机的`/root`目录下
- 环境搭建所需安装包 [下载链接](https://pan.baidu.com/s/1vk1wVTdVxyY5wuD9Q1XUvg), 提取码：`data`

#### 1、虚拟机网络配置

```shell
# CentOS 6
rm -rf /etc/udev/rules.d/70-persistent-net.rules
vim /etc/sysconfig/network-scripts/ifcfg-eth0
```

```shell
# CentOS 7 设置静态 ip
vim /etc/sysconfig/network-scripts/ifcfg-ens33

# 将 BOOTPROTO=dhcp -> BOOTPROTO=static (改)
# 将 ONBOOT=no -> ONBOOT=yes (改)

# 根据实际情况添加配置, 具体情况略, 以下为样例
ipaddr=192.168.100.129
dns1=192.168.100.2
netmask=255.255.255.0
gateway=192.168.100.2
```

**改完重启虚拟机或者重启网卡**

```shell
# CentOS 6
service network restart

# CentOS 7
systemctl restart network.service
```

#### 2、修改 hosts，改完拷贝到另外两台机器

```shell
vim /etc/hosts
# 添加以下内容
master_ip	master
node1_ip	node1
node2_ip	node2

# 主机名中一定一定一定不能有下划线、连接符！！届时统一使用azy01slave1, azy01sla类的名字!
scp /etc/hosts node1:/etc/hosts
scp /etc/hosts node2:/etc/hosts
```

#### 3、关闭防火墙

```shell
# Centos 7
systemctl stop firewalld.service
systemctl disable firewalld.service

# Centos 6
service iptables stop
chkconfig iptables off
```

#### 4、所有环境变量汇总(`/etc/profile`)

````shell
vim /etc/profile
# 添加以下内容

# JAVA_HOME
export JAVA_HOME=/opt/jdk
export PATH=$JAVA_HOME/bin:$PATH

# HADOOP_HOME
export HADOOP_HOME=/opt/hadoop
export PATH=$HADOOP_HOME/bin:$PATH

# MYSQL_HOME
export MYSQL_HOME=/opt/mysql
export PATH=$MYSQL_HOME/bin:$PATH

# HIVE_HOME
export HIVE_HOME=/opt/hive
export PATH=$HIVE_HOME/bin$PATH

# HBASE_HOME
export HBASE_HOME=/opt/hbase
export PATH=$HBASE_HOME/bin:$PATH

# SPARK_HOME
export SPARK_HOME=/opt/spark
export PATH=$SPARK_HOME/bin$PATH
````

#### 5、配置免密登录（在 master 上）

```shell
ssh-keygen -t rsa

ssh-copy-id -i master
ssh-copy-id -i node2
ssh-copy-id -i node1
```

#### 6、安装 JDK

1. 卸载系统自带的 JDK（防止自带版本造成的冲突）

   ```shell
   rpm -qa | grep jdk
   rpm -e --nodeps {file-name}
   ```

2. 安装JDK1.8

   ```shell
   # 解压 java 安装包
   tar -zxvf jdk-8u192-linux-x64.tar.gz
   mv jdk-8u192-linux-x64 /opt/jdk
   
   # 配置环境变量
   vim /etc/profile
   export JAVA_HOME=/opt/jdk
   export PATH=$JAVA_HOME/bin:$PATH
   
   # 在每次生效profile之前，备份一遍PATH，防止PATH变量受损
   echo $PATH
   # 使用export PATH=[原配置]可以还原
   export PATH=xxx
   
   source /etc/profile
   ```

3. 复制到另外两台机器上

   ```shell
   scp /opt/jdk node1:/opt
   scp /opt/jdk node2:/opt
   ```

#### 7、hadoop 配置

```shell
# 解压 hadoop 安装包
tar -zxvf hadoop-2.7.6.tar.gz
mv hadoop-2.7.6 /opt/hadoop
cd /opt/hadoop/etc/hadoop
```

1. slaves

   ```
   node1
   node2
   ```

2. hadoop-env.sh

   ```sh
   export JAVA_HOME=/opt/jdk
   ```

3. core-site.xml

   ```xml
   <property>
       <name>fs.defaultFS</name>
       <value>hdfs://master(主机名或ip):9000</value>
   </property>
   
   <property>
       <name>hadoop.tmp.dir</name>
       <value>/opt/hadoop/tmp</value>
   </property>
   
   // 可不加
   <property>
       <name>fs.trash.interval</name>
       <value>1440</value>
   </property>
   ```

4. hdfs-site.xml

   ```xml
   <property>
       <name>dfs.replication</name>
       <value>1</value>
   </property>
   
   // 可不加
   <property>
       <name>dfs.permissions</name>
       <value>false</value>
   </property>
   ```

5. mapred-site.xml

   ```xml
   <property>
       <name>mapreduce.framework.name</name>
       <value>yarn</value>
   </property>
   
   // 可不加
   <property>
       <name>mapreduce.jobhistory.address</name>
       <value>master:10020</value>
   </property>
   
   // 可不加
   <property>
       <name> mapreduce.jobhistory.webapp.address</name>
       <value>master:19888</value>
   </property>
   ```

6. yarn-site.xml

   ```xml
   <property>
       <name>yarn.resourcemanager.hostname</name>
       <value>master</value>
   </property>
   
   <property>
       <name>yarn.nodemanager.aux-services</name>
       <value>mapreduce_shuffle</value>
   </property>
   
   // 可不加
   <property>
       <name>yarn.log-aggregation-enable</name>
       <value>true</value>
   </property>
   
   // 可不加
   <property>
       <name>yarn.log-aggregation.retain-seconds</name>
       <value>604800</value>
   </property>
   ```

**把 hadoop 拷到其他机器上**

```shell
scp -r /opt/hadoop  node1:/opt/
scp -r /opt/hadoop  node2:/opt/
```

**在 master 上初始化 hadoop 集群**

```shell
hadoop namenode -format
```

**启动节点**

```shell
cd /opt/hadoop/sbin

./start-dfs.sh
./start-yarn.sh

# 或者
./start-all.sh

# jps 查看进程
jps
```

主节点: 

1. Namenode

2. Resourcemanager (yarn 的, 出问题了查 yarn-site.xml)

3. SecondaryNameNode

子节点: 

1. Datanode

2. Nodemanager

**如果第一次启动失败了，请重新检查配置文件或者哪里步骤少了再次重启的时候:**

```shell
# 需要手动将每个节点的tmp目录删除:
rm -rf /opt/hadoop/tmp

# 然后执行将namenode格式化
# 在主节点执行命令
./bin/hdfs namenode -format
```

#### 8、MySQL

1. 先卸载冲突源

    ```shell
    rpm -qa | grep mysql
    rpm -qa | grep mariadb(CentOS 7 注意)
    rpm -e --nodeps {file-name}
    ```

2. 使用 `rpm` 包安装

    ```shell
    rpm -ivh MySQL-client-5.1.73-1.glibc23.x86_64.rpm
    rpm -ivh MySQL-server-5.1.73-1.glibc23.x86_64.rpm
    ```

3. 启动 mysql 服务(安装好 `server `后一般会自启动)

    ```shell
    service mysql start
    ```

4. 加入到开机启动项

    ```shell
    chkconfig mysql on
    ```

5. 初始化配置`mysql`服务

    ```shell
    mysql_secure_installation
    ```

6. 报错解决方法:

    ```shell
    ps aux | grep mysql
    
    # kill pid
     kill -9 pid1 pid2 …
    ```

4. 登录 MySQL

    ```shell
    mysql -uroot -p
    # password:123456
    ```

5. 设置用户权限

    ```sql
    use mysql;
    update user set host='%' where user = 'root';
    flush privileges;
    
    // 建 hive 表
    create database hive default charset utf8;
    
    show databases; // 确保有hive表
    exit;
    ```

**MySQL 配置的疑难解答**

检查`service mysql status`，如果在非启动状态有锁住，直接删去锁文件（status上会指定路径）。

mysql 可能会出现启动不完全的情况。`ps -aux`/`ps -ef`检查所有 mysql 服务的进程号，`kill -9`杀死 mysql 的所有进程重新启动。

#### 9、hive 配置文件

1. **hive-env.sh**(hive-env.sh.template -> hive-env.sh)

   ```sh
   HADOOP_HOME=/opt/hadoop
   JAVA_HOME=/opt/jdk
   HIVE_HOME=/opt/hive
   ```

2. **hive-site.xml**(从 hive-default.xml.template 拷贝）

   ```.vimrc
   " vim 配置方便查找(选择配置) 
   set ignorecase " 自动跳到第一个匹配的结果
   set incsearch  " 搜索时忽略大小写
   ```

   ```xml
   # vim使用`/`加关键字搜索，n切换到下一个搜索项，N切换到上一个搜索项
   <property>
      <name>javax.jdo.option.ConnectionURL </name> 
      <value>jdbc:mysql://主机ip(不要使用hosts):3306/hive?useSSL=false</value> 
   </property>
   
   <property> 
      <name>javax.jdo.option.ConnectionDriverName </name> 
      <value>com.mysql.jdbc.Driver </value> 
   </property> 
   
   <property>
      <name>javax.jdo.option.ConnectionUserName</name>
      <value>root</value>
   </property> 
   
   <property> 
      <name>javax.jdo.option.ConnectionPassword </name> 
      <value>123456</value> 
   </property>
   
   <property>
      <name>hive.querylog.location</name>
   <value>/opt/hive/tmp</value>
   </property>
   
   <property>
      <name>hive.exec.local.scratchdir</name>
   <value>/opt/hive/tmp</value>
   </property>
   
   <property>
       <name>hive.downloaded.resources.dir</name>
       <value>/opt/hive/tmp</value>
   </property>
   ```

```shell
# 提供 mysql-connector jar包
cp /root/mysql-connector-java-5.1.17-bin.jar /opt/hive/lib/

# 替换掉 hadoop 的 jline 的版本 (高版本的似乎不自带 jline, 目前只知道 hadoop1.6 需要先删除 jline-0.9.94.jar)
rm -rf /opt/hadoop/share/hadoop/yarn/lib/jline-0.9.94.jar
cp /opt/hive/lib/jline-2.12.jar /opt/hadoop/share/hadoop/yarn/lib/
```

**拷贝配置文件到所有机器上**

```shell
scp -r /opt/hive node1:/opt
scp -r /opt/hive node2:/opt
```

**初始化元数据：**

```shell
schematool -dbType mysql -initSchema
```

**启动 hive，查看是否运行正常**

```sql
show databases;
set hive.cli.print.current.db=true
exit;
```

**hadoop 退出 safe mode**

```
hadoop dfsadmin -safemode leave
```

**hdfs-site.xml的一些配置**

```xml
设置dfs权限打开 				truedfs.permissions
设置HDFS数据块的备份数		  dfs.replication 
设置数据块写入的最多重试次数 	   dfs.client.block.write.retries
设置dfs最大并发对象数          dfs.max.objects
设置DateNode启动的服务线程数   dfs.datanode.handler.count
```

**hdfs dfs的一些指令，其实跟 bash 的指令差不多：**

```shell
-ls
-mkdir [-p]
-touchz  (跟bash的touch是一样的)
-rmr
-appendToFile File1 File2   (追加File1到File2尾部)
-chmod 644 File1
-cat
-put

# 上传命令：hdfs dfs -put 本地文件路径 hdfs的路径
hdfs dfs -put /usr/local/testdata/anhui.txt /data/

# 下载命令：上传命令：hdfs dfs -get  hdfs的路径 本地文件路径
hdfs dfs -get /data/anhui.txt /usr/local/
```

**hdfs 传输问题优先考虑防火墙的问题，优先先尝试关闭防火墙(但实际比赛环境好像没有防火墙)**
hdfs 报错：`appendToFile: Failed to APPEND_FILE /data/file/data1.csv for DFSClient_NONMAPREDUCE_-1657827142_1 on 192.168.1.100 because lease recovery is in progress. Try again later.`
在`hdfs-site.xml`中追加 `name: dfs.client.block.write.replace-datanode-on-failure.policy value=NEVER`

#### ~~10、zookeeper~~

**配置环境变量**

```shell
ZOOKEEPER_HOME=/opt/zookeeper
export PATH=$ZOOKEEPER_HOME/bin:$PATH
```

**修改配置文件**

zoo.cfg(从 zoo_sample.cfg 复制)

```cfg
dataDir=/opt/zookeeper/data
server.0=master:2888:3888
server.1=node1:2888:3888
server.2=node2:2888:3888
```

**同步到其它节点**

```shell
scp -r /opt/zookeeper node1:/opt
scp -r /opt/zookeeper node2:/opt
```

**创建`/opt/zookeepe/data`目录(每台机器都需要配置)**

```shell
mkdir /opt/zookeeper/data

# 在 data 目录下创建 myid 文件
vim myid
# 分别加上0, 1, 2
# master -> 0
# node1  -> 1
# node2  -> 2
```

**启动 zookeeper**

```shell
# 三台都需要执行
zkServer.sh start

# 查看状态
zkServer.sh status

# 当有一个 leader 的时候启动成功

# 连接 zookeeper
zkCli.sh

# zk shell 操作
ls /                  查找根目录
create /test abc      创建节点并赋值
get /test             获取指定节点的值
set /test cb          设置已存在节点的值
rmr /test             递归删除节点
delete /test/test01   删除不存在子节点的节点

```

#### 11、hbase 配置文件

1. hbase-env.sh

   ```sh
   # 1、改JAVA_HOME
   
   # 2.1、未安装 zookeeper
   	export HBASE_MANAGES_ZK=true
   # 2.2、安装 zookeeper
   	export HBASE_MANAGES_ZK=false
   # 这个关系到 HMaster 的启动
   ```

2. hbase-site.xml

   ```xml
   <property> 
   	<name>hbase.rootdir</name>
       <value>hdfs://matser/hbase</value>
   </property>
   
   <property> 
       <name>hbase.cluster.distributed</name>
       <value>true</value> 
   </property> 
   
   <property> 
       <name>hbase.zookeeper.quorum</name>
       <value>master,node1,node2</value>
   </property>
   
   # 装了 zookeeper 则不需要此配置
   <property>
      <name>hbase.zookeeper.property.dataDir</name> 
      <value>/opt/hbase/zookeeper</value>
   </property>
   ```

3. regionservers

   ```
   node1
   node2
   ```

**拷贝配置文件到所有机器上**

```
scp -r /opt/hbase node1:/opt
scp -r /opt/hbase node2:/opt
```

**启动 hbase**

```shell
./start-hbase.sh

# 进入 hbase sell
hbase shell
```

在master、node2、node3中的任意一台机器使用`./bin/hbase shell `进入hbase自带的shell环境，然后使用命令`version`等，进行查看hbase信息及建立表等操作

**关闭安全模式**

```shell
hadoop dfsadmin -safemode leave
```

主节点: 

1. HMaster

2. HQuorumPeer

子节点: 

1. HRegionServer

2. HQuorumPeer

**hadoop配置的疑难解答**

*namenode 没有启动成功：*

查看 namenode 的日志。根据实际情况随机应变。

大部分情况尝试删除 hadoop 的 tmp 目录，解决 namenode 启动故障。

从节点的 NodeManager 没有启动，尝试将 hadoop 的配置文件拷出，重新解压安装 hadoop 重新初始化。

**注意 hadoop 拷贝到其他从节点在初始化 namenode 之前。**

#### 12、Spark

**配置环境变量**

```shell
export SPARK_HOME=/opt/spark
export PATH=$SPARK_HOME:/bin:$PATH
```

1. **sprk-env-sh(从 spark-env.sh.template 复制)**

   ```shell
   export SPARK_MASTER_IP=master
   export SPARK_MASTER_PORT=7077
   export SPARK_WORKER_CORES=1
   export SPARK_WORKER_INSTANCES=1
   export SPARK_WORKER_MEMORY=1g
   export JAVA_HOME=/opt/jdk
   ```

2. **slaves(从slaves.template 复制)**

   ```
   node1
   node2
   ```

**拷贝配置文件到所有机器上**

```shell
scp -r /opt/spark node1:/opt
scp -r /opt/spark node2:/opt
```

**启动 Spark**

```shell
./sbin/start-all.sh

# 访问spark ui
http://master:8080/
```

**增加 hadoop 配置文件地址**

```shell
vim spark-env.sh

export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
```

**往yarn提交任务需要增加两个配置(yarn.site.xml)**

```xml
<property>
    <name>yarn.nodemanager.pmem-check-enabled</name>
    <value>false</value>
</property>

<property>
    <name>yarn.nodemanager.vmem-check-enabled</name>
    <value>false</value>
</property>
```

**同步到其他节点，重启 yarn**

```shell
scp -r /opt/hadoop/etc/hadoop/yarn-site.xml node1: `pwd`
scp -r /opt/hadoop/etc/hadoop/yarn-site.xml node2: `pwd`

stop-yarn.sh
start-yarn.sh
```

#### 13、Python

**安装编译所需的环境(在`tensorflow_torch.tar.gz`内)**

```shell
tar -zxvf tensorflow_torch.tar.gz
cd tensorflow_torch/rpm
rpm -ivh --nodeps --force *.rpm
```

**编译安装**

```shell
tar -zxvf Python-3.6.3.tgz
cd Python-3.6.3
./configure --prefix=/opt/python36

make

# make 结束后进行
make install
```

**创建软链接**

```shell
ln -s /opt/python36/bin/python3 /usr/bin/python3
ln -s /opt/python36/bin/pip3 /usr/bin/pip3
```

**升级 pip**

```shell
cd /root/tensorflow_torch
pip3 install pip-20.2.3-py2.py3-none-any.whl
```

**安装 Tensorflow**

```shell
# numpy-1.17.2-cp36-cp36m-manylinux1_x86_64.whl
# protobuf-3.9.2-cp36-cp36m-manylinux1_x86_64.whl
# requirements.txt
# six-1.12.0-py2.py3-none-any.whl
# tensorflow-1.1.0rc1-cp36-cp36m-manylinux1_x86_64.whl
# Werkzeug-0.16.0-py2.py3-none-any.whl
# wheel-0.33.6-py2.py3-none-any.whl
cd /root/tensorflow_torch/tensorflow
pip3 install *.whl
```

**Tensorflow 测试代码**

```python
import tensorflow as tf
sess = tf.Session()
hello = tf.constant('Hello,world!')
print(sess.run(hello))
```

**安装 PyTorch**

```shell
cd /root/tensorflow_torch/pytorch
# 安装 future(要需要先安装，不然后面会报错)
tar zxvf future-0.18.2.tar.gz
cd future-0.18.2
python3 setup.py install

# 安装其他
# Pillow-7.2.0-cp36-cp36m-manylinux1_x86_64.whl
# torch-1.6.0+cpu-cp36-cp36m-linux_x86_64.whl
# torchvision-0.7.0+cpu-cp36-cp36m-linux_x86_64.whl
cd ..
pip3 install *.whl
```

**PyTorch 测试代码**

```python
import torch
print(torch.__version__)
print(torch.tensor([1, 2]))
```

**排错**

```shell
python3.6: error while loading shared libraries: libpython3.6m.so.1.0:cannot open shared object file: No such file or directory

# 使用命令ldd /usr/local/Python-3.6/bin/python3 检查其动态链接
```

```shell
# 拷贝文件到lib库
cd /root/Python-3.6.5
cp libpython3.6m.so.1.0 /usr/local/lib64/
cp libpython3.6m.so.1.0 /usr/lib/
cp libpython3.6m.so.1.0 /usr/lib64/
```
