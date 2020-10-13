### MapReduce 模板整理

##### JAVA API

```java
package cn.zhw.hdfs;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.*;
import org.apache.hadoop.io.IOUtils;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;

public class hdfsUtil {
    public static void main(String[] args) throws URISyntaxException, IOException {
        // tem.setProperty("HADOOP_USER_NAME","root");
        // 首先获取 hdfs 集群访问地址，nameNode 的地址
        URI uri = new URI("hdfs://192.168.100.132:9000");
        // 创建一个配置文件对象
        Configuration conf = new Configuration();
        // 创建 hdfs 文件系统对象
        FileSystem fs = FileSystem.get(uri, conf);

        // 创建一个文件夹
        fs.create(new Path("/hdfs001"));

        // 本地文件上传 hdfs
        fs.copyFromLocalFile(new Path("data/word.txt"), new Path("/data"));

        // 流上传
        FileInputStream in = new FileInputStream("data/word.txt");
        FSDataOutputStream out = fs.create(new Path("/data/001"));
        byte[] b = new byte[1024 * 1024];
        int read = 0;
        while ((read = in.read(b)) > 0) {
            out.write(b, 0, read);
        }

        // 追加内容
        FileInputStream fis = new FileInputStream("data/word.txt");
        FSDataOutputStream append = fs.append(new Path("/data/1.txt"));

        // append.write("678910".getBytes());
        byte[] b1 = new byte[1024 * 1024];
        int flag = 0;
        while ((flag = fis.read(b1)) > 0) {
            append.write(b1, 0, flag);
        }

        // 将 hdfs 文件下载到本地
        FSDataInputStream in1 = fs.open(new Path("/data/001"));
        FileOutputStream out1 = new FileOutputStream("data/words.txt");
        IOUtils.copyBytes(in1, out1, conf);

        // 删除一个文件夹
        fs.delete(new Path("/hdfs001"));

        // 查看路径信息
        FileStatus[] listStatus = fs.listStatus(new Path("/data"));
        for (FileStatus status : listStatus) {
            if (status.isFile())
                System.out.println(status.getPath().getName());
        }
    }
}
```

##### main 函数模板

```java
public static void main(String[] args) throws IOException, ClassNotFoundException, InterruptedException {
	// 设置配置参数,使用默认参数
  Configuration conf = new Configuration();
  // 创建任务
  Job job = Job.getInstance(conf, DianXinAvg.class.getSimpleName());
  // 指定 jar 文件
  job.setJarByClass(DianXinAvg.class);
  
  // 指定 map 和 reduce 的类
  job.setMapperClass(DianXinMapper.class);
  job.setReducerClass(DianXinReduce.class);
  
  // 指定 map 输出的 key 和 value 的数据类型
  job.setMapOutputKeyClass(Text.class);
  job.setMapOutputValueClass(LongWritable.class);

  // 指定 reduce 输出的 key 和 value 的数据类型
  job.setOutputKeyClass(Text.class);
  job.setOutputValueClass(LongWritable.class);
  
  // 使用自定义的分区组件
	job.setPartitionerClass(CoursePartitioner.class);
	// 和自定义分区组件同时使用，根据分区的个数设置reduceTask的个数
	job.setNumReduceTasks(4);

  // 指定数据的输入输出路径
  FileInputFormat.addInputPath(job, new Path("data/xxx"));
  FileOutputFormat.setOutputPath(job, new Path("out/001"));

  // 提交任务, 如果数 true 会返回任务执行的速度信息
  job.waitForCompletion(true);
}
```

##### 字符串的一些处理方法

```java
String line = value.toString();

line.split(","); // "\t", "\\|"
line.indexOf("xxx"); // return bool
"xxxx".equals("xxx"); // 判断 xxxx 是否 与 xxxx 相同
line.startsWith("dianxin_data"); // 判断字符串开头是不是 dianxin_data
line.substring(0, 4); // 从 索引 0 开始，取四个字符串
line.replaceAll("abcd", "efgh"); // abcd 替换为 efgh
```

##### 多表联查

