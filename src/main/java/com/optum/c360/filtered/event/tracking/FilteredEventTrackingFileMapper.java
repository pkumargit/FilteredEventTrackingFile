package com.optum.c360.filtered.event.tracking;

import java.io.IOException;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Mapper.Context;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;

public class FilteredEventTrackingFileMapper extends Mapper<LongWritable, Text, NullWritable, Text> {
	private static final Logger LOG = LogManager.getLogger(FilteredEventTrackingFileMapper.class);

	protected void setup(Context context) throws IOException, InterruptedException {
	}

	@Override
	protected void map(LongWritable key, Text value, Mapper<LongWritable, Text, NullWritable, Text>.Context context)
			throws IOException, InterruptedException {
		LOG.info("FilteredEventTrackingFileMapper.map()");
		boolean flag = false;
		String line = value.toString();
		String parts[] = line.split("\u0001");
		String srcSpecificInfo = parts[0];
		String splittedSrcSpecificInfo[] = srcSpecificInfo.split(",");
		for (int i = 0; i < splittedSrcSpecificInfo.length; i++) {
			String srcAndId[] = splittedSrcSpecificInfo[i].split("-");
			if ("AARP_2018".equals(srcAndId[0]) || "CDB_AA".equals(srcAndId[0]) || "2018".equals(srcAndId[0])) {
				flag = true;
			}
		}
		if (flag) {
			context.write(NullWritable.get(), value);
		}

	}

	@Override
	protected void cleanup(Mapper<LongWritable, Text, NullWritable, Text>.Context context)
			throws IOException, InterruptedException {
	}
}
