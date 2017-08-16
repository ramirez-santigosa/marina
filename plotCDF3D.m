function [ ] = plotCDF3D( figCDF, titleFig, fileName )
%PLOTCDF3D Plots a 3D graph of multiple CDFs.
%   INPUT:
%   figCDF: CDFs to plot (n CDFs X n bins)
%   titleFig: Title of the graph
%   fileName: File name of the printed graph
%
% - F. Mendoza (June 2017)

headers_m = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dic'}; % Headers months
figCDF = figCDF';

% Bar3
figure; b = bar3(1:10,figCDF); 
for i = 1:size(figCDF,2) % Solid color bar CDF
    cdata = b(i).CData;
    k = 1;
    for j = 0:6:(6*size(figCDF,1)-6)
        cdata(j+1:j+6,:) = figCDF(k,i);
        k = k+1;
    end
    b(i).CData = cdata;
end
for k = 1:length(b) % Gradient color bar CDF
    zdata = b(k).ZData;
    b(k).CData = zdata;
    b(k).FaceColor = 'interp';
end
colormap(jet)
title(titleFig), xlabel('Months'), ylabel('Bins'), zlabel('CDF')
view([-127 30]), xticklabels(headers_m)
print('-dtiff','-opengl','-r350',fileName)

% Color bar by bin
% figure; h3 = axes; bar3(1:12,figCDF');
% title(titleFig), xlabel('Bins'), ylabel('Months'), zlabel('CDF')
% view([-34.7 38]), set(h3,'YTickLabel',headers_m,'YDir', 'reverse')

% Continous CDF
% [mm,bb] = meshgrid(1:12,1:size(figCDF,1));
% figure; plot3(bb,mm,figCDF)
% title(titleFig), xlabel('Bins'), ylabel('Months'), zlabel('CDF')
% grid on, xlim([1 size(figCDF,2)]), ylim([1 12]), legend(headers_m)

end
