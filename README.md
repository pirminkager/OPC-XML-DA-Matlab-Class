# OPC-XML-Interface
An OPC XML Interface for Matlab. Originally used to communicate with a Labfors bioreactor system.

!!! Very early proof of concept !!!

The interface is designed as a Matlab Class. To use it copy the folder containing the class in your matlab path.
```
> opcdevice = OPCXMLDA
> opcdevice.url = 'http://128.131.133.45:8080'
> opcdevice.browse()
> opcdevice.opclist.struct.with.opc.tags
> opcdevice.read('opc.tag')
> opcdevice.write('opc.tag',value)
```
