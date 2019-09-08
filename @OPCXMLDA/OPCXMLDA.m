classdef OPCXMLDA < handle & matlab.System %& matlab.mixin.SetGet%
    %OPCXMLDACLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        url = 'http://128.131.133.45:8080'
    end
    
    properties (SetAccess = private) % Read Only
        operation
        operationID
        opctags
        opctypes
        urls = struct('Reactor_10','http://128.131.133.36:8080','Reactor_20','http://128.131.133.37:8080','Reactor_2','http://128.131.133.45:8080')
        soapaction % is dynamically assigned by initialization
    end
    
    properties (Access = private)
        options = weboptions()   
        operations = ["Browse" "Read" "Write"]
        soapxml = struct('Browse','browse.xml','Read','read.xml','Write','write.xml')
    end

    methods
        function obj = OPCXMLDA(obj) %Object initialization.
            obj.operationID = obj.initOperationID()
            for i = 1:length(obj.operations)
                obj.operation.(obj.operations(i)) = obj.operations(i)
                obj.soapaction.(obj.operations(i)) = xmlread(obj.soapxml.(obj.operations(i)))
            end
        end
        
        % Set Action maybe not needed in the end if i make seperate
        % functions for all operations
        %         function set.operation(obj,operation)
        %             if operationisValid(operation)
        %                 obj.operation = operation
        %                 %maybe i should make these changes individualy on requests
        %                 obj.actionid = find(contains(obj.operations,operation))
        %                 obj.actionxml = obj.soapaction(obj.actionid)
        %                 obj.options = weboptions()
        %                 obj.options.ContentType='xml'
        %                 obj.headers = {'SOAPAction' strcat('http://opcfoundation.org/webservices/XMLDA/1.0/',obj.operation)}
        %                 obj.options.HeaderFields=obj.headers
        %             else
        %                 error('Invalid Action')
        %             end
        %         end
        
        % Main Function definitions
        % here i make the functions for browse read and write requests
        
        function [value, type] = read(obj,ItemNameArg)
            %r = itemName
            if (nargin == 1)
                itemName = [""];
            elseif (nargin == 2)
                itemName = ItemNameArg;
                fields = textscan(ItemNameArg,'%s','Delimiter','.');
            else
                error('Too many or too few arguments')
            end
            operation = obj.operation.Read;
            soapaction = obj.getsoapAction(operation);%,["ItemName",itemName]);
            soapaction = obj.soapactionchangeParameters(soapaction,"Items",["ItemName",itemName]);
            
            options = obj.getWeboptions(operation);
            response = webwrite(obj.url,soapaction,options);
            value = response.getElementsByTagName('Value').item(0).getTextContent;
            type = response.getElementsByTagName('Value').item(0).getAttribute('xsi:type');
            % test if value type is already known, else save it to struct
            % opctypes
            try
                getfield(obj.opctypes,fields{1}{:})
            catch
                obj.opctypes=makestructentry(obj,obj.opctypes,itemName,type)
            end
        end
        
        function r = write(obj,itemName,value)
            % In order to make the write function we need to know what
            % types are accepted by the device. Lets use the structure
            % created from browse to get a similar structure but with the
            % accepted types for every element.
            
            r = [itemName,value]
        end

        function r = browse(obj,ItemNameArg)
            if (nargin == 1)
                itemName = [""];
            elseif (nargin == 2)
                itemName = ItemNameArg;
                fields = textscan(ItemNameArg,'%s','Delimiter','.');
                fields = matlab.lang.makeValidName(fields{1});
            else
                error('Too many or too few arguments')
            end
            operation = obj.operation.Browse;
            soapaction = obj.getsoapAction(operation);%,["ItemName",itemName]);
            soapaction = obj.soapactionchangeParameters(soapaction,"Browse",["ItemName",itemName]);
            options = obj.getWeboptions(operation);
            response = webwrite(obj.url,soapaction,options);
            %elements = response.getElementsByTagName('n2:BrowseResponse').item(0).getElementsByTagName("Elements");
            elements = response.getElementsByTagName("Elements");
            for i = 1:elements.getLength
                if (elements.item(i-1).getAttributes.getNamedItem("IsItem").getValue) == 'true'
                    name = char(elements.item(i-1).getAttributes.getNamedItem("Name").getValue)
                    value = string(elements.item(i-1).getAttributes.getNamedItem("ItemName").getValue);
                    if itemName == ""
                        obj.opctags.(name) = value;
                    else
                        fieldnames = fields;
                        fieldnames{end+1,:} = matlab.lang.makeValidName(name)
                        obj.opctags = setfield(obj.opctags,fieldnames{:},value);
                    end
                elseif (elements.item(i-1).getAttributes.getNamedItem("HasChildren").getValue) == 'true'
                    value = string(elements.item(i-1).getAttributes.getNamedItem("ItemName").getValue);
                    obj.browse(value)
                end
            end
            r = obj.opctags;
        end
        
        % Followed by subroutines used by all requests
        %r = makestructentry(obj,struct,ItemNameArg,name,value)
        function r = makestructentry(obj,struct,ItemNameArg,name,value)
            fields = textscan(ItemNameArg,'%s','Delimiter','.');
            fields = matlab.lang.makeValidName(fields{1});
            fieldname = fields;
            if (nargin == 4)
                value = name;
            elseif (nargin == 5)
                fieldname{end+1,:} = matlab.lang.makeValidName(name);
            else
                error('Wrong number of arguments')
            end
            struct = setfield(struct,fieldname{:},value);
            r = struct;
        end
        function r = getWeboptions(obj,operation) %Create options for web
            if (obj.operationisValid(operation))
                options = weboptions()
                options.ContentType = 'xml'
                headers = {'SOAPAction' strcat('http://opcfoundation.org/webservices/XMLDA/1.0/',char(operation))}
                options.HeaderFields = headers
                r = options
            else
                error('operation is not valid')
            end
        end

        function r = request(obj,soapmessage,operation)
            options = getWeboptions(operation)
            r = webwrite(obj.url,soapmessage,options)
        end
            
        function r = getsoapAction(obj,operation,arg)
            if nargin <= 2
                par = []
            else
                par = arg
            end
            dom = obj.soapaction.(obj.operation.(operation))
            
            if (isempty(par))
                r = dom
            elseif (mod(length(par),2))
                error('wrong dimensions ["item1","val1","item2,"val2",...]')
            else
                r = obj.soapactionchangeParameters(dom,operation,par)
            end
        end
        
        function r = soapactionreadParameters(obj,dom,par)
            % This function is not yet used. but "soapenv:Body" will make
            % problems with generic opcxml devices
            % Maybe make a funtion which returns the xml so the programmer
            % can search for the tagname in question in the xml?
            tagName = dom.getElementsByTagName("soapenv:Body").item(0).getChildNodes.item(1).getTagName
            %tagName = strcat('ns:',operation)
            if isempty(par)
                error('par not given')
            else
                for i = 1:length(par)
                    struct.(par(i)) = dom.getElementsByTagName(tagName).item(0).getAttribute(par(i))
                end
                r = struct
            end
        end
        
        function r = soapactionchangeParameters(obj,dom,tagName,par)
            % Operation should be extracted from given soap dom!!!
            %tagName = dom.getElementsByTagName("soapenv:Body").item(0).getChildNodes.item(1).getTagName
            %tagName = operation
            if (mod(length(par),2))
                error('wrong dimensions ["item1","val1","item2,"val2",...]')
            else
                if isa(par,'string')
                    for i = 1:2:length(par)
                        dom.getElementsByTagName(tagName).item(0).setAttribute(par(i),par(i+1))
                    end
                    r = dom
                else
                    error('par has to be a string array ["item1","val1","item2,"val2",...]')
                end
            end
        end
        
        function r = initOperationID(obj)
            for i = 1:length(obj.operations)
                struct.(obj.operations(i)) = i
            end
            r = struct
        end
        
        
        
        
    end
%     methods(Static = true)
%         out = dom2struct(dom)
%         
%         
%     end
    methods(Access = protected)
%         function r = getoperationID(obj,operation) %NOT USED now there is a operationID struct created on object initialisation
%             if (operationisValid(operation))
%                 r = obj.operationID.(operation)
%             else
%                 error('operation is not valid')
%             end
%         end
        

        
    end
    
    methods % Testing Methods
        function r = returnactionid(obj)
            r = obj.operationID;
        end
        function r = operationisValid(obj,operation)
            r = ismember(operation,obj.operations)
        end
    end
    
end

