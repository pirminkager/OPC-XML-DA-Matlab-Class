%Handle class is the way to go
classdef HandleClass_2 < handle & matlab.mixin.SetGet
    properties
        Value
        Output = [];
    end
    methods
        function set.Output(obj,value)
            if (value > 10)
                obj.Output = value;
            else
                error('ERROR')
            end
        end
        function roundOff(obj)
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
