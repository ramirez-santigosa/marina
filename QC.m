function [dataqc] = QC(path_fig,data,var,max_rad,cols,tzone,name,offset_empirical)
%QC Creates an ordered, continuous, and complete annual array
%from the input data (which must be in standard format). Calculates
%astronomical variables, quality control and creates figures with the QC
%results of the variables. It takes into account the station time zone and
%converts to TST to perform astronomical calculations. Output is in UTC.
%   INPUT:
%   pathfig: Path where figures are saved
%   data: Standard data structure
%   var: Logical array that indicates which variables will be included in the QC process [GHI DNI DHI].
%   max_rad: Max. solar radiation value for the figures
%   cols: Columns of the variables in the data matrix
%   tzone: Specific time zone of the station location
%   offset_empirical: Just in case the results seems to have timestamp mistakes
%
%   OUTPUT:
%   dataqc: Standard data structure with two additional matrices: .mqc and .astro
%       data.mqc  = [YYYY MM DD HH mm ss GHIord fGHI DNIord fDNI DHIord fDHI];
%       data.astro = [dj e0 ang_day et tst_hours w dec cosz i0 m];
%   fXXX are arrays with the QC flags of the variable XXX according with
%   BSRN procedurement:
%   0 Fail to pass 1st test: Physically Possible Limits
%   1 Fail to pass 2nd test: Extremely Rare Limits
%   2 Fail to pass 3rd test: Comparisons and coherence between variables
%   3 Pass all tests, data is valid
%
% - L. Ramírez (April 2013)
% - S. Moreno  (June 2014)
% - L. Zarzalejo, L Ramírez (May 2015)
% - F. Mendoza (February 2017)

%% Constants
Micolormap = [1     0.2     0.2;...
              1     0.5     0;...
              1     1       0;...
              0.6   1       0.6;...
              0.3   0.9     0.3];

Isc = 1367; % Solar constant [W/m2]

%% Assigment of the input data
lat = data.geodata.lat;
lon = data.geodata.lon;
time = data.timedata.timezone; % Time reference in which data is acquired
stamp = data.timedata.stamp;
num_obs = data.timedata.num_obs;
nodata = data.nodata;
input = data.mat;
year = data.mat(floor(length(input)/2),1); % Avoiding the first rows
file_name = [name num2str(year)]; % For figures title
lat_rad = lat*pi/180; % Latitude in radians

%% Assessing the hours jump needed in the time data
off = str2double(time(4:end)); % Offset of the input data
jumpH = tzone - off; % Shift between the time zone of the station and the time reference of the input data

if tzone >= 0 % String with the time zone of the station
    timeZ = strcat('UTC+',num2str(tzone));
else
    timeZ = strcat('UTC-',num2str(tzone));
end

if ~isnan(nodata)% Position of no data values in the input matrix, if different of NaN
    pos_nodata = input==nodata;
    input(pos_nodata) = NaN; % Assign Not-a-number to no data (default)
end

GHI = input(:,cols.GHI); % Variables arrays
DNI = input(:,cols.DNI);
DHI = input(:,cols.DHI);

%% Input time reference to station local time (now data stars in the previous year!?)
date_vec = input(:,cols.date);

if numel(date_vec(1,:))==4 % If just year, month, day, hour => complete time vector
    date_vec(:,5) = 0; % minutes
    date_vec(:,6) = 0; % seconds
end

date_num = datenum(date_vec); % Input dates in serial date numbers
date_num = date_num + jumpH/24; % Shift to Local Time
date_num_obs = round(date_num*24*num_obs); % Input dates in each observation. Important because of rounding!

%% Creation of the ordered, continuous and complete annual series
day_ini = floor((datenum([year  1  1 0 0 0]))); % First day of the complete year
day_end = floor((datenum([year 12 31 0 0 0]))); % Last day of the complete year
day_ini_obs = floor(day_ini*24*num_obs); % First day of the year in observations period

num_days = day_end-day_ini+1; % Number of days complete year

