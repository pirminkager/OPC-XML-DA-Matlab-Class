%options = weboptions('CharacterEncoding','UTF-8','ContentType','xml','RequestMethod');

browse = 'Browse'
write = 'Write'
read = 'Read'
soapaction = browse

%Initialising options
options = weboptions()
options.ContentType='xml'
headers = {'SOAPAction' strcat('http://opcfoundation.org/webservices/XMLDA/1.0/',soapaction)} %% This needs to be adjusted
options.HeaderFields=headers

data = xmlread('browse.xml')

url = 'http://128.131.133.36:8080'

%% Browse function
response = webwrite(url,data,options)
xmlwrite(response)
%outnew = dom2struct(response)

%% Getting child nodes
children = response.getChildNodes
for i = 1:children.getLength
    node = children.item(i-1)
    s.name = char(node.getNodeName);
end