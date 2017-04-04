function [ dataDays ] = plotdays( iniDay, finalDay, variables, mode )
%PLOTDAYS Extract and plot the data between two specific days of the same
%year
%   INPUT:
%   iniDay: Initial day for plotting.
%   finalDay: Last day for plotting.
%   variables: Logic array pointing which radiation variables will be
%   plotted [GHI DNI DHI]
%   mode: 'qc' or 'val' for plotting data after Quality Control or
%   Validation processes. Useful to identify interpolated data during the
%   validation process
%
%   OUTPUT:
%   dataDays: Array with the radiation values of the days selected
%   Figure 1: Radiation values of the selected variables along the days
%   Figures 2 - 4: Each radiation variable with its quality control flag

run('Configuration_BSRN_ASP.m');

% Get the data ------------------------------------------------------------
y1 = iniDay(1);
y2 = finalDay(1);
mtx2 = [];

ID1 = num2str(y1);
ID2 = num2str(y2);

switch mode
    case 'qc'
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
    case 'val'
        path = path_val;
        fileIn1 = [loc '00-' owner_station '-' num '-' ID1 '_VAL'];
        fileIn2 = [loc '00-' owner_station '-' num '-' ID2 '_VAL'];
        if y2==y1 % Same year
            load(strcat(path,'\',fileIn1)); % Load of the standard data structure
            mtx1 = dataval.mqc;
        else % Several years TODO
            load(strcat(path,'\',fileIn1)); % Load of the standard data structure after QC
            mtx1 = dataval.mqc;
            load(strcat(path,'\',fileIn2)); % Load of the standard data structure
            mtx2 = dataval.mqc;
        end
    otherwise
        error('Mode %s is not valid. Please use ''qc'' or ''val'' modes.', mode)
end

mtx1 = [mtx1; mtx2]; % Concatenate all years required
clear mqc2

% Look for the days wanted ------------------------------------------------
i1 = mtx1(:,1:3)==iniDay; i1 = i1(:,1) & i1(:,2) & i1(:,3);
i2 = mtx1(:,1:3)==finalDay; i2 = i2(:,1) & i2(:,2) & i2(:,3);
indexDay = i1|i2;
i1 = find(indexDay,1,'first'); % First instant of the selected days
i2 = find(indexDay,1,'last'); % Last instant of the selected days
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

dataDays = mtx1(:,[1:6, colsVars colsfQC]);

% Plot
t = datetime(dataDays(:,1:6));
figure; plot(t,dataDays(:,7:7+length(colsVars)-1));
legend(leg,'Interpreter','none')

[mm,~] = string_chars_num(finalDay(2),2);
[dd,~] = string_chars_num(finalDay(3),2);
date = strcat(num2str(finalDay(1)),mm,dd);
print('-djpeg','-opengl','-r350',strcat('..\OUTPUT\Radiation','_',mode,'_',date))

for i = 0:length(colsVars)-1
    figure;
    plotyy(t,dataDays(:,7+i),t,dataDays(:,7+length(colsVars)+i))
    legend(legfQC(i+1,:),'Interpreter','none')
    print('-djpeg','-opengl','-r350',strcat('..\OUTPUT\',legfQC{i+1,2},'_',mode,'_',date))
end

end
