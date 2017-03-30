function [ dataDays ] = plotdays( iniDay, finalDay, variables )
%PLOTDAYS Extract and plot the data between two specific days
%   Detailed explanation goes here

run('Configuration_BSRN_ASP.m');

% Get the data ------------------------------------------------------------
y1 = iniDay(1);
y2 = finalDay(1);
mqc2 = [];

path = path_qc;
    
if y2==y1 % Same year
    ID1 = num2str(y1);
    fileInQC1 = [loc '00-' owner_station '-' num '-' ID1 '_QC'];
    load(strcat(path,'\',fileInQC1)); % Load of the standard data structure
    mqc1 = dataqc.mqc;
else % Several years TODO
    ID1 = num2str(y1);
    ID2 = num2str(y2);
    fileInQC1 = [loc '00-' owner_station '-' num '-' ID1 '_QC'];
    fileInQC2 = [loc '00-' owner_station '-' num '-' ID2 '_QC'];
    load(strcat(path,'\',fileInQC1)); % Load of the standard data structure after QC
    mqc1 = dataqc.mqc;
    load(strcat(path,'\',fileInQC2)); % Load of the standard data structure
    mqc2 = dataqc.mqc;
end

mqc1 = [mqc1; mqc2]; % Concatenate all years required
clear mqc2

% Look for the days wanted ------------------------------------------------
i1 = mqc1(:,1:3)==iniDay; i1 = i1(:,1) & i1(:,2) & i1(:,3);
i2 = mqc1(:,1:3)==finalDay; i2 = i2(:,1) & i2(:,2) & i2(:,3);
indexDay = i1|i2;
i1 = find(indexDay,1,'first'); % First instant of the selected days
i2 = find(indexDay,1,'last'); % Last instant of the selected days
mqc1 = mqc1(i1:i2,:);

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

dataDays = mqc1(:,[1:6, colsVars colsfQC]);

% Plot
t = datetime(dataDays(:,1:6));
plot(t,dataDays(:,7:7+length(colsVars)-1));
legend(leg)
print('-djpeg','-opengl','-r350','..\OUTPUT\2_QC\RadiationDay')

for i = 0:length(colsVars)-1
    figure;
    plotyy(t,dataDays(:,7+i),t,dataDays(:,7+length(colsVars)+i))
    legend(legfQC(i+1,:))
    print('-djpeg','-opengl','-r350',strcat('..\OUTPUT\2_QC\',legfQC{i+1,2}))
end

end
