classdef tcpip4diac1 < tcpip
    %TCPIP4DIAC Construct a TCPIP client or server object that can
    %communicate with 4diac CLIENT/SERVER function blocks.
    %
    properties (Hidden, Access = 'protected')
        % True for client, false for server
        roleFlag;
        % Representative of BOOL, SINT, INT, DINT, LINT, ...
        %                   USINT, UINT, UDINT, ULINT, REAL, LREAL, STRING,
        %                   WSTRING
        supportedCastIDs = {'logical'; 'int8'; 'int16'; 'int32'; 'int64'; ...
            'uint8'; 'uint16'; 'uint32'; 'uint64'; 'single'; 'double'; 'char'; 'string'};
        % Representative of BOOL, SINT, INT, DINT, LINT, ...
        %                   USINT, UINT, UDINT, ULINT, REAL, LREAL, STRING,
        %                   WSTRING
        supportedTypeIDs = [66; 67; 68; 69; 70; 71; 72; 73; 74; 75; 80; 85];
    end
    methods
        function obj = tcpip4diac1(networkRole, address, port)
            if nargin < 3
                port = 61500;
                if nargin < 2
                    address = 'localhost';
                    if nargin < 1
                        networkRole = 'client';
                    end
                end
            end
            obj@tcpip(address, port, 'NetworkRole', networkRole);
            if strcmp(networkRole, 'client')
                obj.roleFlag = true;
            else
                obj.roleFlag = false;
            end
        end
        function [qo, status] = init(obj, qi, host, port)
            if nargin > 2
                obj.RemoteHost = host;
                obj.RemotePort = port;
            end
            if qi
                try
                    fopen(obj);
                    qo = true;
                    status = 'OK';
                catch ME
                    qo = false;
                    status = ME.message;
                end
            else
                try
                    fclose(obj);
                    qo = false;
                    status = 'OK';
                catch ME
                    qo = false;
                    status = ME.message;
                end
            end
        end
        
        function rd = req(obj, data)
            if ~obj.roleFlag % Server object?
                error('Method "req" only valid for client objects.')
            end
            sd = obj.matlabToIEC61499(data);
            fwrite(obj, sd)
            if nargout > 0
                warning('off', 'instrument:fread:unsuccessfulRead')
                sd = fread(obj);
                warning('on', 'instrument:fread:unsuccessfulRead')
                rd = obj.iec61499ToMatlab(sd);
            end
        end
    end
    
    methods (Access = 'protected')
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
            idx = find(ismember(obj.supportedCastIDs, castID), 1);
            if ~isempty(idx)
                typeID = obj.supportedTypeIDs(idx-1);
            else
                error(['The data type "', castID, '" is currently unsupported.'])
            end
        end
            function castID = getCastID(obj, typeID)
                idx = find(obj.supportedTypeIDs == typeID, 1);
                if ~isempty(idx)
                    castID = obj.supportedCastIDs{idx+1};
                else
                    error('Received unsupported data type.')
                end
            end
    end
    
    
end

