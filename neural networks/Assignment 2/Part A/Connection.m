classdef Connection < handle
    
    properties (SetAccess='immutable')
        id              % our id e.g. 'w1'
        from            % the node we're connecting from e.g. 'X1' or 'H2'
        to              % the node we're connecting to e.g. 'X2' or 'O1'
    end
    
    properties (GetAccess='public', SetAccess='private')
        weight          % our current weight
        errorDerivative % error at output layer wrt this weight  
        outputDerivative % network output wrt this weight
    end
    
    methods
        
        % constructor
        function obj = Connection(id, from, to)
            obj.id = id;
            obj.from = from;
            obj.to = to;
            to.registerInboundConnection(obj);
        end
        
        % update weight by specified delta
        function increment(obj, delta)
            %if (delta > 0.00000000001)
                %fprintf ('\n%s.increment(%.4f)', obj.id, delta)
            %end
            obj.weight = obj.weight + delta;
        end
        
        function reset(obj, weight) 
            obj.weight = weight;
        end
        
        % set error derivative (network error partial wrt weight)
        function setErrorDerivative(obj, errorDerivative)
            %fprintf ('\n%s.setErrorDerivative(%.4f)', obj.id, errorDerivative)
            obj.errorDerivative = errorDerivative;
        end
        
        % set output derivative (network output partial wrt weight e.g. Jacobian)
        function setOutputDerivative(obj, outputDerivative)
            %fprintf ('\n%s.setOutputDerivative(%.4f)', obj.id, outputDerivative)
            obj.outputDerivative = outputDerivative;
        end
        
    end
    
end

