function obj = proportionAirModbus(varargin)
%MODBUS Construct a MODBUS communication object.
%
%   m = modbus('Transport', 'DeviceAddress', 'PropertyName', PropertyValue,...)
%   m = modbus('Transport', 'DeviceAddress', Port, 'PropertyName', PropertyValue,...)
%   m = modbus('Transport', 'Port', 'PropertyName', PropertyValue,...)  
%   
%   Arguments:
%   
%  'Transport'    : Describes physical transport layer for device
%                   communication. Valid values are 'tcpip' and 'serialrtu'.
%  'DeviceAddress': IP address or host name of Modbus server, 
%                   e.g. '192.168.2.1'. Required if Transport is 'tcpip'.
%   Port          : Remote port used by Modbus server. Default is 502. 
%                   Optional if transport is 'tcpip'
%  'Port'         : Serial port Modbus server is connected to, e.g. 'COM1'. 
%                   Required if transport is 'serialrtu'
%  'PropertyName' : A modbus property name
%   PropertyValue : A property value supported by PropertyName
%
%   Creates a modbus object and connects to the modbus server over a 
%   physical transport of either TCP/IP or Serial. If Transport is 
%   'tcpip', DeviceAddress must be specified. Port is optional 
%   and defaults to 502 (reserved port for Modbus). If Transport is 
%   'serialrtu', Port must be specified. Optional parameters are described
%   below.
%
%   If an invalid property name or property value is specified, or the 
%   transport is not available, the object will not be created.
%
%   Properties:
%   
%   Common (all Transports) 
%   Timeout 	Maximum time in seconds to wait for a response from the 
%               Modbus server. Default is 10 seconds.
%   NumRetries 	Number of retries to perform if there is no reply from the 
%               server after a timeout. 
%  'ByteOrder'  Byte order of values written to or read from 16-bit 
%               registers. Valid choices are 'big-endian' and 
%               'little-endian'. The default is 'big-endian' as specified 
%               by the Modbus standard. 
%  'WordOrder' 	Word order for register reads and writes that span multiple 
%               16-bit registers. Valid choices are 'big-endian' and 
%               'little-endian'. The default is 'big-endian', and is device 
%               dependent. 
%
%   serialrtu only 
%   BaudRate 	Default is 9600 bits per second, but the actual required 
%               value will be device-dependent. 
%   DataBits 	Default is 8, which is the Modbus standard for serial RTU. 
%   Parity      Valid choices are 'none' (default), 'even', 'odd', 'mark', 
%               and 'space'. Actual required value will be device-dependent. 
%   StopBits 	Valid choices are 1 (default) and 2. Actual required value 
%               will be device-dependent, though 1 is typical for even/odd 
%               parity and 2 for no parity.
%
%   Examples:
%
%   % Create an instance of the modbus TCP/IP object
%   m = modbus('tcpip','192.168.2.15',502)
%
%   % Create an instance of the Modbus Serial RTU object
%   m = modbus('serialrtu','COM6')
%
%   % read 8 discrete input values starting at address 34456
%   address = 34456;
%   data = read(m,'inputs',address,8)
%
%   % write values to 4 coils starting at address 8289
%   write(m,'coils',8289,[1 1 0 1])
%
%   % delete and disconnect from MODBUS server
%   clear(m)
%
% Function help:
%
%   <a href="matlab:help instrument.interface.Modbus.Modbus.write">write</a>		- Write data to the Modbus server.
%   <a href="matlab:help instrument.interface.Modbus.Modbus.read">read</a>		- Read data from the Modbus server.
%   <a href="matlab:help instrument.interface.Modbus.Modbus.writeRead">writeRead</a>	- Write data to, then read data from the Modbus server in one transaction.
%   <a href="matlab:help instrument.interface.Modbus.Modbus.maskWrite">maskWrite</a>	- Perform a register mask write operation on the Modbus server.

%   Copyright 2017 The MathWorks, Inc.

    % Verify that we have at least two input arguments before proceeding.
    % Detailed argument checking will be done in the transport specific 
    % Modbus constructor which will be instantiated below.
    narginchk(2,inf);

    %import instrument.interface.modbus.Modbus;
    obj = proportionair.interface.modbus.serialrtu.Modbus(varargin{:});