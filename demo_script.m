%% Demo 1: Client in Matlab - server in FORTE.
%
% What this demo does: Sends a variable to a FORTE application which
% adds 3 to the data and sends the result back to Matlab

% --> First, import the file ServerTest.sys into 4diac-IDE and compile the
% application ServerTestApp onto FORTE, then run the following:
var = 5;
t = tcpip4diac('client'); % host = 'localhost'; address = 61500;
init(t, 1) % connect to server
out = req(t, var); % returns var + 3
disp(out)
init(t, 0) % disconnect

%% 2. Server in Matlab - client in FORTE
%
% What this demo does: A FORTE application sends an integer (3) to the
% tcpip4diac server object in Matlab. Upon receival of the data, Matlab
% adds 3 to the variable and sends it back to FORTE. The FORTE application
% sends the received result back to Matlab and Matlab adds 3 to it, and so
% on...

% --> Import the file ClientTest.sys into 4diac-IDE.
% Important: The ID of the CLIENT_1 function block in the FORTE_PC.EMB_RES
% resource must be set what is displayed in the commmand window
% after excecuting the following line:
disp([char(java.net.InetAddress.getLocalHost.getHostAddress), ':61500']); % Java must be enabled for this to work

% Run the following code before compiling the application ClientTestApp onto FORTE.
t = tcpip4diac('server'); % host = '0.0.0.0'; address = 61500;
init(t, 1) % Will not return until FORTE client has connected.
connected = true;
while connected % This will run in an endless loop until connection is lost or user aborts with CTRL+C
    out = waitForData(t); % Will not return until client sends request (timeout = inf)
    out = out + 3;
    disp(out)
    rsp(t, out) % Send response
    if strcmp(get(t, 'Status'), 'closed')
        connected = false;
        disp('Connnection with FORTE lost')
    end
end