% Creates an array with the number of positions according to the days with
% data from the first observation (i.e. hour=0, min=0) to the last one
% (i.e. hour=23 min=59)
pos_ord = (1:num_days*24*num_obs)'; % Complete positions vector
date_obs_ord = pos_ord+day_ini_obs-1; % Complete array in observations period
days_num_ord = date_obs_ord/(24*num_obs); % Complete array in days
lines = numel(days_num_ord); % Number of observations in a complete year

% Arrays for the variables in a complete year
GHIord = NaN(lines,1);
DNIord = NaN(lines,1);
DHIord = NaN(lines,1);

%% Assigment of the available values to its corresponding position in the complete array

% Array of relative position according with the number of observations per
% hour.
pos_obs_INI = date_num_obs-date_obs_ord(1)+1;

% If jumpH > 0: Search the positions higher that the number of observations
% in a year, i.e., those that will go beyond of the last observation of the
% year in the local time of the station because of the shift with the time
% reference of the data.
After = pos_obs_INI > lines;
pos_obs_INI(After) = [];
GHI(After) = []; DNI(After) = []; DHI(After) = [];

% If jumpH < 0: Search the positions lower that 1, i.e., those before of
% the first observation of the year in the local time of the station
% because of the shift with the time reference of the data.
Before = pos_obs_INI < 1;
pos_obs_INI(Before) = [];
GHI(Before) = []; DNI(Before) = []; DHI(Before) = [];

% Assignment of the variables values to the corresponding date
GHIord(pos_obs_INI) = GHI; % In the station time zone
DNIord(pos_obs_INI) = DNI; % In the station time zone
DHIord(pos_obs_INI) = DHI; % In the station time zone

%% Astronomical calculations

[astro,tst_num,~] = calcula_astro...
    (days_num_ord,stamp,num_obs,timeZ,lat,lon,offset_empirical); % Function

dj = astro(:,1);
e0 = astro(:,2); % Sun-Earth distance correction factor
% ang_day = astro(:,3);
% et = astro(:,4);
% tst_hours = astro(:,5);
w = astro(:,6);
dec = astro(:,7);
cosz = astro(:,8); % Cosine of the solar zenith angle.
% i0 = astro(:,9);
% m = astro(:,10);

% There must be a problem with UTC conversion in  astro function!!!

%% Quality Control (BSRN)
% TEST #1: Physically Possible Limits ------------------------------------
% Two groups of data are defined:
% - low: Solar height until 10 degrees. Applicable for Tests #1 y 2
% - others

% Pre-allocate
fGHI = zeros(size(GHIord));
fDNI = zeros(size(DNIord));
fDHI = zeros(size(DHIord));

% Creating the groups of data
low = (acos(cosz)*180/pi)>=90; %!Preguntar bajos?

% Setting the limits of the variables and groups
maxG = Isc.*e0*1.5.*((cosz.^12).^0.1)+100;
maxG(low) = 100; % Fixed maximum in this case
maxD = Isc.*e0*0.95.*((cosz.^12).^0.1)+50;
maxD(low) = 50; % Fixed maximum in this case
maxB = Isc.*e0;

% Flag assigment
% Those values that fail to pass the test #1 are flagged with '0'
test1 = (GHIord>=-4 & GHIord<=maxG); fGHI(test1) = 1; clearvars test1
test1 = (DHIord>=-4 & DHIord<=maxD); fDHI(test1) = 1; clearvars test1
test1 = (DNIord>=-4 & DNIord<=maxB); fDNI(test1) = 1; clearvars test1
clearvars  maxG maxD maxB

%% TEST #2: Extremely Rare Limits ----------------------------------------
% Setting the limits of the variables and groups
maxG = Isc.*e0*1.2.*((cosz.^12).^0.1)+50;
maxG(low) = 50;
maxD = Isc.*e0*0.75.*((cosz.^12).^0.1)+30;
maxD(low) = 30;
maxB = Isc.*e0*0.95.*((cosz.^2).^0.1)+10;
maxB(low) = 10;

% Flag assigment
% Those values that fail to pass the test #2 are flagged with '1'
test2 = (GHIord>=-2 & GHIord<=maxG & fGHI==1); fGHI(test2) = 2; clearvars test2
test2 = (DHIord>=-2 & DHIord<=maxD & fDHI==1); fDHI(test2) = 2; clearvars test2
test2 = (DNIord>=-2 & DNIord<=maxB & fDNI==1); fDNI(test2) = 2; clearvars test2
clearvars  maxG maxD maxB

