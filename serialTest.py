#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 11 18:38:12 2019

@author: williamstoy
"""

import serial
import modbus_tk.defines as tkCst
import modbus_tk.modbus_rtu as tkRtu

def convertPressureToCommand(pressure = 0):
	#cmd = int(39.198*pressure + 27026) # Channel 1
	cmd = int(39.21*pressure + 27041) # CHannel 2
	#cmd = int(39.288*pressure + 27272) # Channel 3
	#cmd = int(39.183*pressure + 27034) # Channel 4
	
	#cmd = int(39.197*pressure + 27032) # AVERAGE OF CHANNEL 1, 2, and 4 (3 is off)
	
	cmd = 0 if cmd < 0 else cmd
	cmd = 65535 if cmd > 65535 else cmd
	return cmd

slaveId = 247
iterSp = 100
regsSp = 10
portName = '/dev/cu.usbserial-FT3NO6ER1'
baudrate = 115200

pressure = -600;

timeoutSp=0.018 + regsSp*0
print("timeout: %s [s]" % timeoutSp)

tkmc = tkRtu.RtuMaster(serial.Serial(port=portName, baudrate=baudrate, parity=serial.PARITY_EVEN))
tkmc.set_timeout(timeoutSp)

print(tkmc.execute(slave=slaveId, function_code=tkCst.WRITE_MULTIPLE_REGISTERS, starting_address=49, output_value=[convertPressureToCommand(pressure)]))

tkmc.close()