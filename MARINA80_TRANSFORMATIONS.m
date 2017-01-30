%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MARINA (Multi annual radiation information approach)
% A TOOL FOR SOLAR RADIATION SERIES GENERATION
%
% Developed in the context of ASTRI
%
% MODULE 7: PLOTTING FINAL DAYS
% Version of July, 2015. L. Ramírez; At CSIRO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run('Configuration_BSRN_ASP.m');
ruta_fig=strcat(ruta_trans,'\','figures');
[s,mess,messid] = mkdir(ruta_fig);


close all

for i=1:num_series
    
    nombre_serie=raw{1,i+1};
    
    cosZ=datosval.astro(:,8);
    
    cosZ(cosZ<0.1) = 0.1;

%     figure; 
%     plot(output_series_int(:,7,i)./cosZ ,'-b')
%     axis([1 525600 0 1800]); grid on;
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
    num=0;
    
    for mes=1:12
        for dia=1:num_dias_mes(mes)
            
            num=num+1;
            inicio=(num-1)*24*num_obs+1;
            final =(num)*24*num_obs;
            
            trozo = output_series_int(inicio:final,:,i);
            
            anno_str= num2str(trozo(1,1));
            mes_str = num2str(mes);
            dia_str = num2str(dia);
                       
            i0=datosval.astro(inicio:final,9);
            esdia = i0 > 0;
            hora = trozo(:,4) ; 
            min =  trozo(:,5 );
            horarad = 12-(hora + min./60)*15*pi/180;% wi
            horaradT = (horarad-mean(horarad,1))/std(horarad);% wi
            
                        
            GHI = trozo(:,7 );
            GNI = GHI./cosZ(inicio:final,1);
            DNI = trozo(:,9 );
            
            maxAA(num,1)= max(GNI);
            maxAA(num,2)= max(DNI);
            
            GNIT = GNI/maxAA(num,1);
            DNIT = DNI/maxAA(num,2);
            
            if dia==15
                figure
                fecha_str=['Month ' mes_str ' - Day ' dia_str ' - Year ' anno_str ];
%                 plot(horaradT,i0,'-k');
                hold on
                plot(horaradT(esdia),GNIT(esdia),'b-o');
                plot(horaradT(esdia),DNIT(esdia),'r-o');
                axis([ -2 2 0 2]);
                grid on
                title(['( T-' nombre_serie ') - ' fecha_str ],'Fontsize',16);
                xlabel('Local Universal Time','Fontsize',16);
                ylabel('Wh/m^2','Fontsize',16);
                leg=legend('GHI','DNI');
                set(leg,'Fontsize',16);
                filename=strcat('T-',nombre_serie,'-',fecha_str);
                print('-djpeg','-zbuffer','-r350',strcat(ruta_fig,'\',filename))
                close all
            end
        end
    end
end


