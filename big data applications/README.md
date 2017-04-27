# Big Data Applications
There were two coursework assignments for the Big Data Applications module:

### Assignment 1
Use Hadoop to implement KMeans and Expectation Maximisation (EM), compare the results of both, and discuss the suitability (or not) of Hadoop for implementing iterative ML algorithms.

### Assignment 2
Use Spark to investigate a dataset on a self chosen topic. I already had TFL's [Santander Cycle Hire Usage Data](http://cycling.data.tfl.gov.uk/) from my [third Data Visualisation assignment](https://github.com/downinja/MSc-Data-Science/tree/master/data%20visualisation), and so decided to try a new approach to analysing this. Specifically, I chose to use GraphX to model the journey data as a directed graph, and apply [Page Rank](https://en.wikipedia.org/wiki/PageRank) to see if this could reveal any new insights.  

Ultimately, I found that Page Rank was a useful way of looking at the journey data - albeit from a bike's perspective (as a Markov Chain), rather than the rider's. 

![A plot of Personalised Page Rank for the Hoxton Station docking station](https://github.com/downinja/MSc-Data-Science/blob/master/big%20data%20applications/Assignment%202/ppr_hoxton.jpg?raw=true)
![A plot of Personalised Page Rank for the Cubitt Town docking station](https://github.com/downinja/MSc-Data-Science/blob/master/big%20data%20applications/Assignment%202/ppr_cubitt.png?raw=true)
