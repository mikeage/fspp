MXMLC := "c:\PortableApps\PortableApps\FlexSDK\bin\mxmlc.exe" 

MXMLCFLAGS := --use-network=false -debug=true

pan0.swf: pan0.as
	$(MXMLC) $(MXMLCFLAGS) pan0.as

clean:
	$(RM) pan0.swf
