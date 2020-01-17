classdef (Hidden) PacketBuilder < instrument.interface.modbus.serialrtu.PacketBuilder
    %PACKETBUILDER Builds Modbus Serial RTU request packets
    
    % Copyright 2016 The MathWorks, Inc.
    
    %% Constructor
    methods
        function obj = PacketBuilder(converter)
            % call throught to base class
            obj@instrument.interface.modbus.serialrtu.PacketBuilder(converter);
        end
    end
    
    methods (Access = protected)
        function modbusPDU = createWritePDUframe(obj, writeTarget, startAddress, values, serverId)
            % Create and return the base MODBUS PDU request frame for a
            % write operation.
            
            fcnCode = obj.WriteMultipleRegs;         
            [modbusPDU, index] = obj.createBasePDUframe(fcnCode, startAddress, serverId);
            
            if (isequal(fcnCode,5) || isequal(fcnCode,6))
                % Write single coil or register
                valBytes = obj.Converter.word2bytes(values(1)); 
                modbusPDU = obj.addBytes(modbusPDU, index, valBytes);
            else                          
                % Write multiple coils or registers

                % Add count, either number of coils, or number of registers
                count = length(values);
                cntBytes = obj.Converter.word2bytes(count); 
                [modbusPDU,index] = obj.addBytes(modbusPDU, index, cntBytes);
                byteCount = count * 2;
                
                % If write multiple coils
                if (isequal(fcnCode, 15)) 
                    % Convert coil bits to bytes
                    values = obj.Converter.packBits(values);
                    % Update count
                    count = length(values);
                    byteCount = count;
                    % Add byte count and values                
                    modbusPDU(index) = byteCount;   
                    index = index + 1;
                    modbusPDU = obj.addBytes(modbusPDU, index, values);
                else
                    % else write multiple registers
                    % Add byte count and values                
                    modbusPDU(index) = byteCount;   
                    index = index + 1;                    

                    for idx = 1:count
                        valBytes = obj.Converter.word2bytes(values(idx)); 
                        [modbusPDU,index] = obj.addBytes(modbusPDU, index, valBytes);
                    end
                end
            end
        end         
    end
    
    methods (Access = private)
    
        function [modbusPDU, index] = createBasePDUframe(obj, fcnCode, startAddress, serverId)
            % Create and return the base MODBUS PDU request frame                        
            
            % In the PDU coils inputs and registers are addressed starting
            % at zero. eg. coils numbered 1-16 are addressed as 0-15.
            startAddress = startAddress - 1;
            
            index = 1;
            modbusPDU = zeros(1,6,'uint8');
            modbusPDU(index) = serverId;
            index = index + 1;
            modbusPDU(index) = fcnCode;
            index = index + 1;
            % Start address
            addrBytes = obj.Converter.word2bytes(startAddress);            
            modbusPDU(index) = addrBytes(1);
            index  = index +1;
            modbusPDU(index) = addrBytes(2);
            index  = index +1;                                        
        end
       
        function code = getReadFunctionCode(obj, target)
            % Returns the MODBUS function code for the
            % specified target.
            idx = strcmp(obj.ReadTargets, target);
            code = obj.ReadFcnCodes(idx);            
        end                          
    end
end

