%%

%%

url = 'http://128.131.133.36:8080'

data = xmlread('read.xml')

%% HTTP Request

% Import the xml file
% xmlread converts the xml to a DOI Object
% xmlwrite converts the DOI Object back to a serialized string of
% characters
data = xmlread('write.xml')
% data2 = xmlwrite(data)

% Define the MessageBody and Print it
body = matlab.net.http.MessageBody(data);
body.show

uri = matlab.net.URI('http://128.131.133.36:8080');

acceptencodingField = matlab.net.http.field.GenericField('Accept-Encoding','gzip,deflate');

contentTypeField = matlab.net.http.field.ContentTypeField('text/xml;charset=UTF-8');

SOAPActionField = matlab.net.http.field.GenericField('SOAPAction','http://opcfoundation.org/webservices/XMLDA/1.0/Write');

%value = 538;
%contentlengthField = matlab.net.http.field.ContentLengthField(value);

hostField = matlab.net.http.field.HostField('128.131.133.36:8080');

connectionField = matlab.net.http.field.ConnectionField('close')

useragentField = matlab.net.http.field.GenericField('User-Agent','Apache-HttpClient/4.1.1 (java 1.5)')

%header = [acceptencodingField contentTypeField SOAPActionField contentlengthField hostField connectionField useragentField];
header = [acceptencodingField contentTypeField SOAPActionField hostField connectionField useragentField];

method = matlab.net.http.RequestMethod.POST;

request = matlab.net.http.RequestMessage(method,header,body);
% show(request)

%%

response = request.send(uri)
response.Header.string
response.Body.show