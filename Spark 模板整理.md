### Spark 模板整理

#### 19 年网络赛

```scala
package cn.zhw.spark.test

import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}

object MovieData2 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setAppName("SparkDemo")
    conf.setMaster("local")
    val sc: SparkContext = new SparkContext(conf)
    // 读取hdfs数据
    val data: RDD[String] = sc.textFile("hdfs://192.168.247.146:9000/data/log_movie.txt")
    val data1: RDD[String] = data.filter(line => line.indexOf("烈火英雄") != (-1))
    // 写入数据到hdfs系统
    data1.saveAsTextFile("hdfs://192.168.247.146:9000/data/log_movie_2")
  }
}
```

```scala
package cn.zhw.spark.test

import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}

object MovieData3 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setMaster("local")
    conf.setAppName("SparkDemo")

    val sc: SparkContext = new SparkContext(conf)

    val data: RDD[String] = sc.textFile("hdfs://192.168.247.146:9000/data/log_movie_2/part-00000")

    val data1: RDD[(String, Int)] = data.map(line => (line.split(",")(8), 1))
    val sum: Long = data1.count()

    val data2: RDD[(String, Int)] = data1.reduceByKey(_ + _)
    data2.foreach(line => {
      println(line._1 + ": " + (line._2.toDouble * 100 / sum).formatted("%.2f") + "%")
    })
    data2.saveAsTextFile("hdfs://192.168.247.146:9000/data/log_movie_3")
  }
}
```

```scala
package cn.zhw.spark.test

import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}
object MovieData4_1 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setMaster("local")
    conf.setAppName("SparkDemo")

    val sc: SparkContext = new SparkContext(conf)

    val data: RDD[String] = sc.textFile("hdfs://192.168.247.146:9000/data/log_movie.txt")
    val data1: RDD[Array[String]] = data.filter(line => {
      line.indexOf("上海堡垒") != (-1)).map(line => line.split(","))
    })

    val data2: RDD[(String, Int)] = data1.map(line => {
      if (line(1) .indexOf("2019-昨天") == (-1)){
        (line(1), 1)
      } else {
        ("2019-昨天", 1)
      }
    }) // .foreach(println)

    data2.reduceByKey(_ + _).sortBy(line => line._1).foreach(println)
    data2.saveAsTextFile("hdfs://192.168.247.146:9000/data/log_movie_4_1")
  }
}
```

#### 19 年正式赛


```scala
package cn.zhw.spark.test

import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}

object MovieData4_2 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setMaster("local")
    conf.setAppName("SparkDemo")

    val sc: SparkContext = new SparkContext(conf)

    val data: RDD[String] = sc.textFile("hdfs://192.168.247.146:9000/data/log_movie.txt")

    val data1: RDD[Array[String]] = data.filter(line => {
      line.indexOf("上海堡垒") != (-1)).map(line => line.split(",")
    })

    val data2: RDD[(Long, String, String)] = data1.map(line => {
      (line(4).toLong, line(5), line(7))
    })

    data2.sortBy(-_._1).take(5).foreach(println)
    data2.saveAsTextFile("hdfs://192.168.247.146:9000/data/log_movie_4_2")
  }
}
```

```scala
package cn.zhw.spark.test2

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

object demo1 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setAppName("SparkDemo")
    conf.setMaster("local")

    val sc = new SparkContext(conf)
    val data: RDD[String] = sc.textFile("data/ershoufang-clean-utf8-v1.1.csv")

    val data2: RDD[String] = data.filter(line => {
      "商品房".equals(line.split(",")(18)) && "普通住宅".equals(line.split(",")(20))
    })
    println(data2.count())
    data2.saveAsTextFile("data/ershoufang")
  }
}
```

```scala
package cn.zhw.spark.test2

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

object demo2 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setAppName("SparkDemo")
    conf.setMaster("local")

    val sc: SparkContext = new SparkContext(conf)
    val data: RDD[String] = sc.textFile("data/ershoufang-clean-utf8-v1.1.csv")

    val data2: RDD[String] = data.filter(line => {
      "普通住宅".equals(line.split(",")(20))
    })
    val cx: Long = data2.count()
    val data3: RDD[(String, Int)] = data2.map(line => (line.split(",")(2), 1))
    // val data4: RDD[(String, Int)] = data3.groupByKey().map(x => (x._1, x._2.sum))
    val data4: RDD[(String, Int)] = data3.reduceByKey(_ + _)
    data4.map(line => {
      (line._1, (line._2.toDouble * 100 / cx).formatted("%.2f") + "%")
    }).foreach(println)
  }
}
```

