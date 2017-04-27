classdef Node < handle
    
    properties (SetAccess='immutable')
        id
        type
        activation
    end
    
    properties (GetAccess='public', SetAccess='private')
        sum
        output
        activationDerivative
        inboundConnections
    end
    
    methods
        
        function obj = Node(id, type, activation)
            obj.id = id;
            obj.type = type;
            obj.sum = 0;
            obj.output = 0;
            obj.activationDerivative = 0;
            obj.inboundConnections = [];
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
                    obj.activationDerivative = obj.output * (1 - obj.output);
                case ActivationFunction.TANH
                    obj.output = tanh(obj.sum);
                    obj.activationDerivative = 1 - (obj.output ^ 2);
                case ActivationFunction.SUM
                    obj.output = obj.sum;
                    obj.activationDerivative = 1;
            end
            r = obj.output;
        end
        
        function registerInboundConnection(obj, connection)
            obj.inboundConnections = [obj.inboundConnections, connection];
        end
        
        function obj = reset(obj)
            obj.sum = 0;
            obj.output = 0;
            obj.activationDerivative = 0;
        end
        
        function r = calculateOutput(obj, pattern)
            obj.reset;
            switch obj.type
               case NodeType.INPUT
                    % TODO, remove hacky coupling between obj.id and pattern index
                    obj.output = pattern(obj.id);
               case {NodeType.HIDDEN, NodeType.OUTPUT}
                    for input = obj.inboundConnections
                        out = input.from.calculateOutput(pattern);
                        obj.addInput(out * input.weight);
                    end                   
            end
            r = obj.output;
        end
        
        % This method accepts the partial derivative of the error and the
        % partial derivative of the (weighted) output from the layer above 
        % it. 
        %
        % I've notated it as if it were only for the hidden layer, however
        % the calculation holds for the output layer (if we plug in "1"
        % for dOkdSk) - although this is something of a hack, since it
        % only really works for a single output node.
        % 
        % Keeping the terms separate allows us to calculate the jacobian 
        % (the derivative of the output at K with respect to the weight 
        % from J to K) individually of the gradient (the derivative of the 
        % error at K wrt Wjk). 
        function backProp(obj, dEkdOk, dOkdSk)
            
            if not(exist('dOkdSk','var'))
                dOkdSk = 1; % output layer won't of course have a weight above
            end
            
            for connection = obj.inboundConnections
                
                dSkdOj = connection.weight; %Wjk
                dOjdSj = obj.activationDerivative; %1 if unthresholded, Oj(1-Oj) if sigmoid
                dSjdWij = connection.from.output; % Xi
                
                dOkdWij = dOkdSk * dOjdSj * dSjdWij; 
                % These are the partial derivs with respect to Wjk, hence
                % the term for Wjk is not included.
                connection.setOutputDerivative(dOkdWij); % jacobian
                connection.setErrorDerivative(dEkdOk * dOkdWij); % gradient
                % The term for Wjk is however passed down to any layer
                % below, in the second argument to this call.
                connection.from.backProp(dEkdOk, dSkdOj * dOjdSj);
            end
        end
        
    end
    
end

