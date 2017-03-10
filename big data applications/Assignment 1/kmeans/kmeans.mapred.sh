#!/bin/bash

for i in {1..10}
do
	newclusters="clusters.mapred.txt.$i"
	clusters="clusters.mapred.txt.$((i-1))"
	if [ $i == 1 ]; then
		clusters="clusters.txt"
	fi
	#cat data.txt | clusters=$clusters ./mapper_kmeans.py | sort | ./reducer_kmeans.py > $newclusters
	echo "iteration $i"
	echo "------------"
	hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-2.6.0.jar -Dmapred.reduce.tasks=3 -files=mapper_kmeans.py,reducer_kmeans.py,$clusters -cmdenv clusters=$clusters -mapper mapper_kmeans.py -reducer reducer_kmeans.py -input data.txt -output clusters 
	hadoop fs -cat clusters/part-* | sort > $newclusters
	hadoop fs -rm -r clusters
	diff_val=$(diff $clusters $newclusters)
	if  [ -z "$diff_val" ]; then
		echo "Exiting loop as clusters have not changed this iteration"
		break
	fi
done