```scala
package cn.zhw.spark.test2

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

object demo3 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setAppName("SparkDemo")
    conf.setMaster("local")

    val sc = new SparkContext(conf)
    val data: RDD[String] = sc.textFile("data/ershoufang-clean-utf8-v1.1.csv")
    val data1: RDD[String] = data.filter(line => {
      line.split(",")(2) != "" && line.split(",")(2) != "areaName"
    })

    val data2: RDD[(String, Int)] = data1.map(line => (line.split(",")(2), 1))
    data2.reduceByKey(_+_).sortBy(line => line._2).foreach(println)
  }
}
```

```scala
package cn.zhw.spark.test2

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

object demo4 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setAppName("SparkDemo")
    conf.setMaster("local")

    val sc: SparkContext = new SparkContext(conf)
    val data: RDD[String] = sc.textFile("data/ershoufang-clean-utf8-v1.1.csv")

    val data1: RDD[String] = data.filter(line => {
      line.split(",")(2) != "" && line.split(",")(4) != ""
    })
    val data2: RDD[(String, Long)] = data1.map(line => {
      (line.split(",")(2), line.split(",")(4).toLong)
    })
    val data3: RDD[(String, Double)] = data2.groupByKey().map(line => {
      (line._1, (line._2.sum.toDouble / line._2.toArray.length))
    })
    data3.sortBy(line => -line._2).foreach(println)
  }
}
```

```scala
package cn.zhw.spark.test2

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

object demo5 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setAppName("SparkDemo")
    conf.setMaster("local")

    val sc: SparkContext = new SparkContext(conf)
    val data: RDD[String] = sc.textFile("data/ershoufang-clean-utf8-v1.1.csv")

    val data1: RDD[String] = data.filter(line => line.split(",")(4) != "")
    val data2: RDD[(String, Long)] = data1.map(line => (line, line.split(",")(4).toLong))
    // val data3 = data2.groupByKey().map(line => {
    // (line._1, (line._2.sum.toDouble / line._2.toArray.length))
    // })
    // data2.sortBy(line => -line._2).top(20).foreach(println)
    data2.sortBy(line => -line._2).take(20).foreach(line => println(line._2, line._1))
  }
}
```

#### 18 年 A 卷

```scala
package cn.zhw.spark.test3

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

object demo1 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setAppName("SparkDemo")
    conf.setMaster("local")

    val sc: SparkContext = new SparkContext(conf)

    val data: RDD[String] = sc.textFile("data/top250_f1.txt")
    val data1: RDD[(String, Long)] = data.map(line => {
      (line.split("\t")(1), line.split("\t")(8).toLong)
    })
    data1.reduceByKey(_+_).sortBy(line => -line._2).take(5).foreach(println)
  }
}
```

```scala
package cn.zhw.spark.test3

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

object demo2 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setAppName("SparkDemo")
    conf.setMaster("local")

    val sc: SparkContext = new SparkContext(conf)

    val data: RDD[String] = sc.textFile("data/top250_f1.txt")
    val data2: RDD[String] = data.filter(line => line.split("\t")(4).toLong > 2013)
    
    val data3: RDD[(String, Int)] = data2.map(line => (line.split("\t")(5), 1))
    
    data3.reduceByKey(_+_).sortBy(line => -line._2).take(5).foreach(println)
  }
}
```

```scala
package cn.zhw.spark.test3

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

object demo3 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf()
    conf.setAppName("SparkDemo")
    conf.setMaster("local")

    val sc: SparkContext = new SparkContext(conf)
    
    val data: RDD[String] = sc.textFile("data/top250_f1.txt")
    
    val data1: RDD[String] = data.filter(line => {
      line.split("\t")(6).indexOf("爱情") != (-1) && line.split("\t")(6).indexOf("剧情") != (-1)
    })
    
    val data2: RDD[(String, Double)] = data1.map(line => {
      (line.split("\t")(1), (line.split("\t")(7).toDouble) * (line.split("\t")(8).toDouble))
    })
    
    data2.sortBy(line => -line._2).take(10).foreach(println)
  }
}
```

spark的job输出结果可保存在内存中，而MapReduce的job输出结果只能保存在磁盘中，io读取速度要比内存中慢；

spark以线程方式运行，MapReduce以进程的方式运行，进程要比线程耗费时间和资源；

spark提供了更为丰富的算子操作；

spark提供了更容易的api,支持python,java,scala;

 

hive是基于Hadoop构建的一套数据仓库分析系统，它提供了丰富的SQL查询方式来分析存储在Hadoop分布式文件系统中的数据：可以将结构化的数据文件映射为一张数据库表，并提供完整的SQL查询功能；可以将SQL语句转换为MapReduce任务运行，通过自己的SQL查询分析需要的内容，这套SQL简称Hive SQL，使不熟悉mapreduce的用户可以很方便地利用SQL语言查询、汇总和分析数据。