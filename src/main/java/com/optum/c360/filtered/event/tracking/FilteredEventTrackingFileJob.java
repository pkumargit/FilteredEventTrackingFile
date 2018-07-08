package com.optum.c360.filtered.event.tracking;

import java.io.IOException;
import java.util.StringTokenizer;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;

public class FilteredEventTrackingFileJob {
	private static final Logger LOG = LogManager.getLogger(FilteredEventTrackingFileJob.class);
	private static String[] otherArgs;
	private static Configuration conf = new Configuration();

	public static void main(String[] args) throws Exception {
		String jobName = "";
		String inputFileLocation = "";
		String outputLocation = "";
		String queueName = "";
		boolean completion = false;
		otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
		if ((otherArgs != null) && (otherArgs.length > 0)) {
			jobName = otherArgs[0];
		}
		if ("FILTEREVENTTRACKINGFILE".equals(jobName)) {
			if ((otherArgs != null) && (otherArgs.length > 1)) {
				inputFileLocation = otherArgs[1];
				outputLocation = otherArgs[2];
				queueName = otherArgs[3];

			}
			conf.set("mapreduce.job.queuename", queueName);
			Job job = getFilteredEventTrackingFileJob(inputFileLocation, outputLocation);
			try {
				completion = job.waitForCompletion(true);
			} catch (ClassNotFoundException e) {
				e.printStackTrace();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	}

	public static Job getFilteredEventTrackingFileJob(String inputFileLocation, String outputLocation)
			throws IOException {
		Job job = Job.getInstance(conf, "FILTER EVENT TRACKING FILE");
		job.setJarByClass(FilteredEventTrackingFileJob.class);
		job.setMapperClass(FilteredEventTrackingFileMapper.class);
		job.setMapOutputKeyClass(NullWritable.class);
		job.setMapOutputValueClass(Text.class);
		job.setOutputFormatClass(TextOutputFormat.class);
		FileInputFormat.addInputPath(job, new Path(inputFileLocation));
		FileSystem fs = FileSystem.get(conf);
		Path outputPath = new Path(outputLocation);
		if (fs.exists(outputPath)) {
			fs.delete(outputPath, true);
		}
		FileOutputFormat.setOutputPath(job, new Path(outputLocation));
		return job;
	}
}
