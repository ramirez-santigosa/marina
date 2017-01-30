function [output_series_int,num_out]=interpolating_holes(output_series,cosZ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% interpolation in the following cases:
% HOLES is a boolean 3 columns vector [GHI DNI GHI]
%  Cases 100 (1)/ 010 (2)/ 001 (3) Calculation form the rest  (-1)
%  Cases 110 (4)/ 101 (5)/ 011 (6) Interpolation DNI GHI DHI  (-2) 
%                                  Calculation from the rest  (-3)
%  Cases 111 (7)          Interpolation DNI GHI      (-4) 
%                         DHI Calculation            (-5)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input: 'output_series','cosZ'
%    
% close all
% clear all
% 
% load('output_series');

% dates vector, of a non leap year in minutes
date_year_ini = floor(datenum([2001 1  1  0  0  0])*24*60);
date_year_fin = floor(datenum([2001 12 31 23 59 0])*24*60);
dates_year    = (date_year_ini:date_year_fin)';

for i=1:length(output_series(1,1,:))
    
    GHI  = output_series(:,7,i);
    eGHI = output_series(:,8,i);
    DNI  = output_series(:,9,i);
    eDNI = output_series(:,10,i);
    DHI  = output_series(:,11,i);
    eDHI = output_series(:,12,i);

    %HOLES creation
    GHIbad =   GHI< -900 | isnan(GHI);
    DNIbad =   DNI< -900 | isnan(DNI);
    DHIbad =   DHI< -900 | isnan(DHI);
    
    HOLES= [GHIbad DNIbad DHIbad];
    suma = sum(HOLES,2);
    
    % cases 1
    cases1 = suma == 1;
    if sum(cases1,1)>0
        c100 = (GHIbad & cases1);
        c010 = (DNIbad & cases1);
        c001 = (DHIbad & cases1);
        num(1)=sum(c100,1);
        num(2)=sum(c010,1);
        num(3)=sum(c001,1);
        if num(1)>0 
            GHI(c100) = (DNI(c100).* cosZ(c100)) + DHI(c100); 
            eGHI(c100)= -1;
        end
        if num(2)>0 
            if cosZ>0.005
                DNI(c010) = (GHI(c010)- DHI(c010)) ./ cosZ(c010) ;
            else
                DNI(c010) = 0; 
            end
            eDNI(c010) = -1;
        end
        if num(3)>0
            DHI(c001)= GHI(c001) - (DNI(c001).* cosZ(c001)); 
            eDNI(c001) = -1;
        end
    end
    
    % cases 2
    cases2 = suma == 2;
    if sum(cases2,1)>0
        c110 = (GHIbad & DNIbad & cases2);
        c011 = (DNIbad & DHIbad & cases2);
        c101 = (GHIbad & DHIbad & cases2);
        num(4)=sum(c110,1);
        num(5)=sum(c011,1);
        num(6)=sum(c101,1);
        if num(4)>0 
            DNI(c110)=interp1(dates_year(~DNIbad),DNI(~DNIbad),dates_year(c110));
            eDNI(c110) = -2;
            GHI(c110)= (DNI(c110).* cosZ(c110)) + DHI(c110); 
            eGHI(c110) = -3;
        end
        if num(5)>0 
            DNI(c011)=interp1(dates_year(~DNIbad),DNI(~DNIbad),dates_year(c011));
            eDNI(c011) = -2;
            DHI(c011)= GHI(c011) - (DNI(c011).* cosZ(c011)) ;
            eDHI(c011) = -3;
        end
        if num(6)>0
            GHI(c101)=interp1(dates_year(~GHIbad),GHI(~GHIbad),dates_year(c101));
            eGHI(c101) = -2;
            DHI(c101)= GHI(c101) - (DNI(c101).* cosZ(c101)); 
            eDHI(c101) = -3;
        end
    end    
    
    % cases 3
    cases3 = suma == 3;
    num(7)= sum(cases3,1);
    if num(7)>0
       c111 = cases3;
       DNI(c111)=interp1(dates_year(~DNIbad),DNI(~DNIbad),dates_year(c111)');
       eDNI(c111) = -4;
       GHI(c111)=interp1(dates_year(~GHIbad),GHI(~GHIbad),dates_year(c111));
       eGHI(c111) = -4;
       DHI(c111)= GHI(c111) - (DNI(c111).* cosZ(c111)); 
       eDHI(c111) = -5;
    end

    num_out(:,i)=num';
    output_series_int(:,:,i)=  output_series(:,:,i);
    output_series_int(:,7,i) = round(GHI);
    output_series_int(:,8,i) = eGHI;
    output_series_int(:,9,i) = round(DNI);
    output_series_int(:,10,i)= eDNI;
    output_series_int(:,11,i)= round(DHI);
    output_series_int(:,12,i)= eDHI;
   
end


