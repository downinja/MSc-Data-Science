#!/bin/bash

for i in {1..100}
do
	newclusters="clusters_em.mapred.txt.$i"
	clusters="clusters_em.mapred.txt.$((i-1))"
	if [ $i == 1 ]; then
		clusters="clusters_em.txt"
	fi
	echo "iteration $i"
	echo "------------"
	
	hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-2.6.0.jar \
		-Dmapred.reduce.tasks=3 -files=em_util.py,mapper_em.py,reducer_em.py,$clusters \
		-cmdenv clusters=$clusters -mapper  'scl enable rh-python34 ./mapper_em.py' \
		-reducer  'scl enable rh-python34 ./reducer_em.py' \
		-input data.txt \
		-output clusters_em  
	
	hadoop fs -cat clusters_em/part-* | sort > $newclusters
	hadoop fs -rm -r clusters_em
	diff_val=$(diff $clusters $newclusters)
	if  [ -z "$diff_val" ]; then
		echo "Exiting loop as clusters have not changed this iteration"
		break
	fi
done

