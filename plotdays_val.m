function [ dataDaysVal ] = plotdays_val( cfgFile, iniDay, finalDay, variables )
%PLOTDAYS_VAL Extract and plot the data after quality control process between
%two specific days of the same year
%   INPUT:
%   iniDay: Initial day for plotting.
%   finalDay: Last day for plotting.
%   variables: Logic array pointing which radiation variables will be
%   plotted [GHI DNI DHI].
%
%   OUTPUT:
%   dataDays: Array with the radiation values of the days selected
%   Figure 1: Radiation values of the selected variables along the days
%   Figures 2 - 4: Each radiation variable with its quality control flag

run(cfgFile);
path_fig = [path_out '\figures'];
if ~exist(path_fig,'dir')
    mkdir(path_fig);
end
num_previous_days = [0 cumsum(num_days_m(1:length(num_days_m)-1))]; % Number of days previous to the month start (No leap years)
% Get the data ------------------------------------------------------------
y1 = iniDay(1); m1 = iniDay(2); d1 = iniDay(3);
y2 = finalDay(1); m2 = finalDay(2); d2 = finalDay(3);
mtx2 = [];

ID1 = num2str(y1);
ID2 = num2str(y2);

path = path_val;
fileIn1 = [loc '00-' owner_station '-' num '-' ID1 '_VAL'];
fileIn2 = [loc '00-' owner_station '-' num '-' ID2 '_VAL'];

if y2==y1 % Same year
    load(strcat(path,'\',fileIn1)); % Load of the standard data structure
    mtx1 = dataval.mqc;
    
    if mod(y1,4)~=0
        leap = false; % Common year
    elseif mod(y1,100)~=0
        leap = true; % Leap year
    elseif mod(y1,400)~=0
        leap = false; % Common year
    else
        leap = true; % Leap year
    end
    
else % Several years TODO
    load(strcat(path,'\',fileIn1)); % Load of the standard data structure after QC
    mtx1 = dataval.mqc;
    load(strcat(path,'\',fileIn2)); % Load of the standard data structure
    mtx2 = dataval.mqc;
end

mtx1 = [mtx1; mtx2]; % Concatenate all years required
clear mtx2

% Look for the days wanted ------------------------------------------------
dj1 = num_previous_days(m1)+d1;
dj2 = num_previous_days(m2)+d2;
i1 = (dj1-1)*24*num_obs+1; % First instant of the selected days
i2 = dj2*24*num_obs; % Last instant of the selected days
mtx1 = mtx1(i1:i2,:);

% Select variables wanted -------------------------------------------------
colsVars = [7 9 11]; % Variables for plot [GHI DNI DHI]
colsfQC = [8 10 12];
leg = {'GHI', 'DNI', 'DHI'};
legfQC = {'GHI_fQC', 'DNI_fQC', 'DHI_fQC'};

colsVars = colsVars(variables);
colsfQC = colsfQC(variables);
leg = leg(variables);
legfQC = legfQC(variables);
legfQC = [leg; legfQC]';

dataDaysVal = mtx1(:,[1:6, colsVars colsfQC]);

% Plot
t = (datetime([iniDay 0 0 0]):minutes(60/num_obs):datetime([finalDay 23 60-60/num_obs 0]))';
if leap
    Feb29a = datetime([y1 2 29 0 0 0]); Feb29b = datetime([y1 2 29 23 60-60/num_obs 0]);
    f29 = t>=Feb29a & t<=Feb29b;
    t = t(~f29);
end
figure; plot(t,dataDaysVal(:,7:7+length(colsVars)-1)); title('Validation')
legend(leg,'Interpreter','none'), xlabel('Time'), ylabel('Irradiance [W/m2]')

[mm,~] = string_chars_num(finalDay(2),2);
[dd,~] = string_chars_num(finalDay(3),2);
date = strcat(num2str(finalDay(1)),mm,dd); module = 'val';
print('-djpeg','-opengl','-r350',strcat(path_fig,'\Radiation','_',date,'_',module))

for i = 0:length(colsVars)-1
    figure;
    yyaxis left
    plot(t,dataDaysVal(:,7+i))
    xlabel('Time'), ylabel('Irradiance [W/m2]')
    yyaxis right
    qcf = dataDaysVal(:,7+length(colsVars)+i);
    plot(t,qcf,'--'), title(strcat(leg(i+1), ' Validation'))
    ylabel('Quality Control Flag')
    set(gca,'YLim',[0 max(qcf)],'YTick',0:max(qcf))
    legend(legfQC(i+1,:),'Interpreter','none')
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',legfQC{i+1,2},'_',date,'_',module))
end

end
