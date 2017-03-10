#!/usr/bin/env python

import sys
from datetime import datetime

current_cluster_id = None
current_num_datapoints = 0
current_total_x = 0.
current_total_y = 0.

def log(msg):
    sys.stderr.write(str(datetime.now()) + " INFO reducer_kmeans.py: " + msg + "\n")

def print_new_cluster_params():
    if current_cluster_id:
        mean_x = current_total_x / current_num_datapoints
        mean_y = current_total_y / current_num_datapoints
        output = "%s %s %s" % (current_cluster_id, mean_x, mean_y)
        log("writing new center: " + output)
        print(output)

for line in sys.stdin:
    data_mapped = line.strip().split("\t")
    cluster_id, coords = data_mapped
    x_coord, y_coord = coords.strip().split(",")
    if cluster_id == current_cluster_id:
        current_total_x = current_total_x + float(x_coord)
        current_total_y = current_total_y + float(y_coord)
        current_num_datapoints = current_num_datapoints + 1
    else:
        print_new_cluster_params()
        log("processing new cluster: %s" % (cluster_id))
        current_cluster_id = cluster_id
        current_total_x = float(x_coord)
        current_total_y = float(y_coord)
        current_num_datapoints = 1

print_new_cluster_params()

