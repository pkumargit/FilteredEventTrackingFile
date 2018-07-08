#!/bin/sh

#./home/ohcbddev/.profile
#export MAPR_TICKETFILE_LOCATION=/opt/mapr/tickets/maprticket_ohcbddev

#user=$(whoami)
#. /home/$user/.profile
#export MAPR_TICKETFILE_LOCATION=/opt/mapr/tickets/maprticket_$user

. /home/fstaladp/.profile

export MAPR_TICKETFILE_LOCATION=/opt/mapr/tickets/maprticket_fstaladp

###########################################
# c360-mdm-crosswalk.sh
#
###########################################

filePrefix=C360_MDM_CROSSWALK_
fileSuffix=xml

hbase_version=1.1.8
mapr_jars_version=1703

if [ "$#" -eq 12 ]
then
jarLocation=$1
queueName=$2
crosswalkTable=$3
mdmLoadProcessTable=$4
outputLocation=$5
load=$6
EventtrackingLocation=$7
EventtrackingTable=$8
goldenrecordTable=$9
C360ReconTable=${10}
mdmc360idTable=${11}
c360crosswalkTable=${12}
else
echo "Incorrect parameters"
echo "sh c360-mdm-crosswalk.sh <jar_file_location> <queue_name> <cross_walk_table> <mdm_load_process_table> <output_location> <Load> <EventtrackingLocation>"
exit 128
fi

# following few lines will generate the mdm config file for which is used for next proc_date

#C360ReconTable=/datalake/ODM/mleccm/tst/c360/t_mtables/c360_recon_tracking_tst
#C360ReconTable=/datalake/ODM/mleccm/dev/c360/d_mtables/c360_recon_tracking_temp
echo "C360ReconTable Table:::"${C360ReconTable}
echo "goldenrecordTable Table:::"${goldenrecordTable}
echo "Lookup Table:::"${mdmc360idTable}
echo "Croswalk c360 Table:::"${c360crosswalkTable}
echo ${C360ReconTable}


day_of_week=`date +%u`
if [ ${day_of_week} -eq 5 ]
then
date_val=`date -d "+3 days" +"%Y%m%d"`
else
date_val=`date -d "+1 days" +"%Y%m%d"`
fi
date_val=`date -d "+0 days" +"%Y%m%d%H%M%S%3N"`
partialPath=`echo ${outputLocation} | cut -d "/" -f1-10`
outputPath="${partialPath}/proc_date=${date_val}"

outputLocation=${outputPath}
echo outputLocation=${outputLocation}

#/mapr/datalake/ODM/mleccm/dev/c360/d_config/context/dev/mdm_config_param_date.txt
#/mapr/datalake/ODM/mleccm/dev/c360/d_scripts/jars
#/mapr/datalake/ODM/mleccm/dev/c360/d_scripts/jars/../../*_config/context
env_word=`echo "${jarLocation}" | cut -d "/" -f5`
if [ "$env_word"x = "dev_631x" ]
then
env_letter=d
elif [ "$env_word"x = "tst_631x" ]
then
env_letter=t
elif [ "$env_word"x = "prd_631x" ]
then
env_letter=p
elif [ "$env_word"x = "stg_631x" ]
then
env_letter=s
fi
file_name=/mapr${jarLocation}/../../${env_letter}_config/context/prd/mdm_config_param_date.txt
echo "param_date=${date_val}" > ${file_name}
echo "query_run_param_date=${date_val} 00:00:00" >> ${file_name}



export HADOOP_CLASSPATH=`/opt/mapr/hbase/hbase-${hbase_version}/bin/hbase classpath`
export LIBJARS=/mapr${jarLocation}/ecm-1.0-SNAPSHOT-crosswalk-v11_00.jar,/mapr${jarLocation}/jaxb2-basics-runtime-0.11.0.jar,/opt/mapr/hbase/hbase-${hbase_version}/lib/hbase-client-${hbase_version}-mapr-${mapr_jars_version}.jar,/opt/mapr/hbase/hbase-${hbase_version}/lib/hbase-common-${hbase_version}-mapr-${mapr_jars_version}.jar,/opt/mapr/hbase/hbase-${hbase_version}/lib/hbase-server-${hbase_version}-mapr-${mapr_jars_version}.jar


export numberOfReducersE=20
#-D mapred.reduce.tasks=${numberOfReducers}

####To extract from EVENTRACKING Table-UNLOCK
hadoop jar /mapr${jarLocation}/c360-mdm-crosswalk-xml-0.0.1-SNAPSHOT.jar -Dmapreduce.job.queuename=${queueName} -Dmapreduce.job.acl-view-job=* -D mapred.reduce.tasks=${numberOfReducersE} -D mdm.load.process.table=${mdmLoadProcessTable} -D mdm.goldenrecord.table=${goldenrecordTable} -D crosswalk.table=${crosswalkTable} -D mdm.event.tracking.table=${EventtrackingTable} -D load=${load} -libjars ${LIBJARS} EVENTTRACKING ${outputLocation} ${EventtrackingLocation}

