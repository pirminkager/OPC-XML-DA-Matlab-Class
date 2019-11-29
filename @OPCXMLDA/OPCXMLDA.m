classdef OPCXMLDA < handle & matlab.System %& matlab.mixin.SetGet%
    %OPCXMLDACLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        url = 'http://128.131.133.36:8080'
    end
    
    properties (SetAccess = private) % Read Only
        operation
        operationID
        opctags
        opctypes
        urls = struct('Reactor_20','http://128.131.133.36:8080','Reactor_10','http://???','Reactor_2','http://128.131.133.45:8080')
        soapaction % is dynamically assigned by initialization
    end
    
    properties (Access = private)   
        operations = ["Browse" "Read" "Write"]
        soapxml = struct('Browse','browse.xml','Read','read.xml','Write','write.xml')
        types = ["xsd:float"        "single";...
                 "xsd:float"        "double";...
                 "xsd:double"       "double";...
                 "xsd:boolean"      "logical";...
                 "xsd:int"          "int16";...
                 "xsd:unsignedInt"  "uint16";...
                 "xsd:string"       "string"]
        
    end

    methods
        function obj = OPCXMLDA(obj) %Object initialization.
            obj.operationID = obj.initOperationID();
            for i = 1:length(obj.operations)
                obj.operation.(obj.operations(i)) = obj.operations(i);
                obj.soapaction.(obj.operations(i)) = xmlread(obj.soapxml.(obj.operations(i)));
            end
        end
        
        % Main Function definitions
        % here i make the functions for browse read and write requests
        
        function [value, type] = read(obj,ItemNameArg)
            %r = itemName
            if (nargin == 2)
                try
                    itemName = ItemNameArg;
                    %fields = textscan(ItemNameArg,'%s','Delimiter','.');
                    fields = obj.getstructfieldsarray(ItemNameArg);
                catch
                    error('Given OPC-Tag is not Valid.')
                end
            else
                error('Wrong number of arguments given.')
            end
            operation = obj.operation.Read;
            soapaction = obj.getsoapAction(operation);%,["ItemName",itemName]);
            soapaction = obj.soapactionchangeParameters(soapaction,"Items",["ItemName",itemName]);
            response = obj.request(soapaction,operation);
            value = response.getElementsByTagName('Value').item(0).getTextContent;
            type = response.getElementsByTagName('Value').item(0).getAttribute('xsi:type');
            % test if value type is already known, else save it to struct
            % opctypes
            try
                getfield(obj.opctypes,fields{1}{:})
            catch
                obj.opctypes=makestructentry(obj,obj.opctypes,itemName,type);
            end
        end
        
        function r = write(obj,itemNameArg,value)
            % In order to make the write function we need to know what
            % types are accepted by the device. Lets use the structure
            % created from browse to get a similar structure but with the
            % accepted types for every element.
            [istype,opctype] = obj.checktype(value,itemNameArg);
            if istype
                xmlvalue = obj.converttype(value,opctype);
                if (nargin == 3)
                    try
                        itemName = itemNameArg;
                        %fields = textscan(ItemNameArg,'%s','Delimiter','.');
                        fields = obj.getstructfieldsarray(itemNameArg);
                    catch
                        error('Given OPC-Tag is not Valid.')
                    end
                else
                    error('Wrong number of arguments given.')
                end
                operation = obj.operation.Write;
                soapaction = obj.getsoapAction(operation);%,["ItemName",itemName]);
                soapaction = obj.soapactionchangeParameters(soapaction,"Items",["ItemName",itemName]);
                %soapaction = obj.soapactionchangeParameters(soapaction,"Value",["xsi:type",opctype]);
                soapaction = obj.soapactionchangeValue(soapaction,xmlvalue,opctype);
                response = obj.request(soapaction,operation);
            else
                error('wrong type')
            end
            
            r = "OK";%xmlwrite(response);
        end

        function r = browse(obj,ItemNameArg)
            % if no browse is performed and the opctags struct is empty
            % there must be a fallback procedure where the hardcoded opc
            % tags are used to poll the opc device
            
            if (nargin == 1)
                itemName = [""];
            elseif (nargin == 2)
                itemName = ItemNameArg;
                %fields = textscan(ItemNameArg,'%s','Delimiter','.');
                %fields = matlab.lang.makeValidName(fields{1});
                fields = obj.getstructfieldsarray(ItemNameArg);
            else
                error('Too many or too few arguments')
            end
            operation = obj.operation.Browse;
            soapaction = obj.getsoapAction(operation);%,["ItemName",itemName]);
            soapaction = obj.soapactionchangeParameters(soapaction,"Browse",["ItemName",itemName]);
            response = obj.request(soapaction,operation);
            %elements = response.getElementsByTagName('n2:BrowseResponse').item(0).getElementsByTagName("Elements");
            elements = response.getElementsByTagName("Elements");
            for i = 1:elements.getLength
                if (elements.item(i-1).getAttributes.getNamedItem("IsItem").getValue) == 'true'
                    name = char(elements.item(i-1).getAttributes.getNamedItem("Name").getValue);
                    value = string(elements.item(i-1).getAttributes.getNamedItem("ItemName").getValue);
                    if itemName == ""
                        obj.opctags.(name) = value;
                    else
                        fieldnames = fields;
                        fieldnames{end+1,:} = matlab.lang.makeValidName(name);
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
        %[r, opctype]=checktype(obj,value,opctag)
        function [r, opctype] = checktype(obj,value,opctag)
            
            try
                fields = textscan(opctag,'%s','Delimiter','.');
            catch
                error('Given OPC-Tag is not Valid.')
            end
            
            try
                opctype = string(getfield(obj.opctypes,fields{1}{:}));
            catch %if not cached read from opc device and cache it
                obj.read(opctag)
                try
                    opctype = string(getfield(obj.opctypes,fields{1}{:}));
                catch
                    error('No OPC-Type cached')
                end
                
            end
            
            try
                foundtype = false;
                
                for i = 1:length(obj.types)
                    if (strcmp(opctype,obj.types(i,1)) & isa(value,obj.types(i,2)))
                        foundtype = true;
                    end
                end
                if foundtype
                    r = true;
                else
                    r = false;
                end
            catch
                error('Error')
            end
        end
            
        function r = makestructentry(obj,struct,ItemNameArg,name,value)
            %fields = textscan(ItemNameArg,'%s','Delimiter','.');
            %fields = matlab.lang.makeValidName(fields{1});
            fields = obj.getstructfieldsarray(ItemNameArg);
            if (nargin == 4)
                value = name; %name holds the value if only 4 par are given
                fieldname = fields;
            elseif (nargin == 5)
                name = char(name);
                fieldname = fields;
                fieldname{end+1,:} = matlab.lang.makeValidName(name);
            else
                error('Wrong number of arguments')
            end
            struct = setfield(struct,fieldname{:},value);
            r = struct;
        end

        function r = request(obj,soapmessage,operation)
            %% New Method using HTTP
            data = soapmessage;
            body = matlab.net.http.MessageBody(data);
            uri = matlab.net.URI(obj.url);
            acceptencodingField = matlab.net.http.field.GenericField('Accept-Encoding','gzip,deflate');
            contentTypeField = matlab.net.http.field.ContentTypeField('text/xml;charset=UTF-8');
            if (obj.operationisValid(operation))
                SOAPActionField = matlab.net.http.field.GenericField('SOAPAction',strcat('http://opcfoundation.org/webservices/XMLDA/1.0/',char(operation)));
            else
                error('operation is not valid')
            end
            %contentlengthField = matlab.net.http.field.ContentLengthField('');
            hostField = matlab.net.http.field.HostField('128.131.133.36:8080');
            connectionField = matlab.net.http.field.ConnectionField('close');
            useragentField = matlab.net.http.field.GenericField('User-Agent','Apache-HttpClient/4.1.1 (java 1.5)');
            %header = [acceptencodingField contentTypeField SOAPActionField contentlengthField hostField connectionField useragentField];
            header = [acceptencodingField contentTypeField SOAPActionField hostField connectionField useragentField];
            method = matlab.net.http.RequestMethod.POST;
            request = matlab.net.http.RequestMessage(method,header,body);
            response = request.send(uri);
            r = response.Body.Data;
            %% Debugging
             show(request)
            % response.Header.string
            % response.Body.show
        end
            
        function r = getsoapAction(obj,operation,arg)
            if nargin <= 2
                par = [];
            else
                par = arg;
            end
            dom = obj.soapaction.(obj.operation.(operation));
            
            if (isempty(par))
                r = dom;
            elseif (mod(length(par),2))
                error('wrong dimensions ["item1","val1","item2,"val2",...]')
            else
                r = obj.soapactionchangeParameters(dom,operation,par);
            end
        end
        
        function r = soapactionreadParameters(obj,dom,par)
            % This function is not yet used. but "soapenv:Body" will make
            % problems with generic opcxml devices
            % Maybe make a funtion which returns the xml so the programmer
            % can search for the tagname in question in the xml?
            tagName = dom.getElementsByTagName("soapenv:Body").item(0).getChildNodes.item(1).getTagName;
            %tagName = strcat('ns:',operation)
            if isempty(par)
                error('par not given')
            else
                for i = 1:length(par)
                    struct.(par(i)) = dom.getElementsByTagName(tagName).item(0).getAttribute(par(i));
                end
                r = struct;
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
                    r = dom;
                else
                    error('par has to be a string array ["item1","val1","item2,"val2",...]')
                end
            end
        end
        
        function r = soapactionchangeValue(obj,dom,value,opctype)
            dom.getElementsByTagName('Value').item(0).setAttribute("xsi:type",opctype)
            dom.getElementsByTagName('Value').item(0).setTextContent(value)
            r = dom;
        end
        

        
        function r = initOperationID(obj)
            for i = 1:length(obj.operations)
                struct.(obj.operations(i)) = i
            end
            r = struct;
        end
        
        
        
        
    end
    methods(Static)
        function r = getstructfieldsarray(ItemNameArg)
            fields = textscan(ItemNameArg,'%s','Delimiter','.');
            fields = matlab.lang.makeValidName(fields{1});
            r = fields;
        end
        function r = converttype(value,opctype)
            % Not yet sure if more conversion is necesary. For now lets
            % keep this silly function
            r = string(value);
        end
    end
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
            r = ismember(operation,obj.operations);
        end
    end
    
end

