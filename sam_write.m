function [ ST ] = sam_write(filename_out,sam_out,options_sam)
%SAM_WRITE Writes a CSV file formatted to be read by the software System
%Advisory Model (SAM). More info:
%https://sam.nrel.gov/weather
%https://sam.nrel.gov/sites/default/files/content/documents/pdf/wfcsv.pdf
%   INPUT:
%   filename_out: Name of the output CSV SAM file.
%   sam_out: Data that will be written out. The number of columns must be
%   coherent with the number of labels defined in the configuration case
%   file.
%   options_sam: Structure with the headers and labels. Defined in the
%   configuration case file.
%
%   OUTPUT:
%   ST: 0 if successful or -1 if not.
%
% - F. Mendoza (May 2017)

headerSAM{1,1} = 'Source,Location ID,City,Region,Country,Latitude,Longitude,Time Zone,Elevation';
headerSAM{2,1} = [options_sam.source,',',options_sam.locID,',',...
    options_sam.city,',',options_sam.reg,',',options_sam.country,',',...
    num2str(options_sam.lat,'%.6f'),',',...
    num2str(options_sam.lon,'%.6f'),',',...
    num2str(options_sam.tzone,'%2.1f'),',',...
    num2str(options_sam.alt,'%d')];

labels = options_sam.labels; % Labels defined in the configuration case file

fileID = fopen(filename_out,'W');
for j = 1:size(headerSAM,1)
    fprintf(fileID,'%s\n',headerSAM{j}); % Write first two rows of headers
end
for j = 1:size(labels,2)
    fprintf(fileID,'%s,',labels{j}); % Write labels
end
fprintf(fileID,'\n');

formatSpec = ''; % Init
nDate = 5; nIrr = 3; nAdd = size(sam_out,2)-(nDate+nIrr);
for i = 1:nDate
    formatSpec = strcat(formatSpec,'%d,');
end
for i = 1:nIrr
    formatSpec = strcat(formatSpec,'%.0f,');
end
for i = 1:nAdd
    formatSpec = strcat(formatSpec,'%.1f,');
end
formatSpec = strcat(formatSpec(1:end-1),'\n');
fprintf(fileID,formatSpec,sam_out');
ST = fclose(fileID);

end
