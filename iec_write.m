function [ ST ] = iec_write(filename_out,iec_out,time_func_str,num_obs,options_iec)
%IEC_WRITE Writes a txt file formatted according with the standard 
%IEC 62862-1-3 (MESOR).
%   INPUT:
%   filename_out: Name of the output IEC 62862-1-3 txt file
%   iec_out: Data that will be written out. The number of columns must be
%   coherent with the number of labels defined in the configuration case
%   file.
%   time_func_str: NaN if a functional date is not requiered. Otherwise it
%   should be a string array with the functional date for each observation
%   in ISO 8601 format. A functional date is usually required in the case
%   of typical years files.
%   num_obs: Number of observations per hour.
%   options_iec: Structure with the headers and labels. Defined in the
%   configuration case file.
%
%   OUTPUT:
%   ST: 0 if successful or -1 if not.
%
% - F. Mendoza (May 2017)

date_num = 6; % Number of columns that conform the date [Year Month Day Hour ...]
time_str = cellstr(datestr(iec_out(:,1:date_num),'yyyy-mm-ddTHH:MM:SS')); % Original date. Maybe not always 1:6 TODO!!!

headers{1,1} = ['#MET_IEC.v1.0 headerlines: ', num2str(options_iec.hl,'%d')];
headers{2,1} = ['#characterset ', options_iec.characterset];
headers{3,1} = ['#delimiter ', options_iec.del];
headers{4,1} = ['#endofline ', options_iec.eol];
headers{5,1} = ['#title ', options_iec.title];
headers{6,1} = ['#history.',options_iec.nowstr,options_iec.histmsg];
headers{7,1} = ['#comment ', options_iec.cmt];
headers{8,1} = ['#datasource ', options_iec.ds];
headers{9,1} = ['#user_defined_fields ', options_iec.udf];
headers{10,1} = ['#IPR.institution.name ', options_iec.inst_name];
headers{11,1} = '#IPR.copyrightText ExampleCR';
headers{12,1} = '#IPR.contact someone@example.com';
headers{13,1} = ['#location.latitudeDegrN ', num2str(options_iec.lat,'%.4f')];
headers{14,1} = ['#location.longitudeDegrE ', num2str(options_iec.lon,'%.4f')];
headers{15,1} = ['#location.elevationMAMSL ', num2str(options_iec.alt,'%d')];
headers{16,1} = ['#time.timezone ', options_iec.timezone];
headers{17,1} = ['#time.resolutiontype ', options_iec.t_res];
headers{18,1} = ['#time.resolutionSec ', num2str(3600/num_obs,'%d')];
headers{19,1} = ['#time.averaging ', options_iec.t_ave];
headers{20,1} = ['#time.completeness ', options_iec.t_com];
headers{21,1} = ['#time.calender.leap_years ', options_iec.t_leap];
headers{22,1} = ['#gap.notanumber ' num2str(options_iec.nodata)];
headers{23,1} = '#QC.type.4 BSRN';
headers{24,1} = '#QC.type.4 https://doi.org/10.1016/j.renene.2015.01.031';
headers{25,1} = '#begindata';

labels = options_iec.labels; % Labels defined in the configuration case file

switch options_iec.del
    case 'space'
        del = ' ';
    case ';'
        del = ';';
    case 'tab'
        del = '\t';
    case ','
        del = ',';
end
eol = options_iec.eol;

fileID = fopen(filename_out,'W');
formatSpec = strcat('%s',eol);
for j = 1:size(headers,1)
    fprintf(fileID,formatSpec,headers{j}); % Write headers
end
formatSpec = strcat('%s',del);
for j = 1:size(labels,2)
    fprintf(fileID,formatSpec,labels{j}); % Write labels
end
fprintf(fileID,eol);

formatSpec = strcat('%s',del); % Init
nVars = size(iec_out,2)-date_num;
if isnan(time_func_str{1}) % If it is not required a functional date
    for i = 1:nVars
        formatSpec = strcat(formatSpec,'%4.2f',del);
    end
    formatSpec = strcat(formatSpec(1:end-length(del)),'\n');
    
    for j = 1:size(iec_out,1)
        fprintf(fileID,formatSpec,...
            time_str{j}, iec_out(j,date_num+1:end));
    end
else % If it is required a functional date (typical year case)
    formatSpec = strcat(formatSpec,'%s',del);
    for i = 1:nVars
        formatSpec = strcat(formatSpec,'%4.2f',del);
    end
    formatSpec = strcat(formatSpec(1:end-length(del)),'\n');
    
    for j = 1:size(iec_out,1)
        fprintf(fileID,formatSpec,...
            time_func_str{j}, time_str{j}, iec_out(j,date_num+1:end));
    end
end
fprintf(fileID,'#enddata');
ST = fclose(fileID);

end
