function [ smooth_out ] = smoothed( input )
%SMOOTHED Returns a smooth trend during the year from the input daily
%meteorological parameter. It follows the simplified procedure proposed by
%Festa, R., Ratto, C.F., DeGol, D., 1988. A procedure to obtain average
%daily values of meteorological parameters from monthly averages. Sol.
%Energy 40, 309–313. doi:10.1016/0038-092X(88)90003-5
%   input: Daily meteorological input (365 or 366 days)
%   smooth_out: Smoothed trend of the input daily series

N = length(input); % Number of days input (365 or 366)
M = 12; % Number of equally divided parts of the input
L = N/M;
res = mod(N,M);

nd_parts = floor(L)*ones(M,1);
for i = 0:res-1
    nd_parts(M-i) = nd_parts(M-i)+1;
end
cs_nd_parts = [0; cumsum(nd_parts)];

y_m = zeros(M,1);
for i = 1:length(nd_parts)
    y_m(i) = mean(input(cs_nd_parts(i)+1:cs_nd_parts(i+1)));
end

s_m = zeros(6,1); d_m = zeros(6,1);
for m = 1:6
    s_m(m) = y_m(m)+y_m(13-m);
    d_m(m) = y_m(m)-y_m(13-m);
end

z_m = zeros(12,1);
for m = 1:3
    z_m(m) = s_m(m)+s_m(7-m);
end
for m = 4:6
    z_m(m) = s_m(m-3)-s_m(10-m);
end
for m = 7:9
    z_m(m) = d_m(m-6)+d_m(13-m);
end
for m = 10:12
    z_m(m) = d_m(m-9)-d_m(16-m);
end

D_km = [83 83 83 0 0 0 0 0 0 0 0 0;...
    0 0 0 163 119 44 0 0 0 0 0 0;...
    151 0 -151 0 0 0 0 0 0 0 0 0;...
    0 0 0 131 -131 131 0 0 0 0 0 0;...
    101 -202 101 0 0 0 0 0 0 0 0 0;
    0 0 0 58 -160 218 0 0 0 0 0 0;...
    0 0 0 0 0 0 44 119 163 0 0 0;...
    0 0 0 0 0 0 0 0 0 87 175 87;...
    0 0 0 0 0 0 131 131 -131 0 0 0;...
    0 0 0 0 0 0 0 0 0 175 0 -175;...
    0 0 0 0 0 0 218 -160 68 0 0 0;...
    0 0 0 0 0 0 0 0 0 -131 131 -131]./1000;

A_k = zeros(6,1); B_k = zeros(6,1);
for k = 1:6
    A_k(k) = D_km(k,:)*z_m;
end
for k = 7:12
    B_k(k-6) = D_km(k,:)*z_m;
end

x_d = zeros(N,1); Phi = 0;
for d = 1:N
    sum_k = 0;
    for k = 1:5
        sum_k = sum_k+A_k(k+1)*cos(((2*pi)/N)*k*d)+B_k(k)*sin(((2*pi)/N)*k*d);
    end
    x_d(d) = A_k(1)+sum_k+B_k(6)*sin(((2*pi)/N)*6*d-Phi);
end

smooth_out = x_d;
% smooth_out = smooth(input,30,'sgolay',28); % MATLAB function

end
