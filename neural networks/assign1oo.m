PATTERNS = [
    1 0; 
    1 1;
];

TARGETS = [
    1;
    1;
];

X1 = Node('x1', NodeType.INPUT);
X2 = Node('x2', NodeType.INPUT);
H1 = Node('h1', NodeType.HIDDEN, ActivationFunction.SIGMOID);
H2 = Node('h2', NodeType.HIDDEN, ActivationFunction.SIGMOID);
H3 = Node('h3', NodeType.HIDDEN, ActivationFunction.SIGMOID);
O =  Node('o1', NodeType.OUTPUT, ActivationFunction.SUM);

C1 = Connection('w1', X1, H1,  0.3);
C2 = Connection('w2', X1, O,   0.2);
C3 = Connection('w3', X1, H2,  0.1);
C4 = Connection('w4', X2, H2, -0.2);
C5 = Connection('w5', X2, O,   0.2);
C6 = Connection('w6', X2, H3,  0.2);
C7 = Connection('w7', H3, O,  -0.2);
C8 = Connection('w8', H2, O,   0.3);
C9 = Connection('w9', H1, O,   0.2);

global CONNECTIONS
CONNECTIONS = [C1, C2, C3, C4, C5, C6, C7, C8, C9];

LEARN_RATE = 1.0;
MAX_EPOCHS = 100;
MIN_WEIGHT_DIFF = 0.00001;
[NUM_PATTERNS,~] = size(PATTERNS);

fprintf ('INITIAL VALUES\n--------------\n')
fprintf ('LEARN_RATE: %.4f\n', LEARN_RATE)
fprintf ('MAX_EPOCHS: %.4f', MAX_EPOCHS)
logWeights()

for epoch = 1:MAX_EPOCHS

    weightsBefore = extractWeights();
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
        
        % Now do the back-prop. Again, the Node.m class
        % will recursively push the beta back to the
        % lower layers.
        O.backProp(error, LEARN_RATE);

        % log the weights after each pattern
        logWeights()
        
    end
    
    % log the MSE after each epoch
    MSE = TSS / NUM_PATTERNS;
    fprintf ('\nMSE: %.4f', MSE)
    
    % exit if nothing has changed (presume converged)
    weightsAfter = extractWeights();
    if not(weightsChanged(weightsBefore, weightsAfter, MIN_WEIGHT_DIFF))
        fprintf ('\nBreaking from loop as weights have not changed this epoch')
        break
    end
    
end

fprintf ('\n\n')

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