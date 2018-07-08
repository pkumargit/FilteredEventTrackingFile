package com.optum.c360;

import java.io.IOException;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mrunit.mapreduce.MapDriver;
import org.junit.BeforeClass;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.powermock.modules.junit4.PowerMockRunner;

import com.optum.c360.filtered.event.tracking.FilteredEventTrackingFileMapper;

import junit.framework.TestCase;


public class FilteredEventTrackingFileTestMapper extends TestCase {
	private MapDriver<LongWritable, Text, NullWritable, Text> mapDriver;
	private FilteredEventTrackingFileMapper fileMapper;

	@BeforeClass
	public void setUp() {
		fileMapper = new FilteredEventTrackingFileMapper();
		mapDriver = new MapDriver<LongWritable, Text, NullWritable, Text>();
		mapDriver.setMapper(fileMapper);

	}

	@Test
	public void testMap_FilteredEventTrackingFile() throws IOException, InterruptedException {
		mapDriver
				.withInput(new LongWritable(323422), new Text(
						"AARP_2018-1008858,CR-300000121246^A455829865^AN^A46f2b7d5-9032-0089-9e6a-cc76af6ae10e"))
				.getExpectedOutputs();
		mapDriver.withOutput(NullWritable.get(),
				new Text("AARP_2018-1008858,CR-300000121246^A455829865^AN^A46f2b7d5-9032-0089-9e6a-cc76af6ae10e"));
		mapDriver.runTest();

	}
}
