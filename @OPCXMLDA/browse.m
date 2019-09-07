%%NOW PART OF OPCXMLDA class
function opclist = browse(obj,ItemNameArg)
%BROWSE Summary of this function goes here
%   Detailed explanation goes here

        if (nargin == 1)
            itemName = [""];
        elseif (nargin == 2)
            itemName = ItemNameArg;
            fields = textscan(ItemNameArg,'%s','Delimiter','.');
        else
            error('Too many or too few arguments')
        end
        operation = obj.operation.Browse;
        soapaction = obj.getsoapAction(operation,["ItemName",itemName]);
        options = obj.getWeboptions(operation);
        response = webwrite(obj.url,soapaction,options);
        elements = response.getElementsByTagName('n2:BrowseResponse').item(0).getElementsByTagName("Elements");
        for i = 1:elements.getLength
            if (elements.item(i-1).getAttributes.getNamedItem("IsItem").getValue) == 'true'
                name = string(elements.item(i-1).getAttributes.getNamedItem("Name").getValue);
                value = string(elements.item(i-1).getAttributes.getNamedItem("ItemName").getValue);
                if itemName == ""
                    obj.opclist.(name) = value;
                else
                    obj.opclist = setfield(obj.opclist,fields{1}{:},value);
                end
            elseif (elements.item(i-1).getAttributes.getNamedItem("HasChildren").getValue) == 'true'
                value = string(elements.item(i-1).getAttributes.getNamedItem("ItemName").getValue);
                obj.browse(value)
            end
        end
end