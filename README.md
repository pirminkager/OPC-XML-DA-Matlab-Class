# OPC-XML-Interface
An OPC XML Interface for Matlab. Originally used to communicate with a Labfors bioreactor system.

Working OPCXML Actions:
Read
Write
Browse

At this point i dont know if i will include more Actions to the Class.

Also i did not test it with other OPCXML devices though i think adaption is straightforward.

The interface is designed as a Matlab Class. To use it copy the folder containing the class in your matlab path.

Example Usage
```
>> opcdevice = OPCXMLDA
>> opcdevice.url = 'http://128.131.133.45:8080'
>> opcdevice.browse()
>> opcdevice.opclist.matlabstruct.with.opc.tags
>> opcdevice.read(opcdevice.opclist.opc.tag)
>> opcdevice.write('opc.tag',value)
```
