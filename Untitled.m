%function [output_table]=reduce_intrahourly_frequency(input_table,num_obs,NO_out)
% Function for reducting the num_ond by hour
% can be applied in a matrix of more than 2 dimensions

input_table = salidas(:,:,1);
NO_in = num_obs;
NO_out = 6;

variables = input_table(:,7:end);
dim = size(variables);

new_shape = reshape(variables,365*24*NO_out,dim(2),[]);

new_table = mean(new_shape,3);


fileID = fopen(strcat(ruta_tmy,'\','TMY_ASTRI_',nombre_serie,'_10min.txt'),'w');
for col=1:11
    fprintf(fileID,'%10s\t',header{col});
end
fprintf(fileID,'%10s\r\n',header{12});
fprintf(fileID,...
    '%10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\t %10d\r\n',...
    output_series_int(:,:,i)');
fclose(fileID);
