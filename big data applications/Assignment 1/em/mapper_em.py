#!/usr/bin/env python

'''
This is the mapper part of a MapReduce job for calculating new cluster parameters using
the Expectation Maximisation (EM) algorithm. The logic for the calculations is based on
this page:

    https://www.coursera.org/learn/ml-clustering-and-retrieval/supplement/s9OBQ/optional-a-worked-out-example-for-em 

Parts of this script also started life in

    https://learn.gold.ac.uk/pluginfile.php/731370/mod_assign/introattachment/0/mapper_kmeans.py

@author: jdown003@gold.ac.uk
'''

import sys
sys.path.append('./') # so that the supporting em_util.py file can be found when running inside MapReduce job
import em_util as emu
import os
from scipy.stats import multivariate_normal

numLinesLogged = 0

CLUSTERS_FILENAME = os.environ["clusters"]
#CLUSTERS_FILENAME = "clusters_em.txt"
emu.log("Processing file %s\n" % (CLUSTERS_FILENAME))
clusters = emu.read_clusters(CLUSTERS_FILENAME)

def output_cluster_responsibilities(x, y):
    global numLinesLogged 
    pdfs = []
    sum_pdfs = 0.
    for (centroid_id, cx, cy, covar, weight) in clusters:
        # for each cluster, store its ID and the likelihood that this datapoint belongs to it
        pdf = multivariate_normal.pdf([x,y], [cx, cy], covar) * weight
        pdfs.append((centroid_id, pdf))
        sum_pdfs = sum_pdfs + pdf # keep a running total, as we'll need this below
    
    # can't wrap this into the loop above, as we need to know the sum of the pdfs first
    for i in range(len(pdfs)):
        # for each cluster output the likelihood that this datapoint belongs to it
        centroid_id = pdfs[i][0]  
        pdf = pdfs[i][1]
        likelihood = pdf / sum_pdfs # so likelihoods sum to 1
        # generate our key/value pair for output
        output = "%s\t%s" % (str(centroid_id), str(x) + "," + str(y) + "," + str(likelihood))
        # log the first 10 of these to stderr for use in debugging
        if numLinesLogged < 10:
            if numLinesLogged == 0:
                emu.log("Logging first 10 outputs")
            emu.log(output)
            numLinesLogged = numLinesLogged + 1
        # now write to stdout for Hadoop to pick up
        print(output)

for line in sys.stdin:
#datapoints = emu.read_data("../data.txt")
#for line in datapoints.strip().split("\n"):
    coords = line.strip().split(" ")
    x,y = coords
    output_cluster_responsibilities(x, y)
