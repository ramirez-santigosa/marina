%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 4: CANDIDATES FOR THE TMY GENERATION BASED IN FDA DISTANCES
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (March 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUTS
% ..\OUTPUT\3_VALIDATION
%       One Excel file per year i.e. 'ASP00-BOM-01.xlsx'
%       datos_dia [AÑO MES DIA VALOR_DIARIO]
%
% OUTPUT !!!
% ..\OUTPUT\4_CASES
%       ASP00-BOM-01-CANDIDATOS.xlsx';
%       (1) Tables with the whole data 12 rows
%           FDAT_num (value) [  0 MONTH 0 VAL_INT1 VAL_INT2 ... VAL_INT_fin]
%           FDAT_por (perct) [  0 MONTH 0 VAL_INT1 VAL_INT2 ... VAL_INT_fin]
%       (2)Tables with a row for each month
%           FDA_num (value) [YEAR MONTH 0 VAL_INT1 VAL_INT2 ... VAL_INT_fin]
%           FDA_por (perct) [YEAR MONTH 0 VAL_INT1 VAL_INT2 ... VAL_INT_fin]
%       INPUT-GENERATION.xlsx';
%        File with 3 Sheets:
%           VARIABLE:   name of the main variable in A1 (GHI / DNI)
%           INPUT:      number of the years selected for each month
%                       columns from B (B2:B13)to number of cases
%           OBJECTIVE:  values that would like to be reached for each month
%                       columns from B (B2:B13)to number of cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars, %clc
run('Configuration_BSRN_ASP.m');

if ~exist(path_cases,'dir')
    [s,mess,messid] = mkdir(path_cases);
end

num_years = year_end-year_ini+1;
namef = [loc '00-' owner_station '-' num];
file_xls = strcat(path_val,'\',namef,'.xlsx');

file_Out = strcat(path_cases,'\',namef,'-CANDIDATES.xlsx');
file_Input = strcat(path_cases,'\','INPUT-GENERATION.xlsx');

% Switch off new excel sheet warning
warning off MATLAB:xlswrite:AddSheet

%% READING THE DAILY VALUES !¿Porque no directamente de Matlab?
Val_Day = xlsread(file_xls, 'Val_Day'); % Text headers discarded
colDNId = 5:6:6*num_years;
colGHId = 2:6:6*num_years;
DNI = Val_Day(:,colDNId);
GHI = Val_Day(:,colGHId);

% Voy a probar a selecionar el mes con menos cambios.???
nReplace = xlsread(file_xls, '#_Replace');
nReplace(1,:) = []; % Trim headers (Years)

%% GENERATION OF A CONSECUTIUVE DAILY TABLE
row = 0;
num_days = [31 28 31 30 31 30 31 31 30 31 30 31];
data_day = zeros(365*num_years,4);

for y = year_ini:year_end
    for m = 1:12
        for d = 1:num_days(m)
            row = row+1;
            data_day(row,1) = y;
            data_day(row,2) = m;
            data_day(row,3) = d;
        end
    end
end

%% ADDING DAILY VALUES TO THE CONSECUTIVE TABLE
temp = reshape(DNI,[],1);
data_day(:,4) = temp;

% READING THE MONTHLY VALUES
Val_Month = xlsread(file_xls, 'Val_Month');
colDNIm = 6:6:6*num_annos;
colGHIm = 3:6:6*num_annos;
DNI_month = Val_month(:,colDNId);
DNI_cal = Val_month(:,colDNIm);
GHI_cal = Val_month(:,colGHIm);

% EVALUATING FDA FOR EACH MONTH (ALL YEARS)
maximo=max(data_day(:,4));
num_int=10;
for m=1:12
    
    pos_mes=(data_day(:,2)==m);
    
    % Calculating the monthly mean
    %     good_years = find(DNI_cal(mes,:) == 1 & GHI_cal(mes,:) == 1);
    good_years = find(DNI_cal(m,:) == 1 );
    month_av(m,1)= mean(DNI_month(m,good_years));
    
    %removing positions of the bad years
    bad_years = find(DNI_cal(m,:) ~=1 & GHI_cal(m,:) ~=1);
    bad_years=bad_years+anno_ini;
    if any(bad_years)
        for bad=1:length(bad_years)
            pos_bad = (data_day(:,2)==m & data_day(:,1)==bad_years(bad));
            pos_mes = pos_mes - pos_bad;
            clear pos_bad
        end
    end
    pos_mes=find(pos_mes); % para volver a los numeros de las posiciones
    
    FDAT_num(m,1)=0;
    FDAT_num(m,2)=m;
    FDAT_num(m,3)=0;
    FDAT_por(m,1)=0;
    FDAT_por(m,2)=m;
    FDAT_por(m,3)=0;
    [FDAT_num(m,4:13),FDAT_por(m,4:13)]=FDA_general(data_day(pos_mes,4),maximo,num_int);
end
headers{1}='0000';
headers{2}='MONTH';
headers{3}='0000';
for i=1:num_int
    headers{i+3}=strcat('int',num2str(i));
end
xlswrite(file_Out, [headers; num2cell(FDAT_num)],'FDATotal_num');
xlswrite(file_Out, [headers; num2cell(floor(FDAT_por*100)/100)],'FDATotal_por');


%FDA OF EACH INDIVIDUAL MONTH (EACH YEAR)
anno_ini=min(data_day(:,1));
anno_fin=max(data_day(:,1));
row=0;
for aa=anno_ini:anno_fin
    for m=1:12
        row=row+1;
        pos_mes=find( data_day(:,1)==aa & data_day(:,2)==m);
        FDA_num(row,1)=aa;
        FDA_num(row,2)=m;
        FDA_num(row,3)=0;
        FDA_por(row,1)=aa;
        FDA_por(row,2)=m;
        FDA_por(row,3)=0;
        [FDA_num(row,4:3+num_int),FDA_por(row,4:3+num_int)]=FDA_general(data_day(pos_mes,4),maximo,num_int);
    end
end
headers{1}='YEAR';
xlswrite(file_Out, [headers; num2cell(FDA_num)],'FDAyears_num');
xlswrite(file_Out, [headers; num2cell(floor(FDA_por*100)/100)],'FDAyears_por');

disp('Candidates selected!!');

% GENERATION OF MAIN OUTPUT TABLES (VALUES, CANDIDATES)
libro_por=reshape(FDA_por(:,4:3+num_int)',num_int,12,[]);
[a,b,c]=size(libro_por);
for i=1:c
    hoja=libro_por(:,:,i)';
    resta(:,1:num_int,i)=abs(hoja-FDAT_por(:,4:3+num_int));
    suma_mes(:,:,i)=sum(resta(:,:,i),2);
    resultado(i,:)=suma_mes(:,:,i)';
end
pos_years=[anno_ini:anno_fin];

for m=1:12
    head{m}=strcat('Month',num2str(m));
    [valor(:,m),pos_candidato(:,m)]=sort(resultado(:,m));
    CANDIDATES=pos_candidato+anno_ini-1;
    
    % TMY METHODOLGY
    % With the 5 lowerst, search the month  close to the mean
    % preselected positions in the years
    for pre=1:num_pre
        position_preselected(pre)=find(pos_years==CANDIDATES(pre,m));
    end
    % values of the preselted months
    Preselected_values=DNI_month(m,position_preselected);
    Diference=abs(Preselected_values-month_av(m,1));
    selected_value = min(Diference);
    pos_selecTMY = find (Diference==selected_value);
    
    Val_selectedTMY(m)=DNI_month(m,position_preselected(pos_selecTMY(1)));
    Year_selectedTMY(m)=pos_years(position_preselected(pos_selecTMY(1)));
    % almacena las FDA de la primera selección
    FDA_sel1(m,1)=Year_selectedTMY(m);
    FDA_sel1(m,2)=m;
    FDA_sel1(m,3)=0;
    pos1= find(FDA_por(:,1)==Year_selectedTMY(m) & FDA_por(:,2)==m);
    FDA_sel1_por(m,4:13)=FDA_por(pos1,4:13);
    FDA_sel1_num(m,4:13)=FDA_num(pos1,4:13);
    
    % LMR1 METHODOLGY
    % With the 5 lowerst, search the LESS MISSING REGORDS
    % preselected positions in the years
    % values of the preselted months
    Preselected_faltan=nReplace(m,position_preselected);
    Min_faltan=min(Preselected_faltan);
    pos_selecLMR = find (Preselected_faltan==Min_faltan);
    
    Val_selectedLMR1(m)=DNI_month(m,position_preselected(pos_selecLMR(1)));
    Year_selectedLMR1(m)=pos_years(position_preselected(pos_selecLMR(1)));
    % almacena las FDA de la primera selección
    FDA_sel21(m,1)=Year_selectedLMR1(m);
    FDA_sel21(m,2)=m;
    FDA_sel21(m,3)=0;
    pos2= find(FDA_por(:,1)==Year_selectedLMR1(m) & FDA_por(:,2)==m);
    FDA_sel21_por(m,4:13)=FDA_por(pos2,4:13);
    FDA_sel21_num(m,4:13)=FDA_num(pos2,4:13);
    
    clear pos1 pos2 pos22
end

% TMY METHODOLOGY
output1(1,:) = Year_selectedTMY'; %  1ST COLUMN, YEAR SELECTED
output1(2,:) = Val_selectedTMY';  %  2ND COLUMN, MONTHLY VALUE OF THE SELECTED MONTH
output1(4,:) = floor(month_av');   %4TH COLUMN, MONTHLY MEAN OF THE VALID MONTHS
xlswrite(file_Out, [headers; num2cell(FDA_sel1_num)],'FDA_sel1_num');
xlswrite(file_Out, [headers; num2cell(floor(FDA_sel1_por*100)/100)],'FDA_sel1_por');
xlswrite(file_Out, [head; num2cell(floor(valor))]','distances');
xlswrite(file_Out, [head; num2cell(CANDIDATES)]','CANDIDATES');
xlswrite(file_Out, [head; num2cell(output1)]','output1');
% Write the inputs for series generation
xlswrite(file_Input, [{'DNI'}] ,                     'VARIABLE', 'A1');
xlswrite(file_Input, [{'MONTH'} {'TMY'}],            'INPUT', 'A1');
xlswrite(file_Input, [head; num2cell(output1(1,:))]','INPUT','A2');
xlswrite(file_Input, [{'MONTH'} {'TMY'}],            'OBJECTIVE', 'A1');
xlswrite(file_Input, [head; num2cell(output1(2,:))]','OBJECTIVE','A2');

% LMR1 METHODOLOGY
output21(1,:) = Year_selectedLMR1';  %  1ST COLUMN, YEAR SELECTED
output21(2,:) = Val_selectedLMR1';   %  2ND COLUMN, MONTHLY VALUE OF THE SELECTED MONTH
output21(4,:) = floor(month_av');   %4TH COLUMN, MONTHLY MEAN OF THE VALID MONTHS
xlswrite(file_Out, [headers; num2cell(FDA_sel21_num)],'FDA_sel21_num');
xlswrite(file_Out, [headers; num2cell(floor(FDA_sel21_por*100)/100)],'FDA_sel21_por');
xlswrite(file_Out, [head; num2cell(output21)]','output21');
% Write the inputs for series generation
xlswrite(file_Input, [{'LMR'}],                 'INPUT', 'C1');
xlswrite(file_Input, [num2cell(output21(1,:))]','INPUT','C2');
xlswrite(file_Input, [{'LMR'}],                 'OBJECTIVE', 'C1');
xlswrite(file_Input, [num2cell(output21(2,:))]','OBJECTIVE','C2');
