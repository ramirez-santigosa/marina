%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 5: THE TMY SERIES GENERATION
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
% ..\OUTPUT\4_CASES
%       INPUT-GENERATION.xlsx;
% OUTPUT 
% ..\OUTPUT\4_TMY
%  (1) OUTPUT-GENERACION (3 sheets by case)
%        sheet CASE_Dini   initial daily values
%        sheet CASE_Dfin   final daily values
%        sheet CASE_M      final monthly values
% ..\OUTPUT\4_TMY\CASE
%  (2) TMY-ASTRI-CASE.TXT
%        txt file: aaaa mm dd hh MM SS GHI eGHI DNI eDNI DHI eDNI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
clc
close all
run('Configuration_BURNS.m');

[s,mess,messid] = mkdir(ruta_tmy);

% Matlab file with the data structure after validation
name     = [filedata.loc '00-' filedata.own '-' filedata.num];
filename_val  =strcat(ruta_val,'\',name);   

% Leemos los datos para el input de la generación de datos 
% Lee la variable de trabajo
[num,variable]=xlsread(filename_input,'VARIABLE','A1');
if strcmp(variable,'GHI')
    cols_trab=1:3;
else
    if strcmp(variable,'DNI')
    cols_trab=4:6;
    else
     fprintf('No se identifica la variable de trabajo');   
     fprintf('En la excel de INPUT; sheet=VARIABLE');   
     return;
    end
end
% Lee los años de los meses a concatenar, y el nombre de las series
[series,texto, raw] = xlsread(filename_input,'INPUT');
% Lee los datos objetivo de la generación de la serie
meses_objetivo=xlsread(filename_input,'OBJECTIVE');

%quiero saber el número de columnas=series que tengo que generar
num_series=numel(series(1,:));

num_dias_ant=[0 31 59 90 120 151 181 212 243 273 304 334];

for i=1:num_series   
    
    SERIES_meses=[];
    dias_meses=[];
    valores_meses=[];

    SERIES_salida=[];
    dias_salida=[];
    
    nombre_serie=raw{1,i+1};
    ruta_serie=strcat(ruta_tmy,'\',nombre_serie);
    [s,mess,messid] = mkdir(ruta_serie);
    
    ruta_fig=strcat(ruta_serie,'\','figures');
    [s,mess,messid] = mkdir(ruta_fig);

    fprintf('Generating the %s serie for simulation \n',nombre_serie); 
        
    for mes=1:12
       % EXTRACCIÓN DE VALORES DE LAS SERIES 
       SERIES_mes=[];
       %tengo que identifiar el nombre del año que tengo leer EL FICHERO
       anno=series(mes,i);
       
       % fichero con los datos validados e interpolados
       load(strcat(ruta_val,'\',name,'-',num2str(anno),'_VAL'));
       num_obs = datosval.timedata.num_obs;
       datos   = datosval.matc;
       if mes == 1; cosZ = datosval.astro(:,8);         
       end
       
       fila_ini=num_dias_ant(mes)*24*num_obs+1; 
       fila_fin=fila_ini+(num_dias_mes(mes)*24*num_obs)-1;   
       
       SERIES_mes=datos(fila_ini:fila_fin,:);
       SERIES_meses=[SERIES_meses;SERIES_mes];
       
       % EXTRACCIÓN DE VALORES DIARIOS
       dias_mes=[];
       [dias_annos, texto]=xlsread(filename_val,'Val-dia');
       anno_ini=str2num(texto{1,1}(1:4));
       anno_fin=str2num(texto{1,end}(1:4));
       annos=[anno_ini:anno_fin];
       num=find(annos==anno);
       
       col_ini=1+6*(num-1);
       col_fin=col_ini+5;
       
       fil_ini=num_dias_ant(mes)+1; %los datos empiezan en la fila 2
       fil_fin=fil_ini+(num_dias_mes(mes))-1;
              
       dias_mes=dias_annos(fil_ini:fil_fin,col_ini:col_fin);
       dias_meses=[dias_meses;dias_mes];
       
       % EXTRACCIÓN DE LOS VALORES MENSUALES
       valores_mes=[];
       meses_annos=xlsread(filename_val,'Val-mes');
       fil=mes;
              
       valores_mes=meses_annos(fil,col_ini:col_fin);
       valores_meses=[valores_meses;valores_mes];
       
       %CALCULA LOS CAMBIOS DE DÍAS
       A=dias_mes(:,[1 cols_trab(2)]);
       A(:,2)=A(:,2)/1000;
 
       valor_mes=valores_meses(mes,cols_trab(2));
       VMO=meses_objetivo(mes,i);
        
       if valor_mes <= VMO
           [resultado,usados,cambiados,contador,control]...
               =Cambia_dias_sube(mes,A,VMO,max_cambios,dist_dias,max_uso);
       elseif valor_mes > VMO
           [resultado,usados,cambiados,contador,control]...
               =Cambia_dias_baja(mes,A,VMO,max_cambios,dist_dias,max_uso);
       end
       final.resultado{i,mes}=resultado;
       final.usados{i,mes}=usados;
       final.cambiados{i,mes}= cambiados;
       final.contador{i,mes}=contador;
       final.control{i,mes}=control;
       
       SERIES_sal=SERIES_mes;
       dias_sal=dias_mes;
       valores_sal(mes,1:2)=valores_mes([2 5]);
       % Aplica los cambios de días a las series
       if contador<=max_cambios
           Dias_input=resultado(:,end-1);
           Dias_ord=1:num_dias_mes(mes);
           cambiados=Dias_input~=Dias_ord';
           pos_dias_fin=find(cambiados); % posiciones de los cambiados
           dias_origen=Dias_input(pos_dias_fin);
           for num=1:numel(pos_dias_fin)
               Inicio_dia_fin=1+(pos_dias_fin(num)-1)*24*num_obs;
               Fin_dia_fin=Inicio_dia_fin+24*num_obs-1;
               
               Inicio_dia_origen=1+(dias_origen(num)-1)*24*num_obs;
               Fin_dia_origen=Inicio_dia_origen+24*num_obs-1;
               
               SERIES_sal(Inicio_dia_fin:Fin_dia_fin,:)=SERIES_mes(Inicio_dia_origen:Fin_dia_origen,:);
              
               dias_sal(pos_dias_fin(num),:)=dias_mes(dias_origen(num),:);
           end
       end 
       
       SERIES_salida=[SERIES_salida;SERIES_sal];
       dias_salida=[dias_salida;dias_sal];

       valores_sal(mes,1)=sum(dias_sal(:,2))/1000;
       valores_sal(mes,2)=sum(dias_sal(:,5))/1000;
    end

    objetivo_meses=round(meses_objetivo(:,i));

    
    output_series(:,:,i)=SERIES_salida;

    %---------------------------------------
    [output_series_int,num_out]=interpolating_holes(output_series,cosZ);

    %---------------------------------------
    %Guarda los valores del año FINAL

    %Desactiva el warning de que se cree una nueva hoja excel.
    warning off MATLAB:xlswrite:AddSheet

    %Escribe los valores DIARIOS del año seleccionado
    xlswrite(filename_out,dias_meses,strcat(nombre_serie,'_Dini'),'A1');
    %Escribe los valores DIARIOS del año FINAL
    xlswrite(filename_out,dias_salida,strcat(nombre_serie,'_Dfin'),'A1');

    %Escribe los valores MENSUALES del año seleccionado, OB y FIN
    xlswrite(filename_out,[{'YEARini'},{'GHIini'},{'DNIini'},{'OBJ'},{''},{'GHIend'},{'DNIend'},{'Cambios'}],...
        strcat(nombre_serie,'_M'),'A1');
    % initial year by month
    xlswrite(filename_out,series(:,i),strcat(nombre_serie,'_M'),'A2');
    % initial values of GHi and DNI by month
    xlswrite(filename_out,valores_meses(:,[2 5]),strcat(nombre_serie,'_M'),'B2');
    % objetives (DNI) by each month
    xlswrite(filename_out,objetivo_meses,strcat(nombre_serie,'_M'),'D2');
    % final values
    xlswrite(filename_out,round(valores_sal),strcat(nombre_serie,'_M'),'F2');
    % final cambios
    xlswrite(filename_out,final.contador',strcat(nombre_serie,'_M'),'H2');
  
    %---------------------------------------
    % export to txt file
    fprintf('Generating the TXT %s serie for simulation \n',nombre_serie); 

    % TXT of original Series (num_obs) 
    fileID = fopen(strcat(ruta_serie,'\','MY_',nombre_serie,'.txt'),'w');
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
% 
%         end
%     end
    
end
save(strcat(ruta_tmy,'\','output_series'),'output_series_int',...
    'num_series','raw','datosval');