if [ $? -ne 0 ]
then
echo mdm Eventracking read job failed.
exit 13
fi


splitSize_Active=1000000
splitSize=100000
reducerSize=`expr ${splitSize} \* 2`
inputFileSizeInBytes=`hadoop fs -du -s ${EventtrackingLocation} | cut -d ' ' -f1`
numberOfReducers=20
#numberOfReducers=`expr ${inputFileSizeInBytes} / ${reducerSize}`

#if [ ${numberOfReducers} -eq 0 ]
#then
#	numberOfReducers=1
#fi


########NEW CODE
echo "Here in new code"
#######UNLOCK

hadoop jar /mapr${jarLocation}/c360-mdm-crosswalk-xml-0.0.1-SNAPSHOT.jar -Dmapreduce.job.queuename=${queueName} -Dmapreduce.job.acl-view-job=* -D mdm.eventtracking.path=${EventtrackingLocation} -D mdm.goldenrecord.table=${goldenrecordTable} -Dmapred.max.split.size=${splitSize} -libjars ${LIBJARS} DELETEINDICATORSTATUS

if [ $? -ne 0 ]
then
echo mdm DELETEINDICATORSTATUS read job failed.
exit 13
fi

hadoop jar /mapr${jarLocation}/c360-mdm-crosswalk-xml-0.0.1-SNAPSHOT.jar -Dmapreduce.job.queuename=${queueName} -Dmapreduce.job.acl-view-job=* -D mdm.eventtracking.path=${EventtrackingLocation} -D mdm.c360id.load.table=${mdmc360idTable} -Dmapreduce.map.memory.mb=5120 -Dmapreduce.reduce.memory.mb=5120 -Dmapreduce.map.java.opts=-Xmx4096m -Dmapreduce.reduce.java.opts=-Xmx4096m -D mdm.c360.crosswalk.table=${c360crosswalkTable} -D mdm.load.process.table=${mdmLoadProcessTable} -D crosswalk.table=${crosswalkTable} -D mdm.event.tracking.table=${EventtrackingTable} -D c360.recon.table=${C360ReconTable} -Dmapred.max.split.size=${splitSize} -libjars ${LIBJARS} C360INACTIVECROSSWALKLOAD ${outputLocation}


if [ $? -ne 0 ]
then
echo mdm C360INACTIVECROSSWALKLOAD read job failed.
exit 13
fi

#######UNLOCK
hadoop jar /mapr${jarLocation}/c360-mdm-crosswalk-xml-0.0.1-SNAPSHOT.jar -Dmapreduce.map.memory.mb=5120 -Dmapreduce.reduce.memory.mb=5120 -Dmapreduce.map.java.opts=-Xmx4096m -Dmapreduce.reduce.java.opts=-Xmx4096m -Dmapreduce.job.queuename=${queueName} -Dmapreduce.job.acl-view-job=* -Dmapred.max.split.size=${splitSize} -D mdm.c360id.load.table=${mdmc360idTable} -D mdm.eventtracking.path=${EventtrackingLocation} -D mdm.c360.crosswalk.table=${c360crosswalkTable} -D mdm.load.process.table=${mdmLoadProcessTable} -D crosswalk.table=${crosswalkTable} -D mdm.event.tracking.table=${EventtrackingTable} -D c360.recon.table=${C360ReconTable} -libjars ${LIBJARS} C360ACTIVECROSSWALKLOAD
#-Dmapred.max.split.size=${splitSize_Active}

if [ $? -ne 0 ]
then
echo mdm C360ACTIVECROSSWALKLOAD read job failed.
exit 13
fi

##########CROSWWALK
#####UNLOCK
hadoop jar /mapr${jarLocation}/c360-mdm-crosswalk-xml-0.0.1-SNAPSHOT.jar -Dmapreduce.map.memory.mb=5120 -Dmapreduce.reduce.memory.mb=5120 -Dmapreduce.map.java.opts=-Xmx4096m -Dmapreduce.reduce.java.opts=-Xmx4096m -Dmapreduce.job.queuename=${queueName} -Dmapreduce.job.acl-view-job=* -D mapred.reduce.tasks=${numberOfReducers}  -D mdm.load.process.table=${mdmLoadProcessTable} -D crosswalk.table=${crosswalkTable} -D mdm.c360.crosswalk.table=${c360crosswalkTable} -D mdm.event.tracking.table=${EventtrackingTable} -D c360.recon.table=${C360ReconTable} -D load=${load} -Dmapred.max.split.size=${splitSize} -libjars ${LIBJARS} CROSSWALK ${outputLocation} ${EventtrackingLocation}

if [ $? -ne 0 ]
then
echo mdm crosswalk job failed.
exit 13
else
echo mdm crosswalk job sucess.
cd /mapr${outputLocation}
find . -name 'part*' -size 0 -delete
#ctr=0
#for fileName in part*
#do
#echo "file - ${fileName} ${filePrefix}${ctr}.${fileSuffix}"
# mv ${fileName} ${filePrefix}${ctr}.${fileSuffix}
#ctr=$((ctr + 1))
#done
rm _SUCCESS
fi
