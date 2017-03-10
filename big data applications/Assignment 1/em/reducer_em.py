#!/usr/bin/env python

'''
This is the reducer part of a MapReduce job for calculating new cluster parameters using
the Expectation Maximisation (EM) algorithm. The logic for the calculations is based on
this page:

    https://www.coursera.org/learn/ml-clustering-and-retrieval/supplement/s9OBQ/optional-a-worked-out-example-for-em 

Parts of this script also started life in

    https://learn.gold.ac.uk/pluginfile.php/731370/mod_assign/introattachment/0/reducer_kmeans.py

@author: jdown003@gold.ac.uk
'''

import sys
sys.path.append('./') # so that the supporting em_util.py file can be found when running inside MapReduce job
import em_util as emu
import os

# current_cluster_id is just used to track boundaries in the data e.g. if we've been given multliple clusters 
# to reduce, and have reached the start of a new one
current_cluster_id = None
# For this implementation, we need to store all datapoints for a cluster and process them together once
# they've all been read in - because of the covariance matrix. For the cluster center and weight, 
# we could keep a running total of the relevant variables and discard each datapoint after updating these, .  
# however the covariance matrix needs to know the new cluster centre in advance(?) This probably won't scale
# well; a combiner may help, but ultimately EM may not be an efficient use of MapReduce. 
current_datapoints = [] 

CLUSTERS_FILENAME = os.environ["clusters"]
#CLUSTERS_FILENAME = "clusters_em.txt"
emu.log("Processing file %s\n" % (CLUSTERS_FILENAME))

# We only really need this to know how many clusters there are. Could hardcode it to
# 3 and do without it, but is easier to generalise to new data this way.
clusters = emu.read_clusters(CLUSTERS_FILENAME) 

def print_new_cluster_params():
    # check that we have some datapoints to process
    if len(current_datapoints) > 0: 
        # initialise variables used in calculating new cluster centers and weights
        total_x, total_y, total_likelihood = 0.,0.,0.
        # loop over each datapoint assigned to the current cluster and sum the x & y coordinates and the likelihoods 
        for datapoint in current_datapoints:
            x_coord, y_coord, likelihood = datapoint[0], datapoint[1], datapoint[2]
            total_x = total_x + x_coord * likelihood
            total_y = total_y + y_coord * likelihood
            total_likelihood = total_likelihood + likelihood
        # calculate the new cluster center (mean of total x & y coordinates)
        mean_x = total_x / total_likelihood
        mean_y = total_y / total_likelihood
        # calculate the new cluster weight (total likelihood normalised by number of clusters)
        weight = total_likelihood / len(clusters)
        # now we have the new cluster center, we can derive the covariance matrix - via the
        # weighted average distance of the datapoints from it 
        covar_x,covar_y,covar_xy = 0.,0.,0.
        for datapoint in current_datapoints:
            x_coord, y_coord, likelihood = datapoint[0], datapoint[1], datapoint[2]
            # doing this without matrix algebra, for simplicity/efficiency
            dist_x = x_coord - mean_x
            dist_y = y_coord - mean_y
            # weighted outer product for this datapoint
            covar_x = covar_x + likelihood * pow(dist_x, 2)
            covar_y = covar_y + likelihood * pow(dist_y, 2)
            covar_xy = covar_xy + likelihood * dist_x * dist_y
        # average outer product over all datapoints
        covar_x = covar_x / total_likelihood    
        covar_y = covar_y / total_likelihood
        covar_xy = covar_xy / total_likelihood
        # and output the results
        covar = "%s,%s;%s,%s" % (covar_x, covar_xy, covar_xy, covar_y)
        output = "%s %s %s %s %s" % (current_cluster_id, mean_x, mean_y, covar, weight)
        emu.log("writing new center: " + output)
        print(output)

for line in sys.stdin:
#datapoints = emu.read_data("mapper_output_coursera2.txt")
#for line in datapoints.strip().split("\n"):
    cluster_id, datapoint = line.strip().split("\t")
    x_coord, y_coord, likelihood = datapoint.strip().split(",")
    if cluster_id == current_cluster_id: # check whether we've reached a boundary in the data
        current_datapoints.append((float(x_coord), float(y_coord), float(likelihood)))
    else:
        # we've found a new cluster, so close-off the current one..
        print_new_cluster_params()
        # .. and reset our state for the new one
        emu.log("processing new cluster: %s" % (cluster_id))
        current_cluster_id = cluster_id
        current_datapoints = []
        current_datapoints.append((float(x_coord), float(y_coord), float(likelihood)))

# close-off the current cluster
print_new_cluster_params()

