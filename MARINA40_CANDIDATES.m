%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 4: CANDIDATES FOR THE TMY GENERATION BASED IN FDA DISTANCES
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUTS
% ..\OUTPUT\3_VALIDATION
%       ASP00-BOM-01.xlsx'
%           datos_dia [AÑO MES DIA VALOR_DIARIO]
%
% OUTPUT
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
clear
clc
close all
run('Configuration_BURNS.m');

[s,mess,messid] = mkdir(ruta_cases);

name     = [filedata.loc '00-' filedata.own '-' filedata.num];

file_OUT   = strcat(ruta_cases,'\',name,'-CANDIDATOS.xlsx');
file_input = strcat(ruta_cases,'\','INPUT-GENERATION.xlsx');

%Desactiva el warning de que se cree una nueva hoja excel.
warning off MATLAB:xlswrite:AddSheet

% READING THE DAILY VALUES
Val_dia = xlsread(file_IN, 'Val-dia');
colDNI=5:6:6*num_annos;
colGHI=2:6:6*num_annos;
DNI=Val_dia(:,colDNI);
GHI=Val_dia(:,colGHI);
% Voy a probar a selecionar el mes con menos cambios.
Faltan=xlsread(file_IN, 'Tabla-faltan');
Faltan(1,:)=[];

% GENERATION OF A CONSECUTIUVE DAILY TABLE
fila=0;
num_dias_mes=[31 28 31 30 31 30 31 31 30 31 30 31];
for anno=anno_ini:anno_end
    for mes=1:12
        for dia=1:num_dias_mes(mes)
            fila=fila+1;
            datos_dia(fila,1)=anno;
            datos_dia(fila,2)=mes;
            datos_dia(fila,3)=dia;      
        end
    end
end

% ADDING DAILY VALUES TO THE CONSECUTIVE TABLE
temp=reshape(DNI,[],1);
datos_dia(:,4)=temp;

% READING THE MONTHLY VALUES
Val_month = xlsread(file_IN, 'Val-mes');
colDNIcal=6:6:6*num_annos;
colGHIcal=3:6:6*num_annos;
DNI_month = Val_month(:,colDNI);
DNI_cal   = Val_month(:,colDNIcal);
GHI_cal   = Val_month(:,colGHIcal);

% EVALUATING FDA FOR EACH MONTH (ALL YEARS)
maximo=max(datos_dia(:,4));
num_int=10;
for mes=1:12
    
    pos_mes=(datos_dia(:,2)==mes);
    
    % Calculating the monthly mean
%     good_years = find(DNI_cal(mes,:) == 1 & GHI_cal(mes,:) == 1);
    good_years = find(DNI_cal(mes,:) == 1 );
    month_av(mes,1)= mean(DNI_month(mes,good_years));
    
    %removing positions of the bad years
    bad_years = find(DNI_cal(mes,:) ~=1 & GHI_cal(mes,:) ~=1);
    bad_years=bad_years+anno_ini;
    if any(bad_years)
       for bad=1:length(bad_years)
          pos_bad = (datos_dia(:,2)==mes & datos_dia(:,1)==bad_years(bad));
          pos_mes = pos_mes - pos_bad;
          clear pos_bad
       end
    end
    pos_mes=find(pos_mes); % para volver a los numeros de las posiciones
    
    FDAT_num(mes,1)=0;
    FDAT_num(mes,2)=mes;
    FDAT_num(mes,3)=0;
    FDAT_por(mes,1)=0;
    FDAT_por(mes,2)=mes;
    FDAT_por(mes,3)=0;
    [FDAT_num(mes,4:13),FDAT_por(mes,4:13)]=FDA_general(datos_dia(pos_mes,4),maximo,num_int);
end
headers{1}='0000';
headers{2}='MONTH';
headers{3}='0000';
for i=1:num_int
   headers{i+3}=strcat('int',num2str(i));
end
xlswrite(file_OUT, [headers; num2cell(FDAT_num)],'FDATotal_num');
xlswrite(file_OUT, [headers; num2cell(floor(FDAT_por*100)/100)],'FDATotal_por');


%FDA OF EACH INDIVIDUAL MONTH (EACH YEAR)
anno_ini=min(datos_dia(:,1));
anno_fin=max(datos_dia(:,1));
fila=0;
for aa=anno_ini:anno_fin
    for mes=1:12
        fila=fila+1;
        pos_mes=find( datos_dia(:,1)==aa & datos_dia(:,2)==mes);
        FDA_num(fila,1)=aa;
        FDA_num(fila,2)=mes;
        FDA_num(fila,3)=0;
        FDA_por(fila,1)=aa;
        FDA_por(fila,2)=mes;
        FDA_por(fila,3)=0;
        [FDA_num(fila,4:3+num_int),FDA_por(fila,4:3+num_int)]=FDA_general(datos_dia(pos_mes,4),maximo,num_int);
    end
end
headers{1}='YEAR';
xlswrite(file_OUT, [headers; num2cell(FDA_num)],'FDAyears_num');
xlswrite(file_OUT, [headers; num2cell(floor(FDA_por*100)/100)],'FDAyears_por');

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

for mes=1:12
    head{mes}=strcat('Month',num2str(mes));
    [valor(:,mes),pos_candidato(:,mes)]=sort(resultado(:,mes));
    CANDIDATES=pos_candidato+anno_ini-1;
    
    % TMY METHODOLGY
    % With the 5 lowerst, search the month  close to the mean
    % preselected positions in the years
    for pre=1:num_pre
       position_preselected(pre)=find(pos_years==CANDIDATES(pre,mes));
    end
    % values of the preselted months
    Preselected_values=DNI_month(mes,position_preselected);
    Diference=abs(Preselected_values-month_av(mes,1));
    selected_value = min(Diference);
    pos_selecTMY = find (Diference==selected_value);
    
    Val_selectedTMY(mes)=DNI_month(mes,position_preselected(pos_selecTMY(1)));
    Year_selectedTMY(mes)=pos_years(position_preselected(pos_selecTMY(1)));
    % almacena las FDA de la primera selección 
    FDA_sel1(mes,1)=Year_selectedTMY(mes);
    FDA_sel1(mes,2)=mes;
    FDA_sel1(mes,3)=0;
    pos1= find(FDA_por(:,1)==Year_selectedTMY(mes) & FDA_por(:,2)==mes);
    FDA_sel1_por(mes,4:13)=FDA_por(pos1,4:13);
    FDA_sel1_num(mes,4:13)=FDA_num(pos1,4:13);
    
    % LMR1 METHODOLGY
    % With the 5 lowerst, search the LESS MISSING REGORDS
    % preselected positions in the years
    % values of the preselted months
    Preselected_faltan=Faltan(mes,position_preselected);
    Min_faltan=min(Preselected_faltan);
    pos_selecLMR = find (Preselected_faltan==Min_faltan);
    
    Val_selectedLMR1(mes)=DNI_month(mes,position_preselected(pos_selecLMR(1)));
    Year_selectedLMR1(mes)=pos_years(position_preselected(pos_selecLMR(1)));
    % almacena las FDA de la primera selección 
    FDA_sel21(mes,1)=Year_selectedLMR1(mes);
    FDA_sel21(mes,2)=mes;
    FDA_sel21(mes,3)=0;
    pos2= find(FDA_por(:,1)==Year_selectedLMR1(mes) & FDA_por(:,2)==mes);
    FDA_sel21_por(mes,4:13)=FDA_por(pos2,4:13);
    FDA_sel21_num(mes,4:13)=FDA_num(pos2,4:13);
    
    clear pos1 pos2 pos22
end

% TMY METHODOLOGY
output1(1,:) = Year_selectedTMY'; %  1ST COLUMN, YEAR SELECTED
output1(2,:) = Val_selectedTMY';  %  2ND COLUMN, MONTHLY VALUE OF THE SELECTED MONTH
output1(4,:) = floor(month_av');   %4TH COLUMN, MONTHLY MEAN OF THE VALID MONTHS 
xlswrite(file_OUT, [headers; num2cell(FDA_sel1_num)],'FDA_sel1_num');
xlswrite(file_OUT, [headers; num2cell(floor(FDA_sel1_por*100)/100)],'FDA_sel1_por');
xlswrite(file_OUT, [head; num2cell(floor(valor))]','distances');
xlswrite(file_OUT, [head; num2cell(CANDIDATES)]','CANDIDATES');
xlswrite(file_OUT, [head; num2cell(output1)]','output1');
% Write the inputs for series generation
xlswrite(file_input, [{'DNI'}] ,                     'VARIABLE', 'A1');
xlswrite(file_input, [{'MONTH'} {'TMY'}],            'INPUT', 'A1');
xlswrite(file_input, [head; num2cell(output1(1,:))]','INPUT','A2');
xlswrite(file_input, [{'MONTH'} {'TMY'}],            'OBJECTIVE', 'A1');
xlswrite(file_input, [head; num2cell(output1(2,:))]','OBJECTIVE','A2');

% LMR1 METHODOLOGY
output21(1,:) = Year_selectedLMR1';  %  1ST COLUMN, YEAR SELECTED
output21(2,:) = Val_selectedLMR1';   %  2ND COLUMN, MONTHLY VALUE OF THE SELECTED MONTH
output21(4,:) = floor(month_av');   %4TH COLUMN, MONTHLY MEAN OF THE VALID MONTHS 
xlswrite(file_OUT, [headers; num2cell(FDA_sel21_num)],'FDA_sel21_num');
xlswrite(file_OUT, [headers; num2cell(floor(FDA_sel21_por*100)/100)],'FDA_sel21_por');
xlswrite(file_OUT, [head; num2cell(output21)]','output21');
% Write the inputs for series generation
xlswrite(file_input, [{'LMR'}],                 'INPUT', 'C1');
xlswrite(file_input, [num2cell(output21(1,:))]','INPUT','C2');
xlswrite(file_input, [{'LMR'}],                 'OBJECTIVE', 'C1');
xlswrite(file_input, [num2cell(output21(2,:))]','OBJECTIVE','C2');