%% TEST #3: Comparisons ---------------------------------------------------
% For those values in which this test isn't applicable (measured or calculated
% GHI < 50 W/m2), applies the conditions of the second test.

% Three groups of data are defined
% - low: solar height a -3 a 15; GHI may. 50 !!!
% - high: solar height a may. 15; GHI may. 50 !!!
% - others

% CONDITION IMPOSED TO THE DIFFUSE RADIATION
ffDHI = fDHI; % A temp variable is used to apply a previous condition to the diffuse irradiance

% Second relationship: checks that the diffuse percentage of global
% radiation is not over specific limits. This condition can only be applied
% to records in which the measured global irradiance is over 50 W/m2.

% Creating the groups with the input measured GHI data
high = ((acos(cosz)*180/pi)<75 & GHIord>50);
low = ((acos(cosz)*180/pi)>=75 & (acos(cosz)*180/pi)<93 & GHIord>50);

% Setting limits
maxD = NaN(size(DHIord));
maxD(high) = 1.05*GHIord(high); % For theta_z<75°
maxD(low) = 1.10*GHIord(low); % For 75°<theta_z<93°

% Flag assigment
% Those values that fail to pass the test #3.2 are flagged with '2'
test32 = (DHIord<=maxD & fGHI==2 & fDHI==2 & fDNI==2); ffDHI(test32)=3; clearvars test32
clearvars high low

% CONDITION IMPOSED TO ALL THREE VARIABLES
% First relationship: measured direct global irradiance is compared with
% the value calculated from its measured components. This condition can
% only be applied to records in which the calculated global irradiance is
% over 50 W/m2.
GHIcalc = DHIord+DNIord.*cosz;

% Creating the groups with the calculated GHI data
high = ((acos(cosz)*180/pi)<75 & GHIcalc>50);
low = ((acos(cosz)*180/pi)>=75 & (acos(cosz)*180/pi)<93 & GHIcalc>50);

% Setting limits
maxG = NaN(size(GHIcalc));
maxG(high) = 1.08.*GHIcalc(high); % For theta_z<75°
maxG(low) = 1.15.*GHIcalc(low); % For 75°<theta_z<93°
minG = zeros(size(DHIord))-2; % Preguntar por el minimo según paper?!!!
minG(high) = 0.92.*GHIcalc(high);
minG(low) = 0.85.*GHIcalc(low);

% Flag assigment
% Those values that fail to pass the test #3 are flagged with '2'
test3 = (GHIord>=minG & GHIord<=maxG & fGHI==2 & fDNI==2 & ffDHI==3);
fGHI(test3) = 3;
fDHI(test3) = 3;
fDNI(test3) = 3;
clearvars test32 high low

%% NEW TEST #4: Some impossible were slipping through ---------------------
test4 = ((GHIord+50>GHIcalc & GHIord-50<GHIcalc) & test3);
fGHI(test4) = 4;
fDNI(test4) = 4;
fDHI(test4) = 4;

% Save results
fGHIF = fGHI; fDNIF = fDNI; fDHIF = fDHI;

%% GRAPHS OF QUALITY CONTROL RESULTS
% Coherence of the three variables per year -------------------------------

test0 = fGHI==0;
test1 = fGHI==1;
test2 = fGHI==2;
test3 = fGHI==3;
test4 = fGHI==4;

figure
plot(GHIord(test0),GHIcalc(test0),'o', 'MarkerFaceColor',[1   0   0  ],'MarkerEdgeColor',[0.8 0   0  ]); hold on
plot(GHIord(test1),GHIcalc(test1),'o', 'MarkerFaceColor',[1   0.5 0  ],'MarkerEdgeColor',[0.8 0.3 0  ]);
plot(GHIord(test2),GHIcalc(test2),'o', 'MarkerFaceColor',[1   1   0  ],'MarkerEdgeColor',[0.8 0.8 0  ]);
plot(GHIord(test3),GHIcalc(test3),'o', 'MarkerFaceColor',[0.5 1   0.5],'MarkerEdgeColor',[0.3 0.8 0.3]);
plot(GHIord(test4),GHIcalc(test4),'o', 'MarkerFaceColor',[0   0.8 0  ],'MarkerEdgeColor',[0   0.7 0  ]);
plot([0 max_rad],[0 max_rad],'-k');

