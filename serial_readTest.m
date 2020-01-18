clc; clear; close all;

serverId = 247;
readAddress = 49;
writeAddress = 50;
baudRate = 115200;
parity = 'even';
precision = 'uint16';

m1 = proportionAirModbus('serialrtu', '/dev/cu.usbserial-FT3NO6ER0', 'BaudRate', baudRate, 'Parity', parity, 'Timeout', .1);
m2 = proportionAirModbus('serialrtu', '/dev/cu.usbserial-FT3NO6ER1', 'BaudRate', baudRate, 'Parity', parity, 'Timeout', .1);
m3 = proportionAirModbus('serialrtu', '/dev/cu.usbserial-FT3NO6ER2', 'BaudRate', baudRate, 'Parity', parity, 'Timeout', .1);
m4 = proportionAirModbus('serialrtu', '/dev/cu.usbserial-FT3NO6ER3', 'BaudRate', baudRate, 'Parity', parity, 'Timeout', .1);

handles = [m1 m2 m3 m4];

COMMAND = 10000;

figure;
subplot(4,1,1);
h_pressure1 = animatedline('Color','m','LineWidth',3);
h_cmd1 = animatedline('Color','g','LineWidth',5);
ax1 = gca;
ax1.YGrid = 'on';
ylabel('Pressure Value');

subplot(4,1,2);
h_pressure2 = animatedline('Color','m','LineWidth',3);
h_cmd2 = animatedline('Color','g','LineWidth',5);
%h2 = animatedline;
ax2 = gca;
ax2.YGrid = 'on';
ylabel('Pressure Value');

subplot(4,1,3);
h_pressure3 = animatedline('Color','m','LineWidth',3);
h_cmd3 = animatedline('Color','g','LineWidth',5);
%h2 = animatedline;
ax3 = gca;
ax3.YGrid = 'on';
ylabel('Pressure Value');

subplot(4,1,4);
h_pressure4 = animatedline('Color','m','LineWidth',3);
h_cmd4 = animatedline('Color','g','LineWidth',5);
%h2 = animatedline;
ax4 = gca;
ax4.YGrid = 'on';
ylabel('Pressure Value');

startTime = datetime('now');

prevNow =  datetime('now');
randWaitTime = 10;
calibCMD = 0;

write(handles(4),'holdingregs', writeAddress, calibCMD, serverId, precision);

while true
    try
        now =  datetime('now');
        %getDataAndPlot(handles(1),ax1, h_pressure1, h_cmd1, startTime);
        %getDataAndPlot(handles(2),ax2, h_pressure2, h_cmd2, startTime);
        %getDataAndPlot(handles(3),ax3, h_pressure3, h_cmd3, startTime);
        getDataAndPlot(handles(4),ax4, h_pressure4, h_cmd4, startTime);
        
        if(posixtime(now) - posixtime(prevNow) > 10)
            write(handles(4),'holdingregs', writeAddress, calibCMD, serverId, precision);
            ylabel(num2str(calibCMD));
            prevNow = now;
            calibCMD = calibCMD + 4000;
            
            beep; 
            
            if(calibCMD > 65535)
                break;
            end
        end
        % wait a random amount of time between  pressure changes
%         if(posixtime(now) - posixtime(prevNow) > randWaitTime)
%             write(handles(randi([1,4])),'holdingregs', writeAddress, randi([0,65535]), serverId, precision);
%             prevNow = now;
%             randWaitTime = randi([5,15]);
%             disp('changing pressure');
%         end
    catch error
       disp(error);
       break;
    end
end


function getDataAndPlot(m,ax, h_pressure, h_cmd, startTime)
    t =  datetime('now') - startTime;
    
    data = read(m,'holdingregs', 49, 2, 247, 'uint16');
    pressure = data(1);
    command = data(2);
    
    addpoints(h_pressure,datenum(t),pressure);
    addpoints(h_cmd,datenum(t),command);
    
    ax.XLim = datenum([t-seconds(15) t]);
    datetick('x','keeplimits')
    drawnow;
end