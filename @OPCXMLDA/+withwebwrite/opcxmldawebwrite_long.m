

%options = weboptions('CharacterEncoding','UTF-8','ContentType','xml','RequestMethod');

options = weboptions
options.CharacterEncoding='UTF-8'
options.ContentType='xml'
options.RequestMethod='POST'
headers = {'Accept-Encoding' 'gzip,deflate';
           'Content-Type' 'text/xml;charset=UTF-8';
           'SOAPAction' 'http://opcfoundation.org/webservices/XMLDA/1.0/Browse'}
options.HeaderFields=headers

data = xmlread('Browse.xml')

url = 'http://128.131.133.36:8080'

response = webwrite(url,data,options)
xmlwrite(response)
