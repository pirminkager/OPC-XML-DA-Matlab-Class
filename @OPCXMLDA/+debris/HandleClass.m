%Handle class is the way to go
classdef HandleClass < handle
    properties
        Value
        Output = [];
    end
    methods
        function obj = set.Output(obj,value)
            if (value > 0)
                obj.Output = value;
            else
                error('ERROR')
            end
        end
        function obj = roundOff(obj)
            obj.Output = round([obj.Value],2)
        end
        function r = multiplyBy(obj,n)
            r = [obj.Value] * n;
        end
        function y = getOutput(obj)
            y = obj.Output;
        end 
    end
end
