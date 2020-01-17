clc; clear;

serverId = 247;
readAddress = 49;
writeAddress = 50;
baudRate = 115200;
parity = 'even';
precision = 'uint16';

obj = proportionAirModbus('serialrtu', '/dev/cu.usbserial-FT3NO6ER1', 'BaudRate', baudRate, 'Parity', parity, 'Timeout', .1);

write(obj,'holdingregs', writeAddress, 16000, serverId, precision)

read(obj,'holdingregs', readAddress, 1, serverId, precision)