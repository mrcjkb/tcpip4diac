%% 1. Client in Matlab - server in FORTE.
% --> First, import the file ServerTest.sys into 4diac-IDE and compile the
% application ServerTestApp onto FORTE, then run the following:
t = tcpip4diac('client'); % host = 'localhost'; address = 61500;
init(t, 1) % connect to server
out = req(t, 5); % returns 8
init(t, 0) % disconnect

%% 2. Server in Matlab - client in FORTE
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