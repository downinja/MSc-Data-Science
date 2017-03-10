#!/usr/bin/env python

import os
import sys
import math
from datetime import datetime

def log(msg):
    sys.stderr.write(str(datetime.now()) + " INFO mapper_kmeans.py: " + msg + "\n")

CLUSTERS_FILENAME = os.environ["clusters"]
log("Processing file %s\n" % (CLUSTERS_FILENAME))
clusters = []

def read_data(clusters_file):
    f = open(clusters_file, 'r')
    data = f.read()
    f.close()
    del f
    return data

def read_clusters():
    cluster_data = read_data(CLUSTERS_FILENAME)
    for line in cluster_data.strip().split("\n"):
        centroid_id, x_coord, y_coord = line.split(" ")
        clusters.append((centroid_id, float(x_coord), float(y_coord)))

def get_distance_coords(x, y, cx, cy):
    #Calculate euclidian distance between two coordinates and return the distance
    dist = math.sqrt(pow(cx-x,2) + pow(cy-y,2))
    return dist

def get_nearest_cluster(x, y):
    #determine the nearest cluster from the global clusters variable and return the id
    nearest_cluster_id = None
    current_min_distance = None
    for (centroid_id, cx, cy) in clusters:
        dist = get_distance_coords(x, y, cx, cy)
        if (nearest_cluster_id == None) or (dist < current_min_distance):
            nearest_cluster_id = centroid_id
            current_min_distance = dist
    return nearest_cluster_id

read_clusters()

numLinesLogged = 0
for line in sys.stdin:
#datapoints = read_data("data.txt")
#for line in datapoints.strip().split("\n"):
    coords = line.strip().split(" ")
    x,y = coords
    nearest_cluster_id = get_nearest_cluster(float(x), float(y))
    output = "%s\t%s" % (str(nearest_cluster_id),str(x) + "," + str(y))
    if numLinesLogged < 10:
        if numLinesLogged == 0:
            log("Logging first 10 outputs")
        log(output)
        numLinesLogged = numLinesLogged + 1
    print(output)
