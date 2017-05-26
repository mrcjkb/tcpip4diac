classdef tcpip4diac < tcpip
    %TCPIP4DIAC Construct a TCPIP client or server object that can
    %     communicate with 4diac CLIENT/SERVER function blocks.
    %
    %
    % Syntax:
    %
    % 	>> t = tcpip4diac(networkRole);
    %     --> Initializes a TCP/IP object with the network role 'server' or 'client', a default remote host depending on the role and a default
    % 		port set to 61500. The default remote host is 'localhost' for clients and '0.0.0.0' for servers (required to accept requests from
    % 		clients running on FORTE).
    %
    % 	>> t = tcpip4diac(networkRole, remotehost);
    % 	--> Specifies the remote host with the port set to 61500.
    %
    % 	>> t = tcpip4diac(networkRole, remotehost, port);
    % 	--> Specifies the port
    %
    % 	>> t = tcpip4diac(__, 'OptionName', OptionValue);
    % 	--> To specify additional options.
    %
    %
    %
    % The above syntax initializes a TCP/IP object that is capable of communicating with SERVER_1 or CLIENT_1 function blocks, respectively.
    % To communicate with CSIFBs that have multiple data inputs/outputs, use the 'DataInputs' and 'DataOutputs' options, as shown in the following examples.
    % The DataInputs are sent to the client/server FB on FORTE and the DataOutputs are received from the client/server FB on FORTE. The amount of inputs
    % must be equal to the amount of outputs of the corresponding CSIFB on FORTE and vice versa for the amount of outputs.
    %
    % 	>> % Server with 2 inputs and 1 output
    % 	>> dataInputs = {'UINT'; 'LREAL'}; % Specify the IEC 61499 data input types that are expected in a cell array.
    % 	>> t = tcpip4diac('server', '0.0.0.0', 61500, 'DataInputs', dataInputs);
    %
    % 	>> % Server with 3 outputs and 2 inputs
    % 	>> dataOutputs = {'UINT'; 'LREAL'; 'LREAL'};
    % 	>> dataInputs = {'UINT'; 'LREAL'};
    % 	>> t = tcpip4diac('server', '0.0.0.0', 61500, 'DataInputs', dataInputs, 'DataOutputs', dataOutputs);
    %
    % 	>> % Server with no inputs and 1 output
    % 	>> dataInputs = {};
    % 	>> t = tcpip4diac('server', '0.0.0.0', 61500, 'DataInputs', dataInputs);
    %
    %
    % To initialize or deinitialize the connection, use the following syntax, where qi is true for initialization and false for deinitialization:
    %
    % 	>> init(t, qi) % Omit output arguments
    % 	>> qo = init(t, qi); % output logical flag for success/failure (initalization) or false for deinitialization
    % 	>> [qo, status] = init(t, qi); % outputs a status message
    % 	>> [qo, status, t] = init(t, qi, remotehost, port); % Enables to change the remote host and port
    %
    %
    % Alternatively, the functions fopen() and fclose() can be called on the TCP/IP object t for initialization and deinitialization, respectively.
    %
    %
    % In the client role, use the req() function to send requests to a SERVER FB. This method will not return until a response is received.
    % For multiple data inputs, the inputs in1, ..., inN (where N is the number of CSIFB outputs) are automatically casted to the respective
    % ata types expected by the IEC 61499 CSIFB. The returned output data types out1, ... outM (where N is the number of CSIFB inputs)
    % depend on the corresponding IEC 61499 FB input data types. For CSIFBs with a single data input, the input in1 must be casted to the
    % corresponding Matlab data type before passing it to the req() function.
    %
    % 	>> [out1, out2, out3, ..., outM] = req(t, in1, in2, in3, ..., inN);
    %
    %
    % In the server role, use the waitForData function to await data from a CLIENT FB. This will not return until either a response is received
    % or a timeout (specified in seconds) is reached. The default timeout is inf, if not specified.
    % Unfortunately, Matlab's TCP/IP implementation does not appear to provide a method for using callback functions.
    % The data types of the outputs out1, ..., outM correspond with the data types of the CSIFB input SD1, ... SDN.
    %
    % 	>> [out1, out2, out3, ..., outN] = waitForData(t);
    % 	>> [out1, out2, out3, ..., outN] = waitForData(t, timeoutS);
    %
    % Currently, only numeric data types and BOOL are supported for multiple data inputs/outputs.
    % To send a response, use the rsp() method:
    %
    % 	>> rsp(t, in1, ... inN)
    %
    %
    % An 4diac system "ServerTest" is provided as a demo.
    % It provides similar functionality as the Xplus4 application that comes with 4diac-IDE.
    % To test it, import it into 4diac-IDE and deploy it to FORTE.
    % Then run the following code in Matlab:
    %
    % 	>> t = tcpip4diac('client');
    % 	>> init(t, 1)
    % 	>> out = req(t, 5); % returns 8
    %
    % Aside from the above methods, the regular tcpip methods work, too.
    % Using fwrite() will send byte-data and using fread() will receive byte-data, for example.
    %
    % SEE ALSO: tcpip
    %
    % Author: Marc Jakobi, May 2017, HTW-Berlin
    
    properties (Hidden, Access = 'protected')
        % True for client, false for server
        roleFlag;
        % Amount of data inputs
        numDataInputs = 1;
        % Amount of data outputs
        numDataOutputs = 1;
        % Data inputs of the 4diac CLIENT/SERVER function block
        dataInputs;
        % Data inputs of the 4diac CLIENT/SERVER function block
        dataOutputs;
        % Size of the input byte arrays
        iByteArraySizes;
        % Size of the output byte arrays
        oByteArraySizes;
        % Total size of the input byte array that is sent over the network
        totalIByteArraySize;
        % Identifiers for data types to cast to
        castIDs;
    end
    properties (Constant)
        % Matlab equivalents to supported IEC 61499 data types
        supportedMatlabTypes = {'logical'; 'int8'; 'int16'; 'int32'; 'int64'; ...
            'uint8'; 'uint16'; 'uint32'; 'uint64'; 'single'; 'double'; 'char'; 'string'};
        % Supported IEC 61499 data types
        supportedIEC61499Types = {'BOOL'; 'SINT'; 'INT'; 'DINT'; 'LINT'; ...
            'USINT'; 'UINT'; 'UDINT'; 'ULINT'; 'REAL'; 'LREAL'; 'STRING'; 'WSTRING'};
        % Representative IDs of supported IEC 61499 data types
        supportedTypeIDs = [66; 67; 68; 69; 70; 71; 72; 73; 74; 75; 80; 85];
        % Byte numbers of the respective data types (including typeIDs).
        % STRING and WSTRING are currently not supported for multiple
        % inputs due to the fact that they have variable length bytes.
        dataTypeByteNums = [1; 2; 3; 5; 9; 2; 3; 5; 9; 5; 9];
    end
    methods
        function obj = tcpip4diac(networkRole, remotehost, port, varargin)
            if nargin < 3
                port = 61500;
                if nargin < 2
                    remotehost = 'localhost';
                    if nargin < 1
                        networkRole = 'client';
                    end
                end
            end
            if strcmp(networkRole, 'server') && nargin < 2
                remotehost = '0.0.0.0';
            end
            if nargin > 3
                % Check for additional inputs
                p = inputParser;
                addOptional(p, 'DataInputs', {'LREAL'}, @(x) tcpip4diac.validateDataInputs(x))
                addOptional(p, 'DataOutputs', {'LREAL'}, @(x) tcpip4diac.validateDataInputs(x))
                parse(p, varargin{:})
                % Remove additional options from varargin before passing to
                % superclass constructor
                addOpts = {'DataInputs'; 'DataOutputs'};
                for i = 1:numel(addOpts)
                    tf = cellfun(@(x)isequal(x, addOpts{i}), varargin);
                    if any(tf)
                        tf(find(tf,1) + 1) = true;
                        varargin = varargin(~tf);
                    end
                end
            end
            obj@tcpip(remotehost, port, 'NetworkRole', networkRole, varargin{:});
            if nargin > 3 % Set additional data input/output params
                obj.dataInputs = p.Results.DataInputs;
                obj.dataOutputs = p.Results.DataOutputs;
                obj.numDataInputs = numel(obj.dataInputs);
                obj.numDataOutputs = numel(obj.dataOutputs);
                obj.iByteArraySizes = zeros(obj.numDataInputs, 1);
                obj.castIDs = cell(obj.numDataInputs, 1);
                for i = 1:obj.numDataInputs
                    tf = ismember(tcpip4diac.supportedIEC61499Types, obj.dataInputs{i});
                    obj.iByteArraySizes(i) = obj.dataTypeByteNums(tf);
                    obj.castIDs{i} = obj.supportedMatlabTypes{tf};
                end
                obj.totalIByteArraySize = sum(obj.iByteArraySizes);
                obj.oByteArraySizes = zeros(obj.numDataOutputs, 1);
                for i = 1:obj.numDataOutputs
                    tf = ismember(tcpip4diac.supportedIEC61499Types, obj.dataOutputs{i});
                    obj.oByteArraySizes(i) = obj.dataTypeByteNums(tf);
                end
            end
            if strcmp(networkRole, 'client')
                obj.roleFlag = true;
            else
                obj.roleFlag = false;
            end
        end
        function [qo, status, obj] = init(obj, qi, remotehost, port)
            if nargin > 2 && nargout > 2 % Change address?
                obj.RemoteHost = remotehost;
                if nargin > 3
                    obj.RemotePort = port;
                end
            end
            if qi % Init
                try
                    fopen(obj);
                    if nargout > 0
                        qo = true;
                        if nargout > 1
                            status = 'OK';
                        end
                    end
                catch ME
                    if nargout > 0
                        qo = false;
                        if nargout > 1
                            status = ME.message;
                        end
                    end
                end
            else % Deinit
                try
                    fclose(obj);
                    if nargout > 0
                        qo = false;
                        if nargout > 1
                            status = 'OK';
                        end
                    end
                catch ME
                    if nargout > 0
                        qo = false;
                        if nargout > 1
                            status = ME.message;
                        end
                    end
                end
            end
        end
        function varargout = req(obj, data1, varargin)
            if nargout ~= obj.numDataOutputs
                error('Wrong amount of output arguments.')
            elseif nargin - 1 ~= obj.numDataInputs
                error('Wrong amount of input arguments.')
            elseif ~obj.roleFlag % Server object?
                error('Method "req" only valid for client objects.')
            end
            if nargin > 1
                sd = obj.matlabToByteData(data1, varargin{:});
                fwrite(obj, sd)
            else
                fwrite(obj, 5) % No data inputs
            end
            [varargout{1:nargout}] = waitForData(obj);
        end
        function rsp(obj, data1, varargin)
            if nargin - 1 ~= obj.numDataInputs
                error('Wrong amount of input arguments.')
            elseif obj.roleFlag % Client object?
                error('Method "rsp" only valid for server objects.')
            end
            sd = obj.matlabToByteData(data1, varargin{:});
            fwrite(obj, sd)
        end
        function varargout = waitForData(obj, timeoutS)
            if nargout ~= obj.numDataOutputs
                error('Wrong amount of output arguments.')
            end
            if nargin < 2
                timeoutS = inf;
            end
            tic
            ba = get(obj, 'BytesAvailable');
            while ba == 0
                ba = get(obj, 'BytesAvailable');
                if toc > timeoutS
                    error('Connection timed out.')
                end
            end
            sd = fread(obj, ba);
            if obj.numDataOutputs == 1
                varargout{1} = obj.iec61499ToMatlab(sd);
            elseif obj.numDataOutputs == 0
                varargout = {};
            else
                varargout{nargout} = [];
                lastIdx = obj.oByteArraySizes(1);
                varargout{1} = obj.iec61499ToMatlab(sd(1:lastIdx));
                for i = 2:obj.numDataOutputs
                    n = obj.oByteArraySizes(i);
                    varargout{i} = obj.iec61499ToMatlab(sd(lastIdx+1:lastIdx+n));
                    lastIdx = lastIdx + n;
                end
            end
        end
    end
    
    methods (Access = 'protected')
        function sd = matlabToByteData(obj, data1, varargin)
            if obj.numDataInputs > 1 % multiple inputs
                sd = zeros(obj.totalIByteArraySize, 1, 'uint8');
                % First data input
                lastIdx = obj.iByteArraySizes(1);
                data1 = cast(data1, obj.castIDs{1});
                sd(1:lastIdx) = obj.matlabToIEC61499(data1);
                for i = 2:obj.numDataInputs
                    datan = cast(varargin{i-1}, obj.castIDs{i});
                    datan = obj.matlabToIEC61499(datan);
                    n = obj.iByteArraySizes(i);
                    if numel(datan) ~= n
                        error('Data type mismatch')
                    end
                    sd(lastIdx+1:lastIdx+n) = datan;
                    lastIdx = lastIdx + n;
                end
            else % only 1 input
                sd = obj.matlabToIEC61499(data1);
            end
        end
        function sd = matlabToIEC61499(obj, data)
            [typeID, castID] = obj.getTypeID(data);
            % Convert to appropriate byte-data that 4diac server FB can
            % understand
            if isempty(typeID) % BOOL
                sd = 64 * data + 65 * ~data;
            elseif isnumeric(data) % SINT...UDINT / REAL & LREAL
                sd = [typeID, fliplr(typecast(data, 'uint8'))]';
            elseif strcmp(castID, 'char') % STRING
                sd = [typeID; 0; 4; uint8(data)'];
            elseif strcmp(castID, 'string') % WSTRING
                val = char(data);
                tmp = zeros(2*numel(val) + 1, 1, 'uint8');
                tmp(2:2:end-1) = uint8(val);
                sd = [typeID; 0; 6; 0; 39; tmp; 39];
            end
        end
        function rd = iec61499ToMatlab(obj, sd)
                if numel(sd) == 1 % BOOL
                    rd = sd == 64;
                else
                    typeID = sd(1);
                    castID = obj.getCastID(typeID);
                    if typeID == 80 % STRING
                        rd = char(uint8(sd(4:end))');
                    elseif typeID == 85 % WSTRING
                        rd = string(char((uint8(sd(7:2:end-2)'))));
                    else % SINT...UDINT / REAL & LREAL
                        rd = typecast(flipud(uint8(sd(2:end))), castID);
                    end
                end
        end
        function [typeID, castID] = getTypeID(obj, data)
            castID = class(data);
            idx = find(ismember(obj.supportedMatlabTypes, castID), 1);
            if ~isempty(idx)
                typeID = obj.supportedTypeIDs(idx-1);
            else
                error(['The data type "', castID, '" is currently unsupported.'])
            end
        end
        function castID = getCastID(obj, typeID)
            idx = find(obj.supportedTypeIDs == typeID, 1);
            if ~isempty(idx)
                castID = obj.supportedMatlabTypes{idx+1};
            else
                error('Received unsupported data type.')
            end
        end
    end
    
    methods (Static, Access = 'protected')
        function tf = validateDataInputs(x)
            if ~iscell(x)
                error('Expected a cell array for DataInputs')
            end
            tf = true;
            if ~isempty(x) % Empty if set to zero
                for i = 1:numel(x)
                    tf = tf & ischar(validatestring(x{i}, tcpip4diac.supportedIEC61499Types(1:end-2)));
                end
            end
        end
    end
end
