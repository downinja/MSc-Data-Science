classdef Connection < handle
    
    properties (SetAccess='immutable')
        id              % our id e.g. 'w1'
        from            % the node we're connecting from e.g. 'X1' or 'H2'
        to              % the node we're connecting to e.g. 'X2' or 'O1'
    end
    
    properties (GetAccess='public', SetAccess='private')
        weight          % our current weight
    end
    
    methods
        
        % constructor
        function obj = Connection(id, from, to, weight)
            obj.id = id;
            obj.from = from;
            obj.to = to;
            obj.weight = weight;
        end
        
        % update weight by specified delta
        function increment(obj, delta)
            if (delta > 0.00000000001)
                fprintf ('\n%s.increment(%.4f)', obj.id, delta)
            end
            obj.weight = obj.weight + delta;
        end
        
    end
    
end

