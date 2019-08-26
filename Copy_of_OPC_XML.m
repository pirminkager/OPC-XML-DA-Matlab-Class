%%

%%

url = 'http://128.131.133.36:8080'

data = xmlread('browse.xml')

%% HTTP Request

data = xmlread('browse.xml')
data2 = xmlwrite(data)
body = matlab.net.http.MessageBody(data2);
body.show

acceptencodingField = matlab.net.http.field.GenericField('Accept-Encoding','gzip,deflate');

contentTypeField = matlab.net.http.field.ContentTypeField('text/xml;charset=UTF-8');

SOAPActionField = matlab.net.http.field.GenericField('SOAPAction','http://opcfoundation.org/webservices/XMLDA/1.0/Browse');

value = 512;
contentlengthField = matlab.net.http.field.ContentLengthField(value);

header = [acceptencodingField contentTypeField SOAPActionField contentlengthField];

method = matlab.net.http.RequestMethod.POST;

request = matlab.net.http.RequestMessage(method,header,body);
show(request)