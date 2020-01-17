classdef Modbus < instrument.interface.modbus.serialrtu.Modbus
%MODBUS Construct a MODBUS Serial RTU communication object.
            
    %% Constructor
    methods (Hidden)
        function obj = Modbus (varargin)
            % call through to the base class            
            obj@instrument.interface.modbus.serialrtu.Modbus(varargin{:});
            
            %overwrite the PacketBuilder with our own so we can modify the
            %behavior
            obj.PacketBuilder = proportionair.interface.modbus.serialrtu.PacketBuilder(obj.Converter);
        end                      
    end        
end