```java
public class DianXinJoin {

    public static void main(String[] args) throws IOException, ClassNotFoundException, InterruptedException {
        Configuration conf = new Configuration();
        conf.set("mapred.textoutputformat.separator", ",");
        Job job = Job.getInstance(conf, DianXinJoin.class.getSimpleName());
        job.setJarByClass(DianXinJoin.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileInputFormat.addInputPath(job, new Path(args[1]));

        // 指定 map 类
        job.setMapperClass(DianXinMapper.class);
        // 指定 map 输出的 key 和 value 的数据类型
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);

        // 指定 reduce 类
        job.setReducerClass(DianxinReduce.class);
        // 指定 reduce 输出的 key 和 value 的数据类型
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        // 指定输出路径
        FileOutputFormat.setOutputPath(job, new Path(args[2]));

        // 提交任务, 如果数 true 会返回任务执行的速度信息
        job.waitForCompletion(true);
    }

    public static class DianXinMapper extends Mapper<LongWritable, Text, Text, Text> {
        @Override
        protected void map(LongWritable key, Text value, Mapper<LongWritable, Text, Text, Text>.Context context)
                throws IOException, InterruptedException {
            // 获取切片路径信息
            FileSplit inputSplit = (FileSplit)context.getInputSplit();
            String path = inputSplit.getPath().toString();

            // 打标签 区分连个输入路径的数据
            // 1、判断是否是 dianxin_data 数据
            if (path.contains("dianxin_data")) {
                String line = value.toString();
                String[] split = line.split("\t");
                if (split.length == 8 && split[2] != null) {
                    // 将城市 id 作为 key
                    String id = split[2]; // Key

                    // 将 value 打上标签
                    String data_info = "dianxin_data" + "," + split[0] + "," + split[4];
                    // dianxin_data,D55433A437AEC8D8D3DB2BCA56E9E64392A9D93C,301
                    context.write(new Text(id), new Text(data_info));
                }
            }
            // 给 city_id 的数据打标
            if (path.contains("city_id")) {
                String line = value.toString();
                String[] split = line.split("\t");

                if (split.length == 2) {
                    //获取join的key，将城市id作为key
                    String cid = split[0];
                    // 将 value 打上标签
                    String city_info = "city_id" + "," + split[1];
                    // city_id,合肥市
                    context.write(new Text(cid), new Text(city_info));
                }
            }
        }
    }

    public static class DianxinReduce extends Reducer<Text, Text, Text, Text> {
        @Override
        protected void reduce(Text key, Iterable<Text> values, Reducer<Text, Text, Text, Text>.Context context)
                throws IOException, InterruptedException {
            // 83401 ({dianxin_data,D55433A437AEC8D8D3DB2BCA56E9E64392A9D93C,301}, {city_id,合肥市})
            Vector<String> datas = new Vector<String>();
            Vector<String> citys = new Vector<String>();

            for (Text value : values) {
                String line = value.toString();
                //判断开头标记，放入集合
                if (line.startsWith("dianxin_data")) {
                    datas.add(line.substring(12));
                }
                if (line.startsWith("city_id")) {
                    citys.add(line.substring(7));
                }
            }
            // 将两个集合拼接, 笛卡尔积
            for (String data : datas) {
                for (String city : citys) {
                    context.write(new Text(data + "," + key.toString()), new Text(city));
                }
            }
        }
    }
}
```

##### 指定输出文件个数

- 自定义类

```java
package cn.zhw.MapReduce.test_19_2;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.apache.hadoop.io.WritableComparable;

public class Student implements WritableComparable<Student> {
	private String course;
	private String name;
	private float avg;

	public String getCourse() {
		return course;
	}

	public void setCourse(String course) {
		this.course = course;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public float getAvg() {
		return avg;
	}

	public void setAvg(float avg) {
		this.avg = avg;
	}

	public Student() {

	}

	public Student(String course, String name, Float avg) {
		super();
		this.course = course;
		this.name = name;
		this.avg = avg;
	}

	@Override
	public String toString() {
		return course + "," + name + "," + avg;
	}

	/**
	 ** 反序列化
	 */
	@Override
	public void readFields(DataInput in) throws IOException {
		// TODO Auto-generated method stub
		course = in.readUTF();
		name = in.readUTF();
		avg = in.readFloat();

	}

	/**
	 ** 序列化
	 */
	@Override
	public void write(DataOutput out) throws IOException {
		// TODO Auto-generated method stub
		out.writeUTF(course);
		out.writeUTF(name);
		out.writeDouble(avg);
	}

	// 比较规则
	@Override
	public int compareTo(Student o) {
		// TODO Auto-generated method stub
		double flag = o.avg - this.avg;
		return flag > 0.0f ? 1 : -1;
	}
}
```

