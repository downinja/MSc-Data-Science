'''
Script to plot the results of the MapReduce KMeans task. Not itself part of the MapReduce job.

Large parts of this script started life in

    https://learn.gold.ac.uk/pluginfile.php/731370/mod_assign/introattachment/0/reducer_kmeans.py
    
    and
    
    https://gist.github.com/kfarrahi/1221c2623caf0803255b6ebf004e5191
    

@author: jdown003@gold.ac.uk
'''

import matplotlib.pyplot as plt
import math

c1 = [0, 0.200302217487, 0.186358139854]
c2 = [1, 0.842339504006, 0.690283942841]
c3 = [2, 0.612260390886, 0.653529296302]
clusters = [c1, c2, c3]

def read_data(datafile):
    f = open(datafile, 'r')
    data = f.read()
    f.close()
    del f
    return data

def get_distance_coords(x, y, cx, cy):
    dist = math.sqrt(pow(cx-x,2) + pow(cy-y,2))
    return dist

def get_nearest_cluster(x, y):
    nearest_cluster_id = None
    current_min_distance = None
    for (centroid_id, cx, cy) in clusters:
        dist = get_distance_coords(x, y, cx, cy)
        if (nearest_cluster_id == None) or (dist < current_min_distance):
            nearest_cluster_id = centroid_id
            current_min_distance = dist
    return nearest_cluster_id

datapoints = read_data("../data.txt")

colors = ['#4EACC5', '#FF9C34', '#4E9A06']

plt.style.use('ggplot')
fig = plt.figure(0)
ax = fig.add_subplot(111, aspect='equal')
for cluster in clusters:
    ax.plot(cluster[1], cluster[2], 'o', markeredgecolor='k', markersize = 12, color = colors[cluster[0]])

for line in datapoints.strip().split("\n"):
    x,y = line.strip().split(" ")
    ax.plot(float(x),float(y), 'r', marker='.', markersize=8, color = colors[get_nearest_cluster(float(x), float(y))])

plt.show()