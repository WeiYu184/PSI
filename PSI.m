function [PSIndex] = PSI(varargin)
%1. Read File with UI
[fileName,filePath] = uigetfile({'*.tif';'*.*'},'Please Select Input Image');
fileNamePath=[filePath,fileName]; %acquire absolute dir
tic
%raw_img=read_ENVIimagefile_img(fileNamePath);
raw_img = imread(fileNamePath);
%[length, weight, depth] = size(I);
disp('Size of input image:');
[row,col,band]=size(raw_img);
imshow(raw_img);
disp([row,col,band]);

%2. Calculate PSI
%2.1 Set Parameters
T1 = 110;   % Default spactral threshold
T2 = 50;    % Default spatial threshold
D = 20;     % Default indicates the total number of direction lines
T1_str = inputdlg('The spectral homogeneity threshold','Set T1');
if(size(T1_str,1)~=0)
    T1 = str2double(T1_str{1});
end
T2_str = inputdlg('Number of pixels in each direction line','Set T2');
if(size(T2_str,1)~=0)
    T2 = str2double(T2_str{1});
end
D_str = inputdlg('Number of directions','Set D');
if(size(D_str,1)~=0)
    D= str2double(D_str{1});
end

%2.2 Calculate PSI
PSIndex = zeros(row,col,D,'double');
%2.2.1 Create a templet for Dirction Lines in advance.
degree = linspace(0,3.14159,D);
ratio_col = cos(degree);  %  ---> right
ratio_row = sin(degree);  %  | up
length = 1:T2;
up_templet_offset_col = fix(length'*ratio_col);
up_templet_offset_row = fix(length'*ratio_row);
down_templet_offset_col = up_templet_offset_col.*(-1);
down_templet_offset_row = up_templet_offset_row.*(-1);
%50个长度的20个横\纵坐标
% 定位方向线上的每一个像素：(templet_offset_col(x,y), templet_offset_row(x,y))

for pi=1:row    % pixel (i,j)
    for pj=1:col
        for dir=1:D  % direction line No.dir
            up_endpoint=zeros(1,2);
            down_endpoint=zeros(1,2);
            up_length = 1;
            down_length = 1;
            %2.2.2 Using templet to extend the direction line
            while (norm(up_endpoint-down_endpoint)<T2)
                %当方向线长度小于50时继续扩展
                %向上扩展一个像元：如果不满足光谱条件则不再继续向上扩展
                if up_length<T2
                    PH=0;
                    diff_row=up_templet_offset_row(up_length,dir);
                    diff_col=up_templet_offset_col(up_length,dir);
                    % 邻像元坐标
                    if((pi+diff_row)>0 &&(pi+diff_row)<(row+1) &&(pj+diff_col)>0 && (pj+diff_col)<(col+1))
                    % 当前邻域(pi,pj),像元(pi+diff_row,pj+diff_col)在第dir条方向线上半部分的异质性测度值
                        for dim = 1:band
                            PH = PH+abs(raw_img(pi+diff_row,pj+diff_col,dim)-raw_img(pi,pj,dim));
                        end%for dim
                    end%for PH
                    if (PH<T1)
                        up_endpoint=[diff_row,diff_col];
                        up_length = up_length+1;
                    else
                        up_length = T2+1;
                    end
                end
                
                 %向下扩展一个像元：如果不满足光谱条件则不再继续向下扩展
                 if down_length<T2
                    PH=0;
                    diff_row=down_templet_offset_row(down_length,dir);
                    diff_col=down_templet_offset_col(down_length,dir);
                    % 邻像元坐标
                    if((pi+diff_row)>0 &&(pi+diff_row)<(row+1) &&(pj+diff_col)>0 && (pj+diff_col)<(col+1))
                    % 当前邻域(pi,pj),像元(pi+diff_row,pj+diff_col)在第dir条方向线上半部分的异质性测度值
                        for dim = 1:band
                            PH = PH+abs(raw_img(pi+diff_row,pj+diff_col,dim)-raw_img(pi,pj,dim));
                        end%for dim
                    end%% Spactral limitation
                    if (PH<T1)
                        down_endpoint=[diff_row,diff_col];
                        down_length = down_length+1;
                    else
                        down_length = T2+1;
                    end
                 end
                 if up_length+down_length>50
                     break;
                 end
            end
            PSIndex(pi,pj,dir) = norm(up_endpoint-down_endpoint);
        end%for dir (pixel)
    end%for pj
    disp(['Finish line No.',num2str(pi)]);
end%for pi

%3. Mapping double to uint8
 % PSIndex_uint8 = uint8(255 * mat2gray(PSIndex));
for i=1:D
    fileName=['pcaPSI',num2str(i),'.tif'];
   % temp=squeeze(PSIndex_uint8(:,:,i));
    temp=imadjust(PSIndex(:,:,i));
    imwrite(temp,fileName);
end

PSIm=zeros(row,col);

for pi = 1:row
    for pj = 1:col
        for i=1:D
            PSIm(pi,pj) = max(PSIm(pi,pj),PSIndex(pi,pj,i));
        end
        PSIm(pi,pj)=PSIm(pi,pj)*3;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 先看看方向线长度对不对
    end
end

PSI_tif = uint8(PSIm);
imshow(PSI_tif);
imwrite(PSI_tif,'PSI_3.tif','tif');
%intPSIm=uint8(PSIm);
%cmap = colormap(jet(256));
%rgb = ind2rgb(intPSIm,cmap);
%imshow(rgb);
%imwrite(rgb,'pca_rgbPSI.tif','tif');
 
%M = reshape(PSIndex,col*row,20); 
%m = single(M);
%%%RES = reshape(feature_after_PCA,row,col,3);
%PSI_PCA=uint8(RES);
%imshow(PSI_PCA);
%imwrite(PSI_PCA,'pca_psi.tif','tif'); 
%temp=imadjust(sum(PSIndex,3));
%imwrite(temp,'PSI.tif');
end
% MBIndex=uint8(MBIndex/(D*(S-1)));
% imwrite(MBIndex,'MBI.tif');
%
% eimg=imadjust(MBIndex);
% imshow(eimg,'Colormap',jet(255));
% t=toc;
% display(t);