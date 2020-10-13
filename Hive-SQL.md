#### Hive-SQL

**建表**

```sql
// 数据类型
tinyint -> 微整形
smallint -> 小整形
int -> 整形
bigint -> 长整型
boolean -> 布尔型
float -> 单精度浮点型
double -> 双精度浮点型
string -> 字符串型
timestamp -> 日期 YYYY-MM-DD HH:SS
date -> YYYY-MM-DD
structs, maps, arrays 
```

```sql
create table [table_name] (
userid string,
stat_data string,
tryvv int,
sucvv int,
ptime float
)
row format delimited fields terminated by '\t' // 必选，指定列之间的分隔符
stored as rcfile // 非必选，指定文件的存储格式，默认 textfile
location '/testdata/' // 指定 hdfs 存储路径，默认 /user/hive/warehouse/

// 从已存在的表建表
create table [new_table] as select * from [old_table] limit 10;
create table [new_table] like [old_table];
```

```
desc demo; // 查看表结构
show create table [table_name]; // 查看建表语句
```

**加载数据**

```sql
// 1. 从 hdfs 上加载数据(数据是 mv 过去的，不是 cp 过去的)
load data inpath '/data/xxx' [overwrite] into table table_name partition (dt=20200906_1);
'/data/xxx' -> hdfs 路径
[overwrite] -> 重复则覆盖
partition (dt=20200906) -> 指定分区(建带有分区的表有效)

// 2. 从本地加载数据
load data local inpath '~/local/data/xxx' into table table_name partition (dt=20200906_2 );

// 3. 表对表加载
create table if not exists new_table as select * from old_table;
insert [overwrite] into table new_table select * from old_table;
```

**基本语法**

1. DDL：非查询语句

   ```sql
   create database xxxx;
   show databases;
   drop databases xxxx cascade;
   show tables;
   
   // 查看表的元信息
   desc table_name;
   describe extended table_name;
   sescribe formatted table_name;
   
   // 查看建表语句
   show create table table_name;
   // 修改列数据类型
   alter table table_name change name new_name string;
   // 增加、删除分区
   alter table table_name add partition (pt=xxx)
   alter table table_name drop if exists partition (...)
   ```

2. DML：

   ```sql
   where
   join -> mapjoin 用于大表关联小表，左表是大表
   select uid, name from table_1 left outer join table_2 on 1.uid=2.uid;
   
   cast(xxx as int) -> 类型转换
   
   group by -> 分组
   partition by -> 查询分区子句
   distinct -> 去重
   select distinct name, month(orderdate), sum(cost) over(partition by month(orderdate)) from t_window;
   
   窗口函数：row_number 
   -- 分组排序
   select *, row_number() over(partition by mdn order by duration desc) as rn from dianxin_test;
   select * from (select *, row_number() over(partition by mdn order by duration desc) as rn from dianxin_test) w where w.rn <= 2;
   
   order by
   sort by
   ```

3. Hive 函数

   ```sql
   // 1. if 函数
   // if(条件表达式, 成立 -> 返回值, 不成立 -> 返回值)
   select name, if(age>18, 'old', 'yang') from table_name;
   
   // 2. 时间函数 from_unixtime
   select from_unixtime(1324408943, 'YYYY-MM-DD');
   
   // 3.日期转 UNIX 时间戳函数 : unix_timestamp
   select unix_timestamp('2011-12-07 13:01:03');
   
   // 4. case when 函数
   select name, case when age>18 then 'old' else 'yang' from table_name;
   select name, case when source>90 then 'A' when source>80 then 'B' else 'C' from table_name;
   
   // 5. 汇总统计函数 sum, count， avg, min, max, collect_set(集合去重)
   
   // 6. is null， is not null
   
   // 7. 字符串函数 concat, conxat_ws
   select concat('abc','def','gh') from table_name; -> abcdefgh
   select concat_ws('-','-','abc','def','gh') from table_name; -> abc,def,gh
   select concat_ws('|', array('a', 'b', 'c')) from table_name; -> a|b|c
   
   // 8. 字符串截取函数： substr,substring
   select substr('abcdef', 3); -> cdef
   select substr('abcdef', 3, 2); -> cd
   select substring('abcdef', 3); -> cdef
   select substr('abcdef', -1); -> f
   
   // 9. 字符串查找函数： instr, locate(从 pos 后开始查)
   select instr('abcdef', 'df'); -> 4
   select locate('a', 'abcda', 1); -> 1
   select locate('a', 'abcda', 2); -> 5
   
   // 10. 字符串 长度 函数： length
   select length('abcdef'); -> 6
   
   // 11. 字符串 格式化函数： printf
   select printf("%08X",123);
   
   // 12. 分割字符串函数 split
   select split('abtcdtef','t') from table_name; -> ['ab', 'cd', 'ef']
   
   // 13. 数组 拆分成多行：explode
   select explode(array(1, 2, 3)) from table_name;
   -> 1
   -> 2
   -> 3
   select explode(map('k1', 'v1', 'k2', 'v2')) from table_name;
   -> k1	v1
   -> k2	v2
   
   // 14. json 解析函数： get_json_object
   data = {
   "store":{
   	"fruit":[{"weight":8,"type":"apple"}, {"weight":9,"type":"pear"}],  
   	"bicycle":{"price":19.95,"color":"red"}
   	}, 
   "email":"amy@only_for_json_udf_test.net", 
   "owner":"amy" 
   }
   select get_json_object(data, $.owner) from table_name; -> any
   
   // 15. 窗口函数 row_number()
   select * row_number() over((partition by [mdn] order by [duration desc]) from table_name 
   
   // 16. regexp_replace() 字符串替换
   regexp_replace(addr,'www.taobao.com','ShoppingAction')
   ```

 4. hive-wordcount

    ```sql
    create table words(line string);
    
    select split(line, ',') from words limit 10;
    select explode(split(line, ',')) from words limit 10;
    select w.word, count(*) from (select explode(split(line, ',')) as word from words) as w group by w.word;
    ```

   5. 18 年 hive

      ```sql
      // 1. 建表
      create table studentScore (
      sid string,
      name string,
      score int
      )
      row  format delimited fields terminated by ',';
      
      // 2. 导入数据
      load data local inpath '/root/studentsScore.txt' into table studentscore;
      select * from studentscore limit 10;
      
      // 3. 统计上面创建的表中每门课程的平均分数，课程，平均分
      select sid, avg(score) as ag from (select sid, score from studentscore where score is not null) as a group by sid;
      ```

   6. 19 年 hive

      ```sql
      // 1. 建表
      create table dnslog (
      ip string,
      address string,
      time string,
      dns string,
      num int
      )
      row format delimited fields terminated by '|'
      stored as textfile;
      
      // 2. 导入数据
      hadoop fs -put dns_log.txt /data/
      load data inpath '/data/dns_log.txt' into table dnslog;
      // 3. 将字段个数不满足5个的数据过滤掉，并且将网站地址中为 "www.taobao.com" 的标记为购物网替换为“ShoppingAction ”，最后将清洗过滤后的数据全部输出
      select ip, regexp_replace(address, 'www.taobao.com', 'ShoppingAction') shop, time, dns, num from dnslog where length(ip)>0 and length(address)>0 and length(time)>0 and length(dns)>0 and length(num)>0;
      
      // 4. 统计输出该原始数据集中网站被访问次数最多的前5名的网站地址和次数
      1. select ip, address, row_number() over(partition by address, ip) from dnslog;
      -> 以 address, ip 分组
      
      2. select ip, address, count(ip) as count from dnslog group by address, ip;
      -> 以 address, ip 分组，记录 count
      
      3. select ip, address, count, row_number() over(partition by address, ip order by count desc) rank_list from (select ip, address, count(ip) as count from dnslog group by address, ip) a;
      ------------->
      select * from (select ip, address, count, row_number() over(partition by address, ip order by count desc) rank_list from (select ip, address, count(ip) as count from dnslog group by address, ip) a) b where b.rank_list<=3;
      ```

      