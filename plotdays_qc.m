function [ dataDaysQC ] = plotdays_qc( iniDay, finalDay, variables )
%PLOTDAYS Extract and plot the data after quality control process between
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

run('Configuration_BSRN_ASP.m');
path_fig = '..\OUTPUT\figures';
if ~exist(path_fig,'dir')
    mkdir(path_fig);
end

% Get the data ------------------------------------------------------------
y1 = iniDay(1);
y2 = finalDay(1);
mtx2 = [];

ID1 = num2str(y1);
ID2 = num2str(y2);

path = path_qc;
fileIn1 = [loc '00-' owner_station '-' num '-' ID1 '_QC'];
fileIn2 = [loc '00-' owner_station '-' num '-' ID2 '_QC'];

if y2==y1 % Same year
    load(strcat(path,'\',fileIn1)); % Load of the standard data structure
    mtx1 = dataqc.mqc;
else % Several years TODO
    load(strcat(path,'\',fileIn1)); % Load of the standard data structure after QC
    mtx1 = dataqc.mqc;
    load(strcat(path,'\',fileIn2)); % Load of the standard data structure
    mtx2 = dataqc.mqc;
end

mtx1 = [mtx1; mtx2]; % Concatenate all years required
clear mtx2

% Look for the days wanted ------------------------------------------------
dj1 = datenum(iniDay)-datenum([y1 1 1])+1; % Init day in the year
dj2 = datenum(finalDay)-datenum([y2 1 1])+1; % Final day in the year
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

dataDaysQC = mtx1(:,[1:6, colsVars colsfQC]);

% Plot
t = datetime(dataDaysQC(:,1:6));
figure; plot(t,dataDaysQC(:,7:7+length(colsVars)-1)); title('Quality Control')
legend(leg,'Interpreter','none'), xlabel('Time'), ylabel('Irradiance [W/m2]')

[mm,~] = string_chars_num(finalDay(2),2);
[dd,~] = string_chars_num(finalDay(3),2);
date = strcat(num2str(finalDay(1)),mm,dd); module = 'qc';
print('-djpeg','-opengl','-r350',strcat(path_fig,'\Radiation','_',date,'_',module))

for i = 0:length(colsVars)-1
    figure;
    yyaxis left
    plot(t,dataDaysQC(:,7+i))
    xlabel('Time'), ylabel('Irradiance [W/m2]')
    yyaxis right
    qcf = dataDaysQC(:,7+length(colsVars)+i);
    plot(t,qcf,'--'), title(strcat(leg(i+1), ' Quality Control'))
    ylabel('Quality Control Flag')
    set(gca,'YLim',[0 max(qcf)],'YTick',0:max(qcf))
    legend(legfQC(i+1,:),'Interpreter','none')
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',legfQC{i+1,2},'_',date,'_',module))
end

end
