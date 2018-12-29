%打开图像
[fileName,filePath] = uigetfile({'*.tif';'*.*'},'Please Select Input Image');
fileNamePath=[filePath,fileName];
[row,col,band]=size(raw_img);
raw_img=imread(fileNamePath);

%计算亮度
brightness=uint8(max(raw_img,[],3));

%构建MBI

%W-TH:
length=2:5:52;%length of a linear Structure Element(SE)
S=size(length,2);%numbers of scale
direction=[0;45;90;135];%four directions are considered
D=size(direction,1);%numbers of directions

W_TH=zeros(S,D,row,col);
for i=1:S
    for j=1:D
        SE=strel('line',length(i),direction(j));
        erosion_img=imerode(brightness,SE);
        reconstruct_img=imreconstruct(erosion_img,brightness);
        W_TH(i,j,:,:)=brightness-reconstruct_img;
    end
end

%计算DMP&MBI
DMP=zeros(S-1,D,row,col);
MBIndex=zeros(row,col);
for i=1:(S-1)
    for j=1:D
        DMP(i,j,:,:)=abs(W_TH(i+1,j,:,:)-W_TH(i,j,:,:));
        MBIndex=MBIndex+double(squeeze(DMP(i,j,:,:)));
    end
end
MBIndex=uint8(MBIndex/(D*(S-1)*5));
imwrite(MBIndex,'MBI.tif');

eimg=imadjust(MBIndex);
imshow(eimg,'Colormap',jet(255));
t=toc;
display(t);

            



