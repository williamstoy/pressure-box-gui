classdef SM5 < handle
    
    %% CREDITS
    % Original version contributed by Valentin Stein & Nils Korber, University of Bonn, 5/4/2011
    % Modified by Vijay Iyer 1/2014, for inclusion in ScanImage 3.8.1 & 4.2
    
    %% ABSTRACT PROPERTY REALIZATIONS (dabs.interfaces.LinearStageController)
    properties (Constant,Hidden)
        nonblockingMoveCompletedDetectionStrategy = 'poll';
    end
    
    properties (SetAccess=protected,Dependent)
        positionAbsoluteRaw;
        invertCoordinatesRaw;
        velocityRaw;
        accelerationRaw;
        isMoving;
        maxVelocityRaw;
    end
    
    properties (SetAccess=protected,Hidden)
        velocityDeviceUnits = nan;
        accelerationDeviceUnits = nan;
        resolutionRaw = 1;
        positionDeviceUnits = 1e-6; %microns
    end
    
    %% HIDDEN PROPERTIES
    
    properties (Hidden)
        
        MoveInProgress = false;         % Properties to avoid crossover of commands
        MovingRequest  = true;          % via the isMoving poll
        Serial = [];                    % Serial object for COMmunication
        Timer  = [];                    % Timer object for regular update of connection
        LastAnswer  = [];               % Answer to last Command
        Connected   = false;            % Was it ever connected
        Portopen    = false;            % Port open, might be redundant to connected
        PresentDevice = [];             % Present Devices (Matrix of true and false for 48 possible devices)
        PresentDeviceNumbers = [];      % Numbers of all Devices in the system
        ActualDevice  = uint8(1);       % Device number to talk to, can be direct added in most methods
        Position      = [];             % Postion of a Device in µm,
        PositionOK    = [];             % Is the Position equal to the device display
        StateMotor           = [0 0 0]; % Motor running
        VelocityFast         = []       % Velocity for fast positioning in full steps per s (1:3000) - (associated Command: SM5GoToPosition...)
        comPortNum = 3;
    end
    
    properties (SetAccess=private)
        commandMap = zlclInitCommandMap();        
    end
    
    %% OBJECT LIFE CYCLE
    
    methods 
        function obj = SM5(varargin)
            disp('CONNECTING TO LUIGS AND NEUMANN MANIPULATOR CONTROLLER');
            %global state
            
            %pvArgs = most.util.filterPVArgs(varargin,{'comPort' 'numDeviceDimensions'},{'comPort'});           
            
            %pvStruct = most.util.cellPV2structPV(pvArgs);
            %if ~isfield(pvStruct,'numDeviceDimensions')
            %    pvArgs = [pvArgs {'numDeviceDimensions' 3}];
            %end
            %obj = obj@dabs.interfaces.LinearStageController(pvArgs{:});
            
            obj.comPortNum = 3; % TODO: don't hard code this
            obj.ActualDevice = uint8(2); % TODO: don't hard code this
            
            %---------------------------------------------------
            % constructor, creates the serial object
            %---------------------------------------------------
            
            oldSerial = instrfind('Tag', 'SM5');
            if ~isempty(oldSerial)
                fclose(oldSerial);
                delete(oldSerial);
                clear('oldSerial');
            end
            
            oldTimer = timerfind('Tag', 'SM5');
            if ~isempty(oldTimer)
                stop(oldTimer);
                delete(oldTimer);
                clear('oldTimer');
            end
            
            % Create the serial object ons specified com port
            obj.Serial                        = serial(sprintf('COM%d',obj.comPortNum));               % use connected COM-Port
            obj.Serial.Baudrate               = 38400;
            obj.Serial.Timeout                = 5;
            obj.Serial.Tag                    = 'SM5';
            
            % Create timer object
            % To keep the conncetion alive, something has to be send to the
            % SM5 after 3s. This timer is restarted after every Command send
            % to the SM5, this way no additonal Commands are sent.
            
            obj.Timer                        = timer;
            obj.Timer.Tag                    = 'SM5';
            obj.Timer.Period                 = 2.5;          % call KeepAlive every 2.5s
            obj.Timer.StartDelay             = 2.5;          % 1st call after connect is delayed
            obj.Timer.ExecutionMode          = 'fixedRate';
            obj.Timer.TimerFcn               = @(src,evnt)obj.SM5KeepAlive;
            
            obj.PresentDeviceNumbers = [3*(obj.ActualDevice-1)+1 3*(obj.ActualDevice-1)+2 3*(obj.ActualDevice-1)+3];
            
            %obj.PresentDeviceNumbers         = [state.motor.xDevice, state.motor.yDevice, state.motor.zDevice];   % from standard.ini
            %obj.VelocityFast                 = state.motor.velocityFast;     % take velocity from INI, all axis have the same speed, we could make the Z axis different
            
            %             for i = obj.PresentDeviceNumbers
            %                 obj.SM5SetVelocityFast(obj.VelocityFast, i);
            %             end
            
            
            
            obj.SM5Connect();
        end
        
        % TODO: for some reason clearing the variable does not call delete
        % it must be called explicitly
        function delete(obj)                             % Delete handle and close connection
            disp('DELETING MANIPULATOR OBJECT');
            obj.SM5Disconnect();
            
            obj.Serial = instrfind('Tag', 'SM5');
            if ~isempty(obj.Serial)
                fclose(obj.Serial);
                delete(obj.Serial);
                clear('obj.Serial');
            end
            
            obj.Timer = timerfind('Tag', 'SM5');
            if ~isempty(obj.Timer)
                if isequal(get(obj.Timer, 'Running'), 'on')
                   stop(obj.Timer); 
                end
                
                delete(obj.Timer);
                clear('obj.Timer');
            end
        end                
    end
        
        %% HIDDEN METHODS
        methods
        
            function obj = SM5Connect(obj)                            % open the serial and establish the connection
                if ~obj.Connected
                    fopen(obj.Serial);
                    start(obj.Timer);
                    
                    fwrite(obj.Serial, obj.SM5GenerateCommand('Connect'));
                    SM5Power = tic;
                    while obj.Serial.BytesAvailable < 6
                        if toc(SM5Power) > 2
                            error('SM5 is not powered');
                        end
                    end
                    obj.LastAnswer = fread(obj.Serial, 6);
                    obj.Portopen   = true;
                end
            end
            
            function obj = SM5Disconnect(obj)
                if obj.Connected
                    fwrite(obj.Serial, obj.SM5GenerateCommand('Disconnect'));
                    stop(obj.Timer); % keep this order, otherwise you might call KeepAlive, after the port has been closed
                    fclose(obj.Serial);
                    obj.Connected = false;
                end
            end
            
            function obj = SM5KeepAlive(obj,~,~)
                
                fwrite(obj.Serial, obj.SM5GenerateCommand('KeepAlive'));
                
                while obj.Serial.BytesAvailable < 6
                end
                obj.LastAnswer = fread(obj.Serial, 6);                
            end
            
        end
        
        methods
            function set.LastAnswer(obj, answer)
               obj.LastAnswer = uint8(answer)';
            end
        end
           
    %%    
        
        %% ABSTRACT PROP ACCESS IMPLEMENTATIONS
        methods
            function v = get.positionAbsoluteRaw(obj)
                for i = obj.PresentDeviceNumbers
                    obj.SM5GetPosition(i);
                end
                v = round(obj.Position.*100)/100;
            end
            
            function tf = get.isMoving(obj)
                if (obj.MovingRequest == true) && (obj.MoveInProgress == false)      % this avoids double call which can cause hard errors
                    obj.MovingRequest = false;
                    obj.SM5GetMainStatusFromOutputStage();
                    obj.MovingRequest = true;
                end
                tf = obj.StateMotor(obj.ActualDevice);
            end
            
        end
        
        
%         %% ABSTRACT METHOD IMPLEMENTATIONS (dabs.interfaces.LinearStageController)
%         methods (Access=protected,Hidden)
%             
%             function moveStartHook(obj,absTargetPosn)
%                 
%                 obj.MoveInProgress = true;
%                 GoTo = absTargetPosn - obj.Position;
%                 Device = find(abs(GoTo) >= 0.005);      % calls the move only if the distance is bigger than resolution
%                 Device = obj.PresentDeviceNumbers(Device);
%                 for i = Device
%                     obj.StateMotor(i) = 1;
%                     obj.SM5GoToPositionFastRel(GoTo(i),i);
%                 end
%                 obj.MoveInProgress = false;
%             end
%             
%             function moveCompleteHook(obj,absTargetPosn)
%                 GoTo = absTargetPosn - obj.Position;
%                 Device = find(abs(GoTo) >= 0.005);                     % threshold for minimum movement step
%                 Device = obj.PresentDeviceNumbers(Device);
%                 
%                 for i = Device
%                     obj.SM5GoToPositionFastRel(GoTo(i),i);
%                 end
%                 
%                 for i = Device                                          % this is the blocking unit of the blocking move
%                     obj.SM5GetMainStatusFromOutputStage(i);
%                 end
%                 
%                 if ~sum(obj.StateMotor)
%                     % motor needs double request to ensure switched state recognition
%                     % changing status in SM5 seems slow
%                     % we might not need this, try to elimnate in future version
%                     for i = Device
%                         obj.SM5GetMainStatusFromOutputStage(i);
%                     end
%                 end
%                 
%                 while sum(obj.StateMotor)
%                     for i = Device
%                         obj.SM5GetMainStatusFromOutputStage(i);
%                     end
%                 end
%                 
%             end
%         end
%         
%         
        %%  HIDDEN METHODS
        methods (Hidden)
            
            function SM5GetMainStatusFromOutputStage(obj, Device)
                command = obj.SM5GenerateCommand('GetMainStatusFromOutputStage',uint8(Device));                               
                obj.SM5SendCommand(command,13,false);
                obj.StateMotor(Device) = obj.LastAnswer(11);
            end
            
            function SM5GetPosition(obj, Device)
                command = obj.SM5GenerateCommand('GetPosition',uint8(Device));
                answerLengthInBytes = 4;
                obj.SM5SendCommand(command,answerLengthInBytes,false);
                
                obj.Position(Device) = mexUint8ArrayToSingle(obj.LastAnswer(5:(5+answerLengthInBytes-1)));           
            end
            
            function SM5GoToPositionRel(obj, Device, Distance, FastOrSlow, IsBlocking)
                switch FastOrSlow
                    case 'Fast'
                        cmdString = 'GoToPositionFastRel';
                    case 'Slow'
                        cmdString = 'GoToPositionSlowRel';
                    otherwise
                        cmdString = 'GoToPositionFastRel';
                end
                TempDistance = mexSingleToUint8Array(single(Distance));  % convert Positon to an array of Bytes
                
                command = obj.SM5GenerateCommand(cmdString, [uint8(Device), TempDistance]);
                obj.SM5SendCommand(command,0,false);
                
                if IsBlocking
                    pause(0.1);
                    while obj.isMoving(obj)
                       pause(0.1); 
                    end
                end
                
                obj.Position(Device) = obj.Position(obj.ActualDevice) + Distance;
                obj.PositionOK(Device) = false;
            end
            
            function SM5GoToPositionAbs(obj, Device, Position, FastOrSlow, IsBlocking)
                switch FastOrSlow
                   case 'Fast'
                       cmdString = 'GoToPositionFastAbs';
                   case 'Slow'
                       cmdString = 'GoToPositionSlowAbs';
                   otherwise
                       cmdString = 'GoToPositionFastAbs';
                end
               
                TempPosition = mexSingleToUint8Array(single(Position));  % convert Positon to an array of Bytes
               
                command = obj.SM5GenerateCommand(cmdString, [uint8(Device), TempPosition]);
                obj.SM5SendCommand(command,0,false);
                
                if IsBlocking
                    pause(0.1);
                    while obj.isMoving(obj)
                       pause(0.1); 
                    end
                end

                obj.Position(Device) = Position;
                obj.PositionOK(Device) = false;
            end
            
            
            function SM5SetVelocityFast(obj, Device, Velocity)                 % 0 < Velocity <= 3000 (full steps per sec)
                TempVel = mexUint16ToUint8Array(uint16(Velocity));
                command = obj.SM5GenerateCommand('SetVelocityFast', [uint8(Device), TempVel]);
                obj.SM5SendCommand(command,0,false);
            end
            
            function SM5Stop(obj, Device)                                      %stop any Command on the active device    
                command = obj.SM5GenerateCommand('Stop', uint8(Device));    
                obj.SM5SendCommand(command,0,true);
            end
            
           
        end
        
        %% PROTECTED METHODS
        methods  (Access=protected)
            function SM5SendCommand(obj,commandBytes,answerLengthInBytes,insertPause)
                
                % answer is of the form:
                % <ack><XXXX (2 bytes)><responseLength (1 byte)><response><crc (2 bytes)
                bytesToRead = answerLengthInBytes + 6;
                
                if nargin < 4
                   insertPause = false; 
                end
                
                stop(obj.Timer);
                fwrite(obj.Serial, commandBytes);
                if insertPause
                    pause(1);
                end
                while obj.Serial.BytesAvailable < bytesToRead
                end
                
                obj.LastAnswer = fread(obj.Serial, bytesToRead);
                
                %disp(horzcat('Response: ', num2str(obj.LastAnswer)));
                
                % after each command is sent, restart the timer
                obj.SM5StartKeepAliveTimer();
            end
            
            function SM5StartKeepAliveTimer(obj)
                stop(obj.Timer);
                start(obj.Timer);
            end
            
            function command = SM5GenerateCommand(obj,cmdString,cmdArg)                                                
                
                if nargin < 3
                    cmdArg = [];
                end
                
                % only the cmd argument is used in the calculation of the CRC
                [msb, lsb, ~] = mexCRC16(uint8(cmdArg), 0);
                
                %<syn> is 0x16 or 22 in decimal (uint8)
                %<syn><ID><arg><crc>
                %<syn><ID byte 1><ID byte 2><cmd Arg length><cmd Arg><crc msb><crc lsb>
                command = horzcat(22, obj.commandMap(cmdString), cmdArg, msb, lsb);
                %disp(horzcat(cmdString, ': ', num2str(command)));
            end
            
            
        end
