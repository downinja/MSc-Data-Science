# Neural Networks
There were two assignments in the Neural Networks module:

### Assignment 1
Design and implement a multi-layer perceptron in Matlab, using a combination of input-to-hidden layer connections and direct input-to-output node connections. Train this network on a simple binary classification task and demostrate that it converges on a correct solution.

### Assignment 2
Implement a multi-layer perceptron in Matlab with 10 input and 5 hidden layer nodes. Derive and implement the logic needed to calculate the second-order derivatives of the network output (Jacobian) and error (gradient) functions during the back-propogation phase. Use these to calculate the 'fast approximation' to the Hessian using the [Levenberg-Marquardt algorith](http://crsouza.com/2009/11/18/neural-network-learning-by-the-levenberg-marquardt-algorithm-with-bayesian-regularization-part-1/), and apply Newton's Step to determine the weight deltas for training. Train the network on a time-series dataset (yearly sunspots 1700-1987) using a moving window of 200 inputs, and use one-step-ahead prediction to estimate test error. Compare this with the same network trained using regular gradient descent (first-order derivatives only). 

![A scribble of requirements](https://github.com/downinja/MSc-Data-Science/tree/master/neural%20networks/scribble.jpg?raw=true)
![A graph plotting training error for fast hessian vs classic gradient descent trainig of the network in assignment 2](https://github.com/downinja/MSc-Data-Science/tree/master/neural%20networks/assign2b_01.png?raw=true)

