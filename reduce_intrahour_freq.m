function [ out_series ] = reduce_intrahour_freq( in_series, in_num_obs, out_num_obs )
%REDUCE_INTRAHOUR_FREQ Function for reducing the number of observations per
%hour of the input series.
%   INPUT:
%   in_series: Input series with n_daysX24Xin_num_obs rows and as many 
%   columns as variables.
%   in_num_obs: Number of observations per hour of the input series.
%   out_num_obs: Number of observations per hour of the output series.
%
%   OUTPUT:
%   out_series: Series with the reduced frequency
%
% - F. Mendoza (June 2017) Update

n_vars = size(in_series,2);

if in_num_obs>out_num_obs
    if mod(in_num_obs,out_num_obs)==0
        n_obs = in_num_obs/out_num_obs;
    else
        warning('The original number of observations divided by the new one must be an integer.');
        return
    end
else
    warning('The new number of observations per hour is greater than the original number.');
    return
end

out_length = size(in_series,1)/n_obs;
out_series = NaN(out_length,n_vars);
for i = 0:out_length-1
    out_series(i+1,1:6) = in_series(i*n_obs+1,1:6);
    out_series(i+1,7:end) = mean(in_series(i*n_obs+1:(i+1)*n_obs,7:end));
end

end
