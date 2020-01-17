clc; clear; close all;

m = modbus('serialrtu', '/dev/cu.usbserial-FT3NO6ER1', 'BaudRate', 115200, 'Parity', 'even', 'Timeout', .1);

figure;
h = animatedline;
ax = gca;
ax.YGrid = 'on';
ylabel('Pressure (mbar)');

startTime = datetime('now');

for i = 1:1000
    try
        data = read(m,'holdingregs', 49, 1, 247, 'uint16');
        pressure = (data - 27041)/39.21;
        t =  datetime('now') - startTime;
        % Add points to animation
        addpoints(h,datenum(t),pressure)
        % Update axes
        ax.XLim = datenum([t-seconds(15) t]);
        datetick('x','keeplimits')
        drawnow;
    
    catch error
       disp(error.identifier);
    end
end