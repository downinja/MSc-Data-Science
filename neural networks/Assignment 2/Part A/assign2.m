global PATTERNS
PATTERNS = [
    1 0; 
    1 1;
];

global TARGETS
TARGETS = [
    1;
    1;
];

X1 = Node(1, NodeType.INPUT);
X2 = Node(2, NodeType.INPUT);
H1 = Node('h1', NodeType.HIDDEN, ActivationFunction.TANH);
H2 = Node('h2', NodeType.HIDDEN, ActivationFunction.TANH);
H3 = Node('h3', NodeType.HIDDEN, ActivationFunction.TANH);
global O; O =  Node('o1', NodeType.OUTPUT, ActivationFunction.SUM);

C1 = Connection('w1', X1, H1);
C2 = Connection('w2', X1, O);
C3 = Connection('w3', X1, H3);
C4 = Connection('w4', X2, H2);
C5 = Connection('w5', X2, H3);
C6 = Connection('w6', H1, O);
C7 = Connection('w7', H2, O);
C8 = Connection('w8', H3, O);

global CONNECTIONS; CONNECTIONS = [C1, C2, C3, C4, C5, C6, C7, C8];
global LEARN_RATE; LEARN_RATE = 1.0;
global MAX_EPOCHS; MAX_EPOCHS = 1000;
global MIN_WEIGHT_DIFF; MIN_WEIGHT_DIFF = 0.00001;
global NUM_PATTERNS; [NUM_PATTERNS,~] = size(PATTERNS);

initialWeights = [-0.25, 0.33, 0.14, -0.17, 0.16, 0.43, 0.21, -0.25];
setWeights(initialWeights);
mses1 = train('CLASSIC');
setWeights(initialWeights);
mses2 = train('FAST_HESSIAN');

figure
plot(1:length(mses1), mses1, 1:length(mses2), mses2)
title('CLASSIC vs FAST HESSIAN TRAINING OF SIMPLE NETWORK')
xlabel('EPOCH (xlim[1,10])')
ylabel('MSE (ylim[0,0.1])')
xlim([1,10])
ylim([0,0.1])
legend('CLASSIC (converges in 218 epochs)', 'FAST HESSIAN (converges in 9 epochs)')

function mses = train(MODE) 

    global CONNECTIONS
    global LEARN_RATE; 
    global MAX_EPOCHS; 
    global MIN_WEIGHT_DIFF;
    global NUM_PATTERNS; 
    global O;
    global PATTERNS; 
    global TARGETS; 

    fprintf ('INITIAL VALUES\n--------------\n')
    fprintf ('MODE: %s\n', MODE)
    fprintf ('LEARN_RATE: %.4f\n', LEARN_RATE)
    fprintf ('MAX_EPOCHS: %.4f', MAX_EPOCHS)
    logWeights()
    mses = zeros(218, 1);

    for epoch = 1:MAX_EPOCHS

        weightsBefore = extractWeights();
        approxHessian = zeros(length(CONNECTIONS));
        gradient = zeros(length(CONNECTIONS),1);
        TSS = 0;
        for p = 1:NUM_PATTERNS

            fprintf ('\n-------------------\nepoch %1d pattern %1d\n-------------------', epoch, p)

            pattern = PATTERNS(p, :);
            target = TARGETS(p,:);

            % Do the forward pass (starting with the output node -
            % which will recursively call back to the lower layers)
            out = O.calculateOutput(pattern);
            fprintf ('\noutput: %.4f', out)

            % Update TSS
            error = target - out; 
            TSS = TSS + (error^2);

            % Now do the recursive back-prop. Note that this does not update
            % the weights, it just calculates the derivatives (error wrt
            % weights, and output wrt weights e.g. gradient and jacobian).
            % Per Bishop, this is what the backprop ultimately should do;
            % the bit about updating the weights is an additional step.
            O.backProp(error);

            % Ok, now we should have the derivatives we need for our 
            % weight update calculations. Because I've implemented this as 
            % a recursive OO design rather than using matrix algebra, we 
            % first need to "vectorise" the partial derivatives so that we 
            % can do the matrix algebra involved in calculating the 
            % approximate Hessian.
            jacobian = zeros(length(CONNECTIONS),1);
            for i = 1:length(CONNECTIONS)
                % Loop through the network connections 
                connection = CONNECTIONS(i);
                if strcmp(MODE, 'CLASSIC') == 1
                    % fall-back to simple gradient descent and do the
                    % weight update right here
                    connection.increment(connection.errorDerivative); 
                else
                    % pull out the partial derivatives into our jacobian and 
                    % gradient vectors, for later batch update.
                    jacobian(i) = jacobian(i) + connection.outputDerivative;
                    gradient(i) = gradient(i) + connection.errorDerivative;
                end
            end
            if strcmp(MODE,'FAST_HESSIAN') == 1
                % Now we can build up our approximate Hessian matrix as
                % we go along.
                approxHessian = approxHessian + (jacobian * jacobian');
                fprintf ('\njacobian now: %s', mat2str(jacobian))
                fprintf ('\ngradient now: %s', mat2str(gradient))
                fprintf ('\napproxHessian now: %s', mat2str(approxHessian))
            end

        end

        % log the MSE after each epoch
        MSE = TSS / NUM_PATTERNS;
        mses(epoch) = MSE;
        fprintf ('\nMSE: %.4f', MSE)

        if strcmp(MODE,'FAST_HESSIAN') == 1
            fprintf ('\ndoing Newtons step')
            % Average out our gradient and matrix calculations
            gradient = gradient ./ NUM_PATTERNS;
            approxHessian = approxHessian ./ NUM_PATTERNS;
            fprintf ('\ngradient: %s', mat2str(gradient))
            fprintf ('\napproxHessian: %s', mat2str(approxHessian))
            % Regularise the approximate Hessian so that we can definitiely
            % invert it.
            regularisedHessian = approxHessian + (eye(length(CONNECTIONS)) * 0.001);
            fprintf ('\nregularisedHessian: %s', mat2str(regularisedHessian))
            % And now use Netwon's step (inv(Hessian)*gradient) to get our
            % weight update vector.
            newtons = regularisedHessian\gradient;
            fprintf ('\nnewtons: %s', mat2str(newtons))
            % Again, since the network uses an object model rather than vectors,
            % we need to loop back around the weights and increment them 
            % individually. Is not efficient, but the OO model is (to me at least)
            % easier to follow than matrix algebra.
            for i = 1:length(CONNECTIONS)
                connection = CONNECTIONS(i);
                connection.increment(newtons(i));
            end
        end

        
        % log the weights after this epoch
        logWeights()

        % exit if nothing has changed (presume converged)
        weightsAfter = extractWeights();
        if not(weightsChanged(weightsBefore, weightsAfter, MIN_WEIGHT_DIFF))
            fprintf ('\nBreaking from loop as weights have not changed this epoch')
            break
        end

    end

    fprintf ('\n\n')
end

function logWeights()
    global CONNECTIONS
    fprintf ('\nconnections: ')
    for i=1:length(CONNECTIONS)
        fprintf('%s=%.4f ', CONNECTIONS(i).id, CONNECTIONS(i).weight)
    end
end

function weights = extractWeights()
    global CONNECTIONS
    weights=zeros(length(CONNECTIONS));
    for i=1:length(CONNECTIONS)
        weights(i) = CONNECTIONS(i).weight;
    end
end

function changed = weightsChanged(before, after, minDiff)
    changed = false;
    diff = before - after;
    for i=1:length(diff)
        if abs(diff(i)) > minDiff
            changed = true;
            break;
        end
    end
end

function setWeights(weights) 
    global CONNECTIONS
    numConnections = size(CONNECTIONS, 2);
    for i = 1:numConnections
        CONNECTIONS(i).reset(weights(i));
    end
end