leg=legend('NaN','Not FP','Rare','Coher','Best');
set(leg,'Location','SouthEast');
axis([0 max_rad 0 max_rad]);
title(file_name,'Fontsize',16,'Interpreter','none'); %title([file_name ' Consistency '],'Fontsize',16);
xlabel('GHI Measures','Fontsize',14,'FontWeight','bold');
ylabel('GHI calculated','Fontsize',14,'FontWeight','bold');
grid on;
axis square
set(gca,'XTick',0:400:max_rad);
set(gca,'YTick',0:400:max_rad);
print('-djpeg','-opengl','-r350',strcat(path_fig,'\',file_name,'_COHER'))
% saveas(gcf,strcat(ruta_fig,'\',file_name,'_COHER'),'png');

%% Monthly coherence graphs -----------------------------------------------

tst_vec = datevec(tst_num); % 6X1 date array
path_fig_month = strcat(path_fig,'\Monthly');

if ~exist(path_fig_month,'dir')
    mkdir(path_fig_month);
end
clear test0 test1 test2 test3

for m=1:12
    data_month = (tst_vec(:,2)==m);
    m_str = num2str(m);
    if m<10 % Two character month
        m_str=['0' num2str(m)];
    end
    
    test0 = (fGHI == 0 & data_month);
    test1 = (fGHI == 1 & data_month);
    test2 = (fGHI == 2 & data_month);
    test3 = (fGHI == 3 & data_month);
    test4 = (fGHI == 4 & data_month);
    
    figure
    plot(GHIord(test0),GHIcalc(test0),'o', 'MarkerFaceColor',[1   0   0  ],'MarkerEdgeColor',[ 0.8 0   0  ]); hold on
    plot(GHIord(test1),GHIcalc(test1),'o', 'MarkerFaceColor',[1   0.5 0  ],'MarkerEdgeColor',[ 0.8 0.3 0  ]);
    plot(GHIord(test2),GHIcalc(test2),'o', 'MarkerFaceColor',[1   1   0  ],'MarkerEdgeColor',[ 0.8 0.8 0  ]);
    plot(GHIord(test3),GHIcalc(test3),'o', 'MarkerFaceColor',[0.5 1   0.5],'MarkerEdgeColor',[ 0.3 0.8 0.3]);
    plot(GHIord(test4),GHIcalc(test4),'o', 'MarkerFaceColor',[0   0.8 0  ],'MarkerEdgeColor',[ 0 0.7   0  ]);
    plot([0 max_rad],[0 max_rad] ,'-k');
    
    axis([0 max_rad 0 max_rad]);
    title([file_name ' Month ' m_str ' Consistency ' ],'Fontsize',16);
    xlabel('GHI Measures','Fontsize',16);
    ylabel('GHI calculated','Fontsize',16);
    grid on;
    print('-djpeg','-opengl','-r350',strcat(path_fig_month,'\',file_name,'_COHER_M',m_str))
%     saveas(gcf,strcat(ruta_fig_mes,'\',file_name,'_COHER_M',mes_str),'png'); 
end

%% ANNUAL QUALITY MAPS

% Trick for all graphs have the 5 different values
% fGHI(1)=-1; fGHI(2)=0; fGHI(3)=1; fGHI(4)=2; fGHI(5)=3;
% fDNI(1)=-1; fDNI(2)=0; fDNI(3)=1; fDNI(4)=2; fDNI(5)=3;
% fDHI(1)=-1; fDHI(2)=0; fDHI(3)=1; fDHI(4)=2; fDHI(5)=3;

% Generic data on sunrise, noon, sunset hours. It identifies w position
% depending of num_obs (0.26 rad = 1 hour)
deltat = 0.26/num_obs; % w/deltat
wsr = acos(-tan(dec).*tan(lat_rad));
wss = -wsr;
pos_sunrise = (floor(wsr/deltat)==floor(w/deltat));
pos_sunset = (round(wss/deltat)==round(w/deltat));
pos_zero = (round(w/deltat)==0);

values_day = 24*num_obs;
matrixWSR = reshape(pos_sunrise,values_day,[]);
matrixWSS = reshape(pos_sunset,values_day,[]);
matrixW0 = reshape(pos_zero,values_day,[]);

[y1, x1] = find(matrixWSR);
[y2, x2] = find(matrixWSS);
[y3, x3] = find(matrixW0);

% GHI ANNUAL GRAPH --------------------------------------------------------
if var(1)==1
    matrixGHI = reshape(fGHI,values_day,[]);
    
    figure
    if dj(1)>1
        aux = zeros(24*num_obs,dj(1)-1); %
        imagesc([aux matrixGHI]);
    else
        imagesc(matrixGHI);
    end
    
    colormap(Micolormap)
    labels = {'0','1','2','3','4'};
    lcolorbar(labels);
    axis([0 numel(fGHI)/values_day 0 24*num_obs]);
    title([file_name ' GHI'],'Fontsize',16);
    xlabel('Days','Fontsize',14);
    ylabel('# daily observations','Fontsize',14);
    hold on
    plot(x1,y1,'oc');
    plot(x2,y2,'oc');
    plot(x3,y3,'oc');
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',file_name,'_GHI'))
end

% DNI ANNUAL GRAPH --------------------------------------------------------
if var(2)==1
    matrixDNI = reshape(fDNI,values_day,[]);
    
    figure
    if dj(1)>1
        aux = zeros(24*num_obs,dj(1)-1);
        imagesc([aux matrixDNI]);
    else
        imagesc(matrixDNI);
    end
    
    colormap(Micolormap)
    labels = {'0','1','2','3','4'};
    lcolorbar(labels);
    axis([0 numel(fDNI)/values_day 0 24*num_obs]);
    title([file_name ' DNI'],'Fontsize',16);
    xlabel('Days','Fontsize',14);
    ylabel('# daily observations','Fontsize',14);
    hold on
    plot(x1,y1,'oc');
    plot(x2,y2,'oc');
    plot(x3,y3,'oc');
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',file_name,'_DNI'))
end

% DHI ANNUAL GRAPH --------------------------------------------------------
if var(3)==1
    matrixDHI = reshape(fDHI,values_day,[]);
    
    figure
    if dj(1)>1
        aux = zeros(24*num_obs,dj(1)-1);
        figureDHI=[aux matrixDHI];
        imagesc(figureDHI);
    else
        imagesc(matrixDHI);
    end
    colormap(Micolormap)
    labels = {'0','1','2','3','4'};
    lcolorbar(labels);
    axis([0 numel(fDHI)/values_day 0 24*num_obs]);
    title([file_name ' DHI'],'Fontsize',16);
    xlabel('Days','Fontsize',14);
    ylabel('# daily observations','Fontsize',14);
    hold on
    plot(x1,y1,'oc');
    plot(x2,y2,'oc');
    plot(x3,y3,'oc');
    print('-djpeg','-opengl','-r350',strcat(path_fig,'\',file_name,'_DHI'))
end

%% OUTPUT

% DATE PROCESSING: Out in TST
% Centers the instant in the beginning of the period (in days)
% % date_num_out = tst_num-time_corr-(0.5/(num_obs*24));
% date_num_out = tst_num+(0.5/(num_obs*24)); % TANZANIA
% date_vec_out = datevec(date_num_out);
% % output = [date_vec_out,GHIord,fGHI,DNIord,fDNI,DHIord,fDHI];

% DATE PROCESSING: Out in station local time
LT_vec = datevec(days_num_ord);
ouput = [LT_vec GHIord fGHIF DNIord fDNIF DHIord fDHIF];
pos_nodata = (isnan(ouput));
ouput(pos_nodata) = -999;

data.timedata.timezone = timeZ;
data.timedata.stamp = 0;
data.mqc = ouput;
data.astro = astro;
clear input output
dataqc = data;

end