- 定义输出文件

```java
package cn.zhw.MapReduce.test_19_2;

import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.Partitioner;


public class CoursePartitioner extends Partitioner<Student, NullWritable>{
	@Override
	public int getPartition(Student key, NullWritable value, int numPartitions) {
		if ("algorithm".equals(key.getCourse())){
			return 0;
		} else if ("computer".equals(key.getCourse())) {
            return 1;
        } else if ("english".equals(key.getCourse())) {
            return 2;
        } else {
            return 3;
        }
	}
}

```

- 主类

```java
package cn.zhw.MapReduce.test_19_2;

import java.io.IOException;
import java.text.DecimalFormat;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class MapReduceAvg {

	public static class MyMapper extends Mapper<LongWritable, Text, Student, NullWritable> {
		@Override
		protected void map(LongWritable key, Text value, Mapper<LongWritable, Text, Student, NullWritable>.Context context)
				throws IOException, InterruptedException {
			String[] line = value.toString().split(",");
			long sum = 0L;
			for (int i = 2; i < line.length; i++) {
				sum += Long.parseLong(line[i]);
			}
			
			DecimalFormat df = new DecimalFormat(".0");
			float avg =  sum * 1.0f / (line.length - 2);
			float b = Float.parseFloat(df.format(avg));
			
			Student student = new Student(line[0], line[1], b);
			
			context.write(student, NullWritable.get());
		}
	}

	public static class MyReduce extends Reducer<Student, NullWritable, Student, NullWritable> {
		@Override
		protected void reduce(Student key, Iterable<NullWritable> values,
				Reducer<Student, NullWritable, Student, NullWritable>.Context context)
				throws IOException, InterruptedException {
			for (NullWritable value : values) {
				context.write(key, value);
			}
		}
	}

	public static void main(String[] args) throws IOException, ClassNotFoundException, InterruptedException {
		// 设置配置参数,使用默认参数
		Configuration conf = new Configuration();
		// 创建任务
		Job job = Job.getInstance(conf, MapReduceAvg2.class.getSimpleName());
		// 指定 jar 文件
		job.setJarByClass(MapReduceAvg2.class);
		// 指定数据的输入路径,指定第一个路径是 hdfs 的输入路径
		FileInputFormat.addInputPath(job, new Path("data/studentScore.txt"));

		// 指定 map 的类
		job.setMapperClass(MyMapper.class);
		// 指定 map 输出的 key 和 value 的数据类型
		job.setMapOutputKeyClass(Student.class);
		job.setMapOutputValueClass(NullWritable.class);

		// 指定 reduce 类
		job.setReducerClass(MyReduce.class);
		// 指定 reduce 输出的 key 和 value 的数据类型
		job.setOutputKeyClass(Student.class);
		job.setOutputValueClass(NullWritable.class);

		// 使用自定义的分区组件
		job.setPartitionerClass(CoursePartitioner.class);
		// 和自定义分区组件同时使用，根据分区的个数设置reduceTask的个数
		job.setNumReduceTasks(4);

		// 指定输出路径
		FileOutputFormat.setOutputPath(job, new Path("data/004"));

		// 提交任务, 如果数 true 会返回任务执行的速度信息
		job.waitForCompletion(true);
	}
}
```

##### 排序输出topN

