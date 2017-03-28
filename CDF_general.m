function [num_days, cumPercent] = CDF_general(data,max,nbins)
%CDF_GENERAL Creates the cumulative distribution function of the input
%series.
%   INPUT:
%   data: Input series
%   max: Maximum value of the series
%   nbins: Number of bins
%
%   OUTPUT:
%   num_days: Cumulative number of days below each edge according to the
%   number of bins
%   cumPercent: Cumulative percent of each bin
%
% - Guillermo Ibáñez (April 2013)
% - L. Ramírez (2015)
% - F. Mendoza (March 2017) Update

delta = max/nbins;
edges = delta:delta:max;
num_days = zeros(nbins,1); % Pre-allocating

for i = 1:nbins
    values = data<=edges(i);
    num_days(i) = sum(values);
end

cumPercent = num_days/length(data);

end
