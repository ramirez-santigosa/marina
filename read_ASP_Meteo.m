function [ output_args ] = read_ASP_Meteo( input_args )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

nombre_serie=raw{1,i+1};
ruta_serie=strcat(ruta_tmy,'\',nombre_serie);
ruta_fig=strcat(ruta_tmy,'\',nombre_serie,'\figures');
[s,mess,messid] = mkdir(ruta_fig);

num=0;
temp=[]; rhum=[] ; wvel = [];

fprintf('Interpolating METEO in %s serie \n',nombre_serie);

for mes=1:12
    
    prim_fila=(num)*24*num_obs+1;
    anno_dat = output_series_int(prim_fila,1,i); anno_str = num2str(anno_dat);
    
    file_meteo= strcat(ruta_meteo,'\','Alice_',anno_str,'_Weather.xlsx');
    [datos, letras, raw_meteo]= xlsread(file_meteo,'Raw');
    
    date_meteo_vec=[datos(:,2) datos(:,3) datos(:,4) datos(:,5)...
        datos(:,6) zeros(length(datos(:,1)),1)];
    
    date_meteo_num = datenum(date_meteo_vec);
    
    for dia=1:num_dias_mes(mes)
        
        num=num+1;
        inicio=(num-1)*24*num_obs+1;
        final =(num)*24*num_obs;
        
        trozo = output_series_int(inicio:final,:,i);
        
        mes_dat  = trozo(1,2); mes_str  = num2str(mes_dat);
        dia_dat  = trozo(1,3); dia_str  = num2str(dia_dat);
        
        % datos from meteo
        dia_sel = datenum([anno_dat mes_dat dia_dat]);
        selec_meteo = floor(date_meteo_num) == dia_sel;
        %find the positions of the today's meteo
        positions=find(selec_meteo);
        % adds the position before and afeter for interpolation
        positions2=[positions(1)-1; positions; positions(end)+1];
        selec_meteo(positions2)=1;
        
        % do a whole vector for interpolated values
        output_pos1 = date_meteo_num(positions2(1));
        int = 1/(24*num_obs);
        if positions2(end)>length(date_meteo_num)
            date_meteo_num=[date_meteo_num;date_meteo_num(end)+1/(24*2)];
            datos=[datos;datos(end,:)];
        end
        output_pos2 = date_meteo_num(positions2(end));
        out_vector=output_pos1:int:output_pos2;
        
        % extract  meteo values at the input frequency (+2)
        horadec_meteo = datos(selec_meteo,5)+ datos(selec_meteo,6)/60;
        Temp = (datos(selec_meteo,7));
        Rhum = (datos(selec_meteo,11));
        Wvel = (datos(selec_meteo,13));
        Patm = (datos(selec_meteo,17));
        
        % estract solar data (just for testing if needed)
        i0=datosval.astro(inicio:final,9);
        hora = trozo(:,4);
        min =  trozo(:,5 );
        horadec = hora + min./60;
        GHI = trozo(:,7 );
        DNI = trozo(:,9 );
        DHI = trozo(:,11);
        
        fecha_str=['Month ' mes_str ' - Day ' dia_str ' - Year ' anno_str ];
        
        % checking and removing NaN in the first and the last input data
        hay=find(~isnan(Temp));
        Temp(1)=Temp(hay(1)); Temp(end)=Temp(hay(end)); clear hay
        hay=find(~isnan(Rhum));
        Rhum(1)=Rhum(hay(1)); Rhum(end)=Rhum(hay(end)); clear hay
        hay=find(~isnan(Wvel));
        Wvel(1)=Wvel(hay(1)); Wvel(end)=Wvel(hay(end)); clear hay
        
        % off the warning for NaNs in the inputs data => not used.
        warning('off','MATLAB:interp1:NaNstrip');
        Temp_kk=interp1(date_meteo_num(selec_meteo),Temp,out_vector,'spline');
        Rhum_kk=interp1(date_meteo_num(selec_meteo),Rhum,out_vector,'spline');
        Wvel_kk=interp1(date_meteo_num(selec_meteo),Wvel,out_vector,'spline');
        
        % cut the today's positions
        % in the interpolated vector
        selec_out = floor(out_vector) == dia_sel;
        Temp_int= Temp_kk(selec_out);
        Rhum_int= Rhum_kk(selec_out);
        Wvel_int= Wvel_kk(selec_out);
        % in the non imterpolated vector
        Temp(1)=[];Rhum(1)=[];Wvel(1)=[];
        horadec_meteo(1)=[];
        Temp(end)=[];Rhum(end)=[];Wvel(end)=[];
        horadec_meteo(end)=[];
        
        %             % plot interpolate and input values
        %             figure
        %             x_min=0:1/60:(24-1/60);
        %             h1=plot(x_min,Temp_int);
        %             hold on
        %             set(h1,'LineStyle','-','Color','g','Marker','o');
        %             h2=plot(horadec_meteo,Temp);
        %             set(h2,'LineStyle','-','Color','y','Marker','*');
        %             h3=plot(x_min,Rhum_int);
        %             set(h3,'LineStyle','-','Color','b','Marker','o');
        %             h4= plot(horadec_meteo,Rhum);
        %             set(h4,'LineStyle','-','Color','r','Marker','*');
        %             h5=plot(x_min,Wvel_int);
        %             set(h5,'LineStyle','-','Color','m','Marker','o');
        %             h6= plot(horadec_meteo,Wvel);
        %             set(h6,'LineStyle','-','Color','c','Marker','*');
        %             grid on
        %             axis([0 24 0 100]);
        %             title(['(' nombre_serie ') - ' fecha_str ],'Fontsize',16);
        %             xlabel('Local Universal Time','Fontsize',16);
        %             ylabel('ºC / % / m/s','Fontsize',16);
        %             leg=legend('Temp int','Temp','Rhum int','Rhum','Wvel inte','Wvel');
        % %             set(leg,'Fontsize',10,'Location','EastInside');
        %             filename=strcat('Meteo-',nombre_serie,'-',fecha_str);
        %             print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',filename))
        %
        %             % pause
        %             close all
        
        temp=[temp; Temp_int'];
        rhum=[rhum; Rhum_int'];
        wvel=[wvel; Wvel_int'];
    end

     salida = output_series_int(:,:,i);
    salida(:,end+1)=round(temp*10)/10;
    salida(:,end+1)=round(rhum);
    salida(:,end+1)=round(wvel*10)/10;
    
%     % Plotting solar radiation outputs
%     
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
%     fprintf('Generating the TXT %s serie with METEO for simulation \n',nombre_serie);
%     
%     % TXT of original Series (num_obs)
%     fileID = fopen(strcat(ruta_serie,'\','TMY_ASTRI_',nombre_serie,'-MET.txt'),'w');
%     header{1} = 'YEAR'; header{2}= 'MONTH';  header{3}= 'DAY';
%     header{4} = 'HOUR'; header{5}= 'MINUTE'; header{6}= 'SECOND';
%     header{7} = 'GHI(wh/m2)'; header{8}=  'eGHI';
%     header{9} = 'DNI(wh/m2)'; header{10}= 'eDNI';
%     header{11}= 'DHI(wh/m2)'; header{12}= 'eDHI';
%     header{13}= 'Temp(ºC)'; header{14}= 'Rhum(%)'; header{15}= 'Wvel(m/s)';
%     for col=1:14
%         fprintf(fileID,'%10s\t',header{col});
%     end
%     fprintf(fileID,'%10s\r\n',header{15});
%     fprintf(fileID,...
%         '%10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d %8.1f\t %10d\t %8.1f\r\n',...
%         salida');
%     fclose(fileID);
%     
%     salidas(:,:,i)=salida;
    
end
