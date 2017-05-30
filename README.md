# tcpip4diac
Enables TCP/IP client/server connection between Matlab and 4diac Communication Service Interface Function blocks (SERVER/CLIENT).
Subclass of Matlab's tcpip class. The transferred byte-data is automatically translated to the respective data types.


TCPIP4DIAC Construct a TCPIP client or server object that can
    communicate with 4diac CLIENT/SERVER function blocks.
    
	
Syntax:
    
	>> t = tcpip4diac(networkRole);
    --> Initializes a TCP/IP object with the network role 'server' or 'client', a default remote host depending on the role and a default
		port set to 61500. The default remote host is 'localhost' for clients and '0.0.0.0' for servers (required to accept requests from
		clients running on FORTE).
		
	>> t = tcpip4diac(networkRole, remotehost);
	--> Specifies the remote host with the port set to 61500.

	>> t = tcpip4diac(networkRole, remotehost, port);
	--> Specifies the port
	
	>> t = tcpip4diac(__, 'OptionName', OptionValue);
	--> To specify additional options.



The above syntax initializes a TCP/IP object that is capable of communicating with SERVER_1 or CLIENT_1 function blocks, respectively.
To communicate with CSIFBs that have multiple data inputs/outputs, use the 'DataInputs' and 'DataOutputs' options, as shown in the following examples.
The DataInputs are sent to the client/server FB on FORTE and the DataOutputs are received from the client/server FB on FORTE. The amount of inputs
must be equal to the amount of outputs of the corresponding CSIFB on FORTE and vice versa for the amount of outputs.

	>> % Server with 2 inputs and 1 output
	>> dataInputs = {'UINT'; 'LREAL'}; % Specify the IEC 61499 data input types that are expected in a cell array.
	>> t = tcpip4diac('server', '0.0.0.0', 61500, 'DataInputs', dataInputs);

	>> % Server with 3 outputs and 2 inputs
	>> dataOutputs = {'UINT'; 'LREAL'; 'LREAL'};
	>> dataInputs = {'UINT'; 'LREAL'};
	>> t = tcpip4diac('server', '0.0.0.0', 61500, 'DataInputs', dataInputs, 'DataOutputs', dataOutputs);
	
	>> % Server with no inputs and 1 output
	>> dataInputs = {};
	>> t = tcpip4diac('server', '0.0.0.0', 61500, 'DataInputs', dataInputs);


To initialize or deinitialize the connection, use the following syntax, where qi is true for initialization and false for deinitialization:

	>> init(t, qi) % Omit output arguments
	>> qo = init(t, qi); % output logical flag for success/failure (initalization) or false for deinitialization
	>> [qo, status] = init(t, qi); % outputs a status message
	>> [qo, status, t] = init(t, qi, remotehost, port); % Enables to change the remote host and port


Alternatively, the functions fopen() and fclose() can be called on the TCP/IP object t for initialization and deinitialization, respectively.


In the client role, use the req() function to send requests to a SERVER FB. This method will not return until a response is received.
For multiple data inputs, the inputs in1, ..., inN (where N is the number of CSIFB outputs) are automatically casted to the respective
ata types expected by the IEC 61499 CSIFB. The returned output data types out1, ... outM (where N is the number of CSIFB inputs)
depend on the corresponding IEC 61499 FB input data types. For CSIFBs with a single data input, the input in1 must be casted to the
corresponding Matlab data type before passing it to the req() function.

	>> [out1, out2, out3, ..., outM] = req(t, in1, in2, in3, ..., inN);


In the server role, use the waitForData function to await data from a CLIENT FB. This will not return until either a response is received
or a timeout (specified in seconds) is reached. The default timeout is inf, if not specified.
Unfortunately, Matlab's TCP/IP implementation does not appear to provide a method for using callback functions.
The data types of the outputs out1, ..., outM correspond with the data types of the CSIFB input SD1, ... SDN.

	>> [out1, out2, out3, ..., outN] = waitForData(t);
	>> [out1, out2, out3, ..., outN] = waitForData(t, timeoutS);

Currently, only numeric data types and BOOL are supported for multiple data inputs/outputs.
To send a response, use the rsp() method:

	>> rsp(t, in1, ... inN)


As a demo for both the server and client functionality, the 4diac systems ServerTest.sys and ClientTest.sys are provided along
with the demo script demo_script.m

Aside from the above methods, the regular tcpip methods work, too.
Using fwrite() will send byte-data and using fread() will receive byte-data, for example.

The currently supported data types and their correspondences are listed as follows:

   IEC 61499 data type  |		Matlab data type		|			Notes
---------------------------------------------------------------------------------------
		BOOL			| 			logical				|			  -
		SINT			|			int8				|			  -
		INT 			|			int16				|			  -
		DINT			|			int32				|			  -
		LINT			|			int64				|			  -
		USINT			|			uint8				|			  -
		UINT			|			uint16				|			  -
		UDINT			|			uint32				|			  -
		ULINT			|			uint64				|			  -
		REAL			|			single				|			  -
		LREAL			|			double				|			  -
		STRING			|			char				|	only supported for objects 
						|								|	with max. 1 input/output.
		WSTRING			|			string				|	only supported for objects 
						|								|	with max. 1 input/output.
						|								|	Requires Matlab R2016b or
						|								|	above.
		DATE_AND_TIME   |           1x6 double          |   According to Matlab's datevec 
                        |                               |   format

Please report bugs in the GitHub issue tracker. I am also glad for anyone who commits improvements.						
						
SEE ALSO: tcpip

Author: Marc Jakobi, May 2017, HTW-Berlin