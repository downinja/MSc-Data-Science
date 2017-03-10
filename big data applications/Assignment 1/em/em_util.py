'''
Utility functions shared between mapper_em and reducer_em. Largely borrowed from: 

    https://learn.gold.ac.uk/pluginfile.php/731370/mod_assign/introattachment/0/mapper_kmeans.py

@author: jdown003@gold.ac.uk
'''

import numpy as np
import sys
from datetime import datetime

def log(msg):
    sys.stderr.write(str(datetime.now()) + " INFO reducer_em.py: " + msg + "\n")

def read_data(datafile):
    f = open(datafile, 'r')
    data = f.read()
    f.close()
    del f
    return data

def read_clusters(clusters_filename):
    clusters = []
    cluster_data = read_data(clusters_filename)
    for line in cluster_data.strip().split("\n"):
        centroid_id, x_coord, y_coord, covar, weight = line.split(" ")
        clusters.append((centroid_id, float(x_coord), float(y_coord), np.matrix(covar), float(weight)))
    return clusters

