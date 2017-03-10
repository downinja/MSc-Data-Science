'''
Script to plot the results of the MapReduce EM task. Not itself part of the MapReduce job.

@author: jdown003@gold.ac.uk
'''

import em_util as emu;
import math
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Ellipse
from scipy.stats import multivariate_normal

clusters = emu.read_clusters("clusters_em_final.txt")

plt.style.use("ggplot")
fig = plt.figure(figsize=(10,10))
ax = fig.add_subplot(111, aspect='equal')

colours = ['#4EACC5', '#FF9C34', '#4E9A06']

for (centroid_id, cx, cy, covar, weight) in clusters:
    ellipse = Ellipse(
        xy = np.array([cx, cy]), 
        width = weight * covar[0,0] * 2, 
        height = weight * covar[1,1] * 2, 
        angle = math.acos(covar[0,1])*(180/math.pi),
        alpha = 0.7,
        fc = colours[int(centroid_id)]                    
    )
    ax.add_artist(ellipse)

datapoints = emu.read_data("../data.txt")
for line in datapoints.strip().split("\n"):
    x,y = line.strip().split(" ")
    pdfMax = 0.
    colour = colours[0]
    for (centroid_id, cx, cy, covar, weight) in clusters:
        pdf = multivariate_normal.pdf([x,y], [cx, cy], covar) * weight
        if pdf > pdfMax:
            pdfMax = pdf
            colour = colours[int(centroid_id)]
    
    ax.plot(
        float(x),
        float(y),
        colour, 
        marker = '.', 
        markersize = 8,
        markeredgecolor = 'k'
    )
plt.show()
