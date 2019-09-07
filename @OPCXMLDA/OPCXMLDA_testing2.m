classdef OPCXMLDA < handle & matlab.mixin.SetGet
    %OPCXMLDACLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Server URL to be used by function and urls struct to make a list
        %of known servers. 
        urls = struct('Reactor_10','http://128.131.133.36:8080','Reactor_20','http://128.131.133.37:8080')
        url = 'http://128.131.133.36:8080'
        %actions = {'Browse','Read','Write'}
        actions = struct('Browse',xmlread('browse.xml'),'Read',xmlread('read.xml'),'Write',xmlread('write.xml'))
        soapaction
        OPCvariables
    end
    
    methods
        %function ConstructorDesign
        opcStructure = browse(obj)
            
        function obj = OPCXMLDA(arg1)
            
        function obj = OPCXMLDA(inputArg1,inputArg2)
            %OPCXMLDACLASS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = inputArg;
        end
        end
    end
end