```java
package cn.zhw.MapReduce.test_19_4;

import java.io.IOException;
import java.util.Random;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.SequenceFileInputFormat;
import org.apache.hadoop.mapreduce.lib.map.InverseMapper;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat;

public class MR_DnsLog2 {

	public static class MyMapper extends Mapper<LongWritable, Text, Text, LongWritable> {

		@Override
		protected void map(LongWritable key, Text value, Mapper<LongWritable, Text, Text, LongWritable>.Context context)
				throws IOException, InterruptedException {
			String line = value.toString();
			String[] split = line.split("\\|");
			String www = split[1];
			context.write(new Text(www), new LongWritable(1));
		}
	}

	public static class MyReduce extends Reducer<Text, LongWritable, Text, LongWritable> {

		@Override
		protected void reduce(Text key, Iterable<LongWritable> values,
				Reducer<Text, LongWritable, Text, LongWritable>.Context context) throws IOException, InterruptedException {
			int sum = 0;
			for (LongWritable value : values) {
				sum += value.get();
			}

			context.write(key, new LongWritable(sum));
		}
	}

  // Map 阶段结束对 key 进行排序
	private static class DescSort extends LongWritable.Comparator {

		@Override
		public int compare(byte[] b1, int s1, int l1, byte[] b2, int s2, int l2) {
			// TODO Auto-generated method stub
			return -super.compare(b1, s1, l1, b2, s2, l2);
		}

		@Override
		public int compare(WritableComparable a, WritableComparable b) {
			// TODO Auto-generated method stub
			return -super.compare(a, b);
		}
	}

	public static void main(String[] args) throws Exception {

		Path outputPath = new Path("data/009");
		Configuration conf = new Configuration();
		Path tempDir = new Path("data/wordcount-temp-" + Integer.toString(new Random().nextInt(Integer.MAX_VALUE)));
		Job job = Job.getInstance(conf, MR_DnsLog2.class.getSimpleName());
		job.setJarByClass(MR_DnsLog2.class);
		
		// 指定 map,Combiner, reduce 的类
		job.setMapperClass(MyMapper.class);
		job.setCombinerClass(MyReduce.class);
		job.setReducerClass(MyReduce.class);
		
		// 指定 map 输出的 key 和 value 的数据类型
		job.setMapOutputKeyClass(Text.class);
		job.setMapOutputValueClass(LongWritable.class);
		
		// 指定 reduce 输出的 key 和 value 的数据类型
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(LongWritable.class);
		
		FileInputFormat.addInputPaths(job, "data/dns_log.txt");
		
		// 先将词频统计任务的输出结果写到临时目录中, 下一个排序任务以临时目录为输入目录
		FileOutputFormat.setOutputPath(job, tempDir);
		
		job.setOutputFormatClass(SequenceFileOutputFormat.class);
		if (job.waitForCompletion(true)) {
			Job sortJob = Job.getInstance(conf, "sortJob");
			sortJob.setJarByClass(MR_DnsLog2.class);

			FileInputFormat.addInputPath(sortJob, tempDir);
			// 实现 key 和 value 都可以自定义类，需要实现Writable接口
			sortJob.setInputFormatClass(SequenceFileInputFormat.class);

			// InverseMapper由 hadoop 库提供，作用是实现map()之后的数据对的 key 和 value 交换
			sortJob.setMapperClass(InverseMapper.class);
		
			// job.setPartitionerClass(CoursePartitioner.class); // 使用自定义的分区组件
			// sortJob.setNumReduceTasks(1); // 将 Reducer 的个数限定为1, 最终输出的结果文件就是一个
			
			outputPath.getFileSystem(conf).delete(outputPath, true);
			FileOutputFormat.setOutputPath(sortJob, outputPath);

			sortJob.setOutputKeyClass(LongWritable.class);
			sortJob.setOutputValueClass(Text.class);
			/*
			 * hadoop 默认对 IntWritable 按升序排序，而我们需要的是按降序排列。 因此我们实现了一个
			 * IntWritableDecreasingComparator 类, 并指定使用这个自定义的 DescSort 类对输出结果中的 key
			 * (词频)进行排序
			 */
			sortJob.setSortComparatorClass(DescSort.class);
			sortJob.waitForCompletion(true);
		}
	}
}
```

##### fastjson 使用

```java
// 读取 json 文件
JSONObject josncommon = JSONObject.parseObject(common);

// 创建 json 文件
JSONObject jsonObject = new JSONObject(true);

String uid = josncommon.getString("uid");
String platform = josncommon.getString("platform");
String app_version = josncommon.getString("app_version");
String pid = josncommon.getString("pid");
String cityid = josncommon.getString("cityid");

jsonObject.put("uid", uid);
jsonObject.put("platform", platform);
jsonObject.put("app_version", app_version);
jsonObject.put("pid", pid);
jsonObject.put("cityid", cityid);
```

