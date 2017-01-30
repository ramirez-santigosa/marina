function [name_out,datos]=Year_BSRN_to_format(ruta_in,ruta_out,filedata,timedata,nodata,anno)
row_summary = 1; % summay row

ruta_fig=strcat(ruta_out,'\','figures');
[s,mess,messid] = mkdir(ruta_fig);


% OUTPUT A FILE / YEAR
fechas_anno = [];
datos_anno  = []; 

aaaa     = num2str(anno);

for mes=1:12
    clear datos_mes fechas_vec
    %saving a summary of the months
    res_date(row_summary,1) = anno;
    res_date(row_summary,2) = mes; 
    
    mm = num2str(mes);
    if length(mm)<2 mm = strcat('0',mm); end

    filename = strcat(filedata.loc,'_',aaaa,'-',mm,'_0100.txt');
    disp(['Leyendo fichero: ' filename]);
    % nombre del fichero con la ruta
    file_id = strcat(ruta_in,'\',aaaa,'\',filename);

    % Test if file exist
    fid = fopen(file_id);
    if fid>-1  %exists the file 
        fclose(fid);

       [ok, ID, geo, dates, data, col] = read_BSRN_LR0100(file_id);%FUNCTION

       if ok==1  %exist and the inside information is ok

           fechas_vec = datevec(dates); 
           fechas     = fechas_vec(:,1:5);

           %saving a summary of the variables order
           res_col(row_summary,1) = col.GHI;
           res_col(row_summary,2) = col.DNI;
           res_col(row_summary,3) = col.DHI;

           %saving the data
           if ~isnan(col.GHI) 
               datos_mes(:,1) = data(:,col.GHI);
               if ~isnan(col.DNI) 
                   datos_mes(:,2) = data(:,col.DNI);
               else
                   datos_mes(:,2) = NaN;
               end
               if ~isnan(col.DHI) 
                   datos_mes(:,3) = data(:,col.DHI);
               else
                   datos_mes(:,3) = NaN;
               end
           end

           geodata.lat = geo.lat;
           geodata.lon = geo.lon;
           geodata.alt = geo.alt;

           %ADD THE MONTHLY DATA AND DATE TO THE PREVIOUS ONES
           fechas_anno = [fechas_anno;fechas_vec];
           datos_anno  = [datos_anno;datos_mes];

       else %exist BUT the inside information is NOT ok
           res_col(row_summary,1) = 0;
           res_col(row_summary,2) = 0;
           res_col(row_summary,3) = 0;
       end
       
    else % the file DOES NOT exists
       %saving a summary when file does not exist
       res_col(row_summary,1) = -1;
       res_col(row_summary,2) = -1;
       res_col(row_summary,3) = -1;
    end

row_summary = row_summary+1; % summay row

end
plot(res_col,'*');
axis([0 12 -2 max(max(res_col))+1]);
title([' Summary ' aaaa],'Fontsize',16);
xlabel('Months','Fontsize',16);
ylabel('Num. column in input file','Fontsize',16);
hleg=legend('GHI','DNI','DHI');
% set(hleg,'Location','WestOutside');
set(hleg,'Location','SouthEastOutside');
set(hleg,'Fontsize',16);
grid on;
% saveas(gcf,strcat(ruta_out,'\','Summary',aaaa),'png');
print('-djpeg','-opengl','-r350',strcat(ruta_fig,'\','Summary',aaaa))

% MAKE  A ESTRUCTURED VARIABLE FOR EACH YEAR
[name_out,datos]=...
    make_standard_data(filedata,timedata,nodata,geodata,...
    fechas_anno,datos_anno(:,1),datos_anno(:,2),datos_anno(:,3),[]);%FUNCTION
% saving the summary of the data 
% aaaa mmm GHI DNI DHI
% Values: -1 no file; 0 wrong file; column number in original file
save(strcat(ruta_out,'\','Summary',aaaa),'res_date','res_col');