end

%% LOCAL FUNCTIONS
function commandMap = zlclInitCommandMap()

commandMap = containers.Map();

commandMap('MaxNumberOfDevices') = 3;                             % 48 posible Devices, 3 for faster connection

% first two bytes are the command, third is the number of following data
% bytes
% <ID byte 1><ID byte 2><cmd Arg length>
commandMap('Connect') = uint8([4, 0, 0]);
commandMap('Disconnect') = uint8([4, 1, 0]);
commandMap('KeepAlive') = uint8([4, 2, 0]);

% Keypad
commandMap('KeyPadon') = uint8([4, 44, 0]);
commandMap('KeyPadoff') = uint8([4, 45, 0]);

% Get information about connected devices
commandMap('OutputStagePresent') = uint8([1, 31, 1]);
commandMap('GetMainStatusFromOutputstage') = ([1, 32, 1]);

% axis activation/deactivation
commandMap('DeactivateAxis') = ([0, 52, 1]);
commandMap('ActivateAxis')   = ([0, 53, 1]);

% Position
commandMap('GetPosition')       = uint8([1, 1, 1]);
commandMap('SetPositionZero')   = uint8([0, 240, 1]);
commandMap('GoToPositionZero')  = uint8([0, 36, 1]);

% Movement
commandMap('GoToPositionFastAbs') = uint8([0, 72, 5]);
commandMap('GoToPositionSlowAbs') = uint8([0, 73, 5]);
commandMap('GoToPositionFastRel') = uint8([0, 74, 5]);
commandMap('GoToPositionSlowRel') = uint8([0, 75, 5]);

commandMap('GoFastPos')           = uint8([0, 18, 1]);
commandMap('GoFastNeg')           = uint8([0, 19, 1]);
commandMap('GoSlowPos')           = uint8([0, 20, 1]);
commandMap('GoSlowNeg')           = uint8([0, 21, 1]);
commandMap('Stop')                = uint8([0, 255, 1]);

% Velocity settings
commandMap('SetVelocitySlow') = uint8([0, 60, 3]);             % for positioning speed (associated Command: SM5GoToPosition...)
commandMap('SetVelocityFast') = uint8([0, 61, 3]);
commandMap('GetVelocityFast') = uint8([1, 96, 1]);
commandMap('GetVelocitySlow') = uint8([1, 97, 1]);

commandMap('SetMoveVelFast')  = uint8([1, 52, 2]);             % for general movement speed (associated Command: SM5Go...)
commandMap('SetMoveVelSlow')  = uint8([1, 53, 2]);
commandMap('GetMoveVelFast')  = uint8([1, 47, 1]);
commandMap('GetMoveVelSlow')  = uint8([1, 48, 1]);

end