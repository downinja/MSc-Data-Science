classdef Node < handle
    
    properties (SetAccess='immutable')
        id
        type
        activation
    end
    
    properties (GetAccess='public', SetAccess='private')
        sum
        output
    end
    
    methods
        
        function obj = Node(id, type, activation)
            obj.id = id;
            obj.type = type;
            obj.sum = 0;
            obj.output = 0;
            if exist('activation','var')
                obj.activation = activation;
            else
                obj.activation = ActivationFunction.NONE;
            end
        end
       
        function r = addInput(obj, amount)
            obj.sum = obj.sum + amount;
            switch obj.activation
                case ActivationFunction.SIGMOID
                    obj.output = 1 / (1 + exp(-obj.sum));
                case ActivationFunction.SUM
                    obj.output = obj.sum;
            end
            r = obj.output;
        end
        
        function obj = reset(obj)
            obj.sum = 0;
            obj.output = 0;
        end
        
        function r = calculateOutput(obj, pattern)
            
            global CONNECTIONS
            
            obj.reset();
            switch obj.type
                case NodeType.INPUT
                    % TODO, remove hacky depenedncy on e.g. X1/X2
                    if endsWith(obj.id(), '1')
                        obj.output = pattern(1);
                    else
                        obj.output = pattern(2);
                    end
               case {NodeType.HIDDEN, NodeType.OUTPUT}
                    for i = 1:length(CONNECTIONS)
                        if (CONNECTIONS(i).to() == obj)
                            input = CONNECTIONS(i);
                            out = input.from().calculateOutput(pattern);
                            obj.addInput(out * input.weight());
                        end
                    end                   
            end
            r = obj.output;
        end
        
        function backProp(obj, error, learnRate, from)
            
            global CONNECTIONS
            
            if exist('from','var')
                fprintf ('\nbackProp from %s to %s over connection %s (error=%.4f)', ...
                    from.to.id, obj.id, from.id(), error)
            else
                fprintf ('\nbackProp to %s (error=%.4f)', obj.id, error)
            end
            
            fromWeight = 0;
            if obj.type == NodeType.OUTPUT
                % just to make the code easier below. 
                fromWeight = 1; 
            else
                fromWeight = from.weight;
            end
            
            % Calculate the outbound and inbound changes, based 
            % on the total error from above. 
            delta = error * obj.output; % outbound weight change
            beta = 0; % amount of error to push down
            switch obj.activation
                case ActivationFunction.SIGMOID
                    beta = learnRate * obj.output * (1-obj.output) * error * fromWeight;
                case ActivationFunction.SUM
                    beta = learnRate * error * fromWeight;
            end
            
            Node.logDeltaAndBeta(obj, delta, beta);
            
            % Now for any connections to us, push down our contribution 
            % to the error from above (our beta value)
            for i = 1:length(CONNECTIONS)
                connection = CONNECTIONS(i);
                if connection.to == obj
                    connection.from.backProp(beta,learnRate,connection);
                end
            end
            
            % Finally, adjust the weight on the connection which is
            % passing us the error from above.
            if obj.type ~= NodeType.OUTPUT
                from.increment(delta);
            end
            
        end
        
    end
    
    methods(Static, Access=private)
        
        function logDeltaAndBeta(obj, delta, beta)
            if obj.type == NodeType.OUTPUT
                fprintf ('\n%s beta=%.4f, no delta as OUTPUT layer', obj.id, beta)
            elseif obj.type == NodeType.INPUT
                fprintf ('\n%s delta=%.4f, no beta as INPUT layer', obj.id, delta)
            else
                fprintf ('\n%s delta=%.4f beta=%.4f ', obj.id, delta, beta) 
            end
        end
        
    end
   
    
end

