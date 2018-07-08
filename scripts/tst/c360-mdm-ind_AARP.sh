#!/bin/sh

###########################################
# c360-mdm-ind.sh
# this script will expect 7 params, where the last param tells us load type initial or incremental.
###########################################
#./home/fstaladm/.profile

#./home/ohcbddev/.profile

#export MAPR_TICKETFILE_LOCATION=/opt/mapr/tickets/maprticket_ohcbddev
./home/fstaladt/.profile

export MAPR_TICKETFILE_LOCATION=/opt/mapr/tickets/maprticket_fstaladt

start_time=`date +%s`

filePrefix=C360_MDM_IND_
fileSuffix=xml

C360ReconTable=/datalake/ODM/mleccm/dev/c360/d_mtables/c360_recon_tracking_temp

hbase_version=1.1.8
mapr_jars_version=1710

if [ "$#" -eq 10 ]
then
	jarLocation=$1
	queueName=$2
	crosswalkTable=$3
	mdmGoldenRecordTable=$4
	mdmLoadProcessTable=$5
	outputLocation=$6
	load=$7
	EventtrackingLocation=$8
        C360ReconTable=$9
	mdmc360idTable=${10}
else
        echo "Incorrect parameters"
	echo "sh c360-mdm-ind.sh <jar_file_location> <queue_name> <cross_walk_table> <mdm_golden_record_table> <mdm_load_process_table> <output_location>"
        exit 128
fi

export HADOOP_CLASSPATH=`/opt/mapr/hbase/hbase-${hbase_version}/bin/hbase classpath`
export LIBJARS=/opt/mapr/hbase/hbase-${hbase_version}/lib/hbase-client-${hbase_version}-mapr-${mapr_jars_version}.jar,/opt/mapr/hbase/hbase-${hbase_version}/lib/hbase-common-${hbase_version}-mapr-${mapr_jars_version}.jar,/opt/mapr/hbase/hbase-${hbase_version}/lib/hbase-server-${hbase_version}-mapr-${mapr_jars_version}.jar

splitSize=100000
reducerSize=`expr ${splitSize} \* 2`
inputFileSizeInBytes=`hadoop fs -du -s ${EventtrackingLocation} | cut -d ' ' -f1`
numberOfReducers=`expr ${inputFileSizeInBytes} / ${reducerSize}`

if [ ${numberOfReducers} -eq 0 ]
then 
	numberOfReducers=1
fi

###Removed writing to folder mdmIndividualXML as we are not renaming part files to xml
#hadoop jar /mapr${jarLocation}/c360-mdm-ind-xml-0.0.1-SNAPSHOT.jar -Dmapreduce.job.queuename=${queueName} -Dmapreduce.job.acl-view-job=* -D mapred.reduce.tasks=${numberOfReducers} -D load=${load} -D mdm.load.process.table=${mdmLoadProcessTable} -D mdm.c360id.load.table=${mdmc360idTable} -D mdm.goldenrecord.table=${mdmGoldenRecordTable} -D c360.recon.table=${C360ReconTable} -Dmapred.max.split.size=${splitSize} -libjars ${LIBJARS} MDMGOLDENRECORD ${EventtrackingLocation} ${outputLocation}/mdmIndividualXML
#hadoop jar /mapr${jarLocation}/c360-mdm-ind-xml-0.0.1-SNAPSHOT.jar -Dmapreduce.job.queuename=${queueName} -Dmapreduce.job.acl-view-job=* -D mapred.reduce.tasks=${numberOfReducers} -D load=${load} -D mdm.load.process.table=${mdmLoadProcessTable} -D mdm.c360id.load.table=${mdmc360idTable} -D mdm.goldenrecord.table=${mdmGoldenRecordTable} -D c360.recon.table=${C360ReconTable} -Dmapred.max.split.size=${splitSize} -libjars ${LIBJARS} MDMGOLDENRECORD ${EventtrackingLocation} ${outputLocation}
hadoop jar /mapr${jarLocation}/c360-mdm-ind-xml-0.0.1-SNAPSHOT.jar -Dmapreduce.job.queuename=${queueName} -Dmapreduce.job.acl-view-job=* -D mapred.reduce.tasks=${numberOfReducers} -D load=${load} -D mdm.load.process.table=${mdmLoadProcessTable} -D mdm.c360id.load.table=${mdmc360idTable} -D mdm.goldenrecord.table=${mdmGoldenRecordTable} -D c360.recon.table=${C360ReconTable} -Dmapred.max.split.size=${splitSize} -libjars ${LIBJARS} MDMGOLDENRECORD /datalake/ODM/mleccm/tst_631/cr3_mdm/t_outbound/epmp/event_tracking_filtered ${outputLocation}

if [ $? -ne 0 ]
then
        echo mdm golden record transformation to individual job failed.
else
cd /mapr${outputLocation}
find . -name 'part*' -size 0 -delete
#ctr=0
#for fileName in part*
#do
#        echo "file - ${fileName} ${filePrefix}${ctr}.${fileSuffix}"
#        mv ${fileName} ${filePrefix}${ctr}.${fileSuffix}
 #       ctr=$((ctr + 1))
#done
rm _SUCCESS
#mv * 
mv * ../../MDM_IND_ECMM_Output_AARP
fi

end_time=`date +%s`
diff=`expr ${end_time} - ${start_time}`
echo start_time=${start_time} end_time=${end_time}
echo total time in seconds ${diff}



