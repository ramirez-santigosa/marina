%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 5: THE TMY SERIES GENERATION
% Version of July, 2015. L. Ramírez; At CSIRO.
% Update F. Mendoza (April 2017) at CIEMAT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
% ..\OUTPUT\4_CASES
%       INPUT-GENERATION.xlsx
%
% OUTPUT: !!!!
% ..\OUTPUT\4_TMY
%  (1) OUTPUT-GENERACION (3 sheets by case)
%        sheet CASE_Dini   initial daily values
%        sheet CASE_Dfin   final daily values
%        sheet CASE_M      final monthly values
% ..\OUTPUT\4_TMY\CASE
%  (2) TMY-ASTRI-CASE.TXT
%        txt file: aaaa mm dd hh MM SS GHI eGHI DNI eDNI DHI eDNI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close, clearvars, %clc
run('Configuration_BSRN_ASP.m');

if ~exist(path_cases,'dir')
    mkdir(path_tmy);
end

name = [loc '00-' owner_station '-' num]; % MATLAB file with the results after validation
filename_val = strcat(path_val,'\',name,'.xlsx'); % Validation results
filename_input = strcat(path_cases,'\','INPUT-GENERATION.xlsx'); % Input Generation

% Reading data of the input series generation file
[~,variable] = xlsread(filename_input,'VARIABLE','A1'); % Read main variable

if strcmp(variable,'GHI')
    cols_main = 1:3;
elseif strcmp(variable,'DNI')
    cols_main = 4:6;
else
    warning(strcat('Main variable is not identifiable in Excel file ',...
        filename_input,' and sheet VARIABLE.'))
end

% Read the years of the selected months to be concatenated and the name of the series
[series,~,raw] = xlsread(filename_input,'INPUT');
% Read objective data for series generation
month_objective = xlsread(filename_input,'OBJECTIVE');

num_series = size(series,2); % Number of columns/series to generate

for i=1:num_series
    
    Series_months = [];
    days_months = [];
    values_months = [];
    
    Series_output = [];
    days_output = [];
    
    name_series = raw{1,i+1};
    path_series = strcat(path_tmy,'\',name_series);
    if ~exist(path_series,'dir')
        mkdir(path_series);
    end
    
    path_fig = strcat(path_series,'\','figures');
    if ~exist(path_fig,'dir')
        mkdir(path_fig);
    end
    
    fprintf('Generating the %s serie for simulation \n',name_series);
    
    for m = 1:12 % Extraction of the series values
        
        year = series(m,i); % Get the number of the year to read the file
        
        % Data structure with the validated data
        load(strcat(path_val,'\',name,'-',num2str(year),'_VAL'));
        num_obs = dataval.timedata.num_obs;
        data = dataval.mqc;
        
        if m == 1 % ¿Porque enero? !!!
            cosZ = dataval.astro(:,8);
        end
        
        row_ini = num_days_prev(m)*24*num_obs+1;
        row_end = row_ini+(num_dias_mes(m)*24*num_obs)-1;
        
        SERIES_mes=data(row_ini:row_end,:);
        Series_months=[Series_months;SERIES_mes];
        
        % EXTRACCIÓN DE VALORES DIARIOS
        dias_mes=[];
        [dias_annos, texto]=xlsread(filename_val,'Val-dia');
        anno_ini=str2num(texto{1,1}(1:4));
        anno_fin=str2num(texto{1,end}(1:4));
        annos=[anno_ini:anno_fin];
        numb=find(annos==year);
        
        col_ini=1+6*(numb-1);
        col_fin=col_ini+5;
        
        fil_ini=num_days_prev(m)+1; %los datos empiezan en la fila 2
        fil_fin=fil_ini+(num_dias_mes(m))-1;
        
        dias_mes=dias_annos(fil_ini:fil_fin,col_ini:col_fin);
        days_months=[days_months;dias_mes];
        
        % EXTRACCIÓN DE LOS VALORES MENSUALES
        valores_mes=[];
        meses_annos=xlsread(filename_val,'Val-mes');
        fil=m;
        
        valores_mes=meses_annos(fil,col_ini:col_fin);
        values_months=[values_months;valores_mes];
        
        %CALCULA LOS CAMBIOS DE DÍAS
        A=dias_mes(:,[1 cols_main(2)]);
        A(:,2)=A(:,2)/1000;
        
        valor_mes=values_months(m,cols_main(2));
        VMO=month_objective(m,i);
        
        if valor_mes <= VMO
            [resultado,usados,cambiados,contador,control]...
                =Cambia_dias_sube(m,A,VMO,max_cambios,dist_dias,max_uso);
        elseif valor_mes > VMO
            [resultado,usados,cambiados,contador,control]...
                =Cambia_dias_baja(m,A,VMO,max_cambios,dist_dias,max_uso);
        end
        final.resultado{i,m}=resultado;
        final.usados{i,m}=usados;
        final.cambiados{i,m}= cambiados;
        final.contador{i,m}=contador;
        final.control{i,m}=control;
        
        SERIES_sal=SERIES_mes;
        dias_sal=dias_mes;
        valores_sal(m,1:2)=valores_mes([2 5]);
        % Aplica los cambios de días a las series
        if contador<=max_cambios
            Dias_input=resultado(:,end-1);
            Dias_ord=1:num_dias_mes(m);
            cambiados=Dias_input~=Dias_ord';
            pos_dias_fin=find(cambiados); % posiciones de los cambiados
            dias_origen=Dias_input(pos_dias_fin);
            for numb=1:numel(pos_dias_fin)
                Inicio_dia_fin=1+(pos_dias_fin(numb)-1)*24*num_obs;
                Fin_dia_fin=Inicio_dia_fin+24*num_obs-1;
                
                Inicio_dia_origen=1+(dias_origen(numb)-1)*24*num_obs;
                Fin_dia_origen=Inicio_dia_origen+24*num_obs-1;
                
                SERIES_sal(Inicio_dia_fin:Fin_dia_fin,:)=SERIES_mes(Inicio_dia_origen:Fin_dia_origen,:);
                
                dias_sal(pos_dias_fin(numb),:)=dias_mes(dias_origen(numb),:);
            end
        end
        
        Series_output=[Series_output;SERIES_sal];
        days_output=[days_output;dias_sal];
        
        valores_sal(m,1)=sum(dias_sal(:,2))/1000;
        valores_sal(m,2)=sum(dias_sal(:,5))/1000;
    end
    
    objetivo_meses=round(month_objective(:,i));
    
    
    output_series(:,:,i)=Series_output;
    
    %---------------------------------------
    [output_series_int,num_out]=interpolating_holes(output_series,cosZ);
    
    %---------------------------------------
    %Guarda los valores del año FINAL
    
    %Desactiva el warning de que se cree una nueva hoja excel.
    warning off MATLAB:xlswrite:AddSheet
    
    %Escribe los valores DIARIOS del año seleccionado
    xlswrite(filename_out,days_months,strcat(name_series,'_Dini'),'A1');
    %Escribe los valores DIARIOS del año FINAL
    xlswrite(filename_out,days_output,strcat(name_series,'_Dfin'),'A1');
    
    %Escribe los valores MENSUALES del año seleccionado, OB y FIN
    xlswrite(filename_out,[{'YEARini'},{'GHIini'},{'DNIini'},{'OBJ'},{''},{'GHIend'},{'DNIend'},{'Cambios'}],...
        strcat(name_series,'_M'),'A1');
    % initial year by month
    xlswrite(filename_out,series(:,i),strcat(name_series,'_M'),'A2');
    % initial values of GHi and DNI by month
    xlswrite(filename_out,values_months(:,[2 5]),strcat(name_series,'_M'),'B2');
    % objetives (DNI) by each month
    xlswrite(filename_out,objetivo_meses,strcat(name_series,'_M'),'D2');
    % final values
    xlswrite(filename_out,round(valores_sal),strcat(name_series,'_M'),'F2');
    % final cambios
    xlswrite(filename_out,final.contador',strcat(name_series,'_M'),'H2');
    
    %---------------------------------------
    % export to txt file
    fprintf('Generating the TXT %s serie for simulation \n',name_series);
    
    % TXT of original Series (num_obs)
    fileID = fopen(strcat(path_series,'\','MY_',name_series,'.txt'),'w');
    header{1} = 'YEAR'; header{2}= 'MONTH';  header{3}= 'DAY';
    header{4} = 'HOUR'; header{5}= 'MINUTE'; header{6}= 'SECOND';
    header{7} = 'GHI(wh/m2)'; header{8}=  'eGHI';
    header{9} = 'DNI(wh/m2)'; header{10}= 'eDNI';
    header{11}= 'DHI(wh/m2)'; header{12}= 'eDHI';
    for col=1:11
        fprintf(fileID,'%10s\t',header{col});
    end
    fprintf(fileID,'%10s\r\n',header{12});
    fprintf(fileID,...
        '%10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\r\n',...
        output_series_int(:,:,i)');
    fclose(fileID);
    
    %     % Plotting solar radiation outputs
    %     figure;
    %     plot(output_series_int(:,7,i) ,'-b')
    %     axis([1 525600 0 1600]); grid on;
    %     title(['(' nombre_serie ') - GHI' ],'Fontsize',16);
    %     xlabel('Observations','Fontsize',16);
    %     ylabel('Wh/m^2','Fontsize',16);
    %     filename=strcat(nombre_serie,'-GHI');
    %     print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',filename))
    %
    %     figure;
    %     plot(output_series_int(:,9,i) ,'-r')
    %     axis([1 525600 0 1600]); grid on;
    %     title(['(' nombre_serie ') - DNI' ],'Fontsize',16);
    %     xlabel('Observations','Fontsize',16);
    %     ylabel('Wh/m^2','Fontsize',16);
    %     filename=strcat(nombre_serie,'-DNI');
    %     print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',filename))
    %
    %     figure;
    %     plot(output_series_int(:,11,i),'-c')
    %     axis([1 525600 0 1000]); grid on;
    %     title(['(' nombre_serie ') - DHI' ],'Fontsize',16);
    %     xlabel('Observations','Fontsize',16);
    %     ylabel('Wh/m^2','Fontsize',16);
    %     filename=strcat(nombre_serie,'-DHI');
    %     print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',filename))
    %     close all
    %     num=0;
    %
    %     for mes=1:12
    %         for dia=1:num_dias_mes(mes)
    %
    %             num=num+1;
    %             inicio=(num-1)*24*num_obs+1;
    %             fin =(num)*24*num_obs;
    %
    %             trozo = output_series_int(inicio:fin,:,i);
    %
    %             anno_str= num2str(trozo(1,1));
    %             mes_str = num2str(mes);
    %             dia_str = num2str(dia);
    %
    %             i0=datosval.astro(inicio:fin,9);
    %             hora = trozo(:,4);
    %             min =  trozo(:,5 );
    %             horadec = hora + min./60;
    %             GHI = trozo(:,7 );
    %             DNI = trozo(:,9 );
    %             DHI = trozo(:,11);
    %
    %             figure
    %
    %             fecha_str=['Month ' mes_str ' - Day ' dia_str ' - Year ' anno_str ];
    %
    %             plot(horadec,i0,'-k');
    %             hold on
    %             plot(horadec,GHI,'b-o');
    %             plot(horadec,DNI,'r-o');
    %             plot(horadec,DHI,'c-o');
    %             axis([ 0 24 0 1600]);
    %             grid on
    %             title(['(' nombre_serie ') - ' fecha_str ],'Fontsize',16);
    %             xlabel('Local Universal Time','Fontsize',16);
    %             ylabel('Wh/m^2','Fontsize',16);
    %             leg=legend('GHo','GHI','DNI','DHI');
    %             set(leg,'Fontsize',16);
    %             filename=strcat(nombre_serie,'-',fecha_str);
    %             print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',filename))
    %             close all
    %         end
    %     end
    
end

save(strcat(path_tmy,'\','output_series'),'output_series_int',...
    'num_series','raw','datosval');
