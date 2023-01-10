%% Initial configurations
clc % Clear all text from command window
close all % Close all figures previously opened
clear % Clear previous environment variables
warning('off','images:graycomatrix:scaledImageContainsNan')

list_of_exercises = { 
   %'main'
   'test'
   %'test2'
  };


%% Main -------------------------------------------------------------------

exercise = 'main'; 
if ismember(exercise, list_of_exercises) 
  disp(['Executing ' exercise ':'])
  clearvars -except list_of_exercises 

  imagefiles = natsortfiles(dir("/home/luisfgbs/AII/TP2/imgs/ProstateCase*.dcm"));  
  segmentationfiles = natsortfiles(dir("/home/luisfgbs/AII/TP2/imgs/ProstateSeg*.dcm"));
  
  %percorrer todos os casos clínicos disponibilizados
  for p=1:size(imagefiles,1)

      %IMAGENS DA PROSTATA
      disp(imagefiles(p).name)
      pimg = dicomread(strcat("/home/luisfgbs/AII/TP2/imgs/", imagefiles(p).name));
      pimg=squeeze(pimg);

      %SEGMENTAÇÃO TUMOR
      simg= dicomread(strcat("/home/luisfgbs/AII/TP2/imgs/", segmentationfiles(p).name));
      simg=squeeze(simg);
    
      %Metadata das imagens
      pinfo=dicominfo(strcat("/home/luisfgbs/AII/TP2/imgs/", imagefiles(p).name), 'UseDictionaryVR', true);
      sinfo=dicominfo(strcat("/home/luisfgbs/AII/TP2/imgs/", segmentationfiles(p).name), 'UseDictionaryVR', true); 

      %melhor gama de representação
      window_center=pinfo.WindowCenter;
      window_width=pinfo.WindowWidth;
      win_lo=window_center-window_width/2;
      win_hi=window_center+window_width/2;
    
      set(gcf, 'Position',  [1000, 150, 800, 700])    
    
      %percorrer as imagens dentro cada um dos casos clínicos
      for i=1:size(pimg, 3)

          tiles=tiledlayout(2,2);
          title(tiles,'Distribuição do Tumor')

          nexttile
          p_slice=pimg(:,:,i);
          imshow(p_slice, [win_lo win_hi])
          title('Prostate')
    
          nexttile
          s_slice=simg(:,:,i);
          imshow(s_slice, []);
          title('Segmentation')

          nexttile   
          imshow(p_slice, [win_lo win_hi])
          title('Boundary demarcation')
          hold on;

          bound=bwboundaries(s_slice);
          %se tiver sido identificado tumor desenhar contorno
          if size(bound,1)>0
              x=bound{1,1}(:,1);
              y=bound{1,1}(:,2);
              plot(y,x, 'r', 'LineWidth', 1)
          end

          nexttile
          zoi=p_slice(:,:);
          zoi(~s_slice)=nan;
        
          imshow(zoi, [win_lo win_hi]);
          title('Roi extraction')
    
          pause(0.2)    
      end

  end

end

%% Test -------------------------------------------------------------------

exercise = 'test'; % Define the name of the current exercise
if ismember(exercise, list_of_exercises) %... if exer. in list_of_exercises
  disp(['Executing ' exercise ':'])
  clearvars -except list_of_exercises 

  imagefiles = natsortfiles(dir("/home/luisfgbs/AII/TP2/imgs/ProstateCase*.dcm"));  
  segmentationfiles = natsortfiles(dir("/home/luisfgbs/AII/TP2/imgs/ProstateSeg*.dcm"));

  cases={'ProstateCase1' 'ProstateCase2' 'ProstateCase3'};

  tumor.ProstateCase1=[];
  tumor.ProstateCase2=[];
  tumor.ProstateCase3=[];
  
  %percorrer todos os casos clínicos disponibilizados
  for p=1:size(imagefiles,1)

      %IMAGENS DA PROSTATA
      disp(imagefiles(p).name)
      pimg = dicomread(strcat("/home/luisfgbs/AII/TP2/imgs/", imagefiles(p).name));
      pimg=squeeze(pimg);

      %SEGMENTAÇÃO TUMOR
      simg= dicomread(strcat("/home/luisfgbs/AII/TP2/imgs/", segmentationfiles(p).name));
      simg=squeeze(simg);
    
      %Metadata das imagens
      pinfo=dicominfo(strcat("/home/luisfgbs/AII/TP2/imgs/", imagefiles(p).name), 'UseDictionaryVR', true);
      sinfo=dicominfo(strcat("/home/luisfgbs/AII/TP2/imgs/", segmentationfiles(p).name), 'UseDictionaryVR', true); 

      %melhor gama de representação
      window_center=pinfo.WindowCenter;
      window_width=pinfo.WindowWidth;
      win_lo=window_center-window_width/2;
      win_hi=window_center+window_width/2;
    
      set(gcf, 'Position',  [1000, 150, 800, 700])    

      %preparar para receber rois

      for i=1:size(pimg, 3)
          img=simg(:,:,i);
          sz=0;

          if all(img(:)==0)
              sz=sz+1;
          end
      end

      all_zoi=zeros(size(pimg,1), size(pimg,2), sz);
    
      %percorrer as imagens dentro cada um dos casos clínicos
      for i=1:size(pimg, 3)

          tiles=tiledlayout(2,2);
          title(tiles, strcat('Distribuição do Tumor ', int2str(p) ) )

          p_slice=pimg(:,:,i);
          s_slice=simg(:,:,i);
          zoi=double(p_slice(:,:));
          zoi(~s_slice)=nan;

          nexttile
          imshow(p_slice, [win_lo win_hi])
          title('Prostate')
    
          nexttile
          imshow(s_slice, []);
          title('Segmentation')

          nexttile   
          imshow(p_slice, [win_lo win_hi])
          title('Boundary demarcation')
          hold on;

          bound=bwboundaries(s_slice);
          %se tiver sido identificado tumor desenhar contorno
          if size(bound,1)>0
              x=bound{1,1}(:,1);
              y=bound{1,1}(:,2);
              plot(y,x, 'r', 'LineWidth', 1)
              all_zoi(:,:,i)=zoi;
          end

          nexttile        
          imshow(zoi, [win_lo win_hi]);
          title('Roi extraction')
 
          pause(0.2)    
      end

      figure

      for z=1:size(all_zoi,3)

          offsets=[0 5; -5 5; -5 0; -5 -5];
          GLCMS=graycomatrix(all_zoi(:,:,z), 'Of', offsets, 'NumLevels', 64, 'GrayLimits', [win_lo win_hi]);
        
          for k=1:4
              subplot(2,2,k)
              imshow(GLCMS(:,:,k), [])
          end

          pause(0.2)
      end

  end

end


%% Test2 -------------------------------------------------------------------

exercise = 'test2'; % Define the name of the current exercise
if ismember(exercise, list_of_exercises) %... if exer. in list_of_exercises
  disp(['Executing ' exercise ':'])
  clearvars -except list_of_exercises 

  imagefiles = natsortfiles(dir("/home/luisfgbs/AII/TP2/imgs/ProstateCase*.dcm"));  
  segmentationfiles = natsortfiles(dir("/home/luisfgbs/AII/TP2/imgs/ProstateSeg*.dcm"));
  
  %percorrer todos os casos clínicos disponibilizados
  for p=1:size(imagefiles,1)

      %IMAGENS DA PROSTATA
      disp(imagefiles(p).name)
      pimg = dicomread(strcat("/home/luisfgbs/AII/TP2/imgs/", imagefiles(p).name));
      pimg=squeeze(pimg);

      %SEGMENTAÇÃO TUMOR
      simg= dicomread(strcat("/home/luisfgbs/AII/TP2/imgs/", segmentationfiles(p).name));
      simg=squeeze(simg);
    
      %Metadata das imagens
      pinfo=dicominfo(strcat("/home/luisfgbs/AII/TP2/imgs/", imagefiles(p).name), 'UseDictionaryVR', true);
      sinfo=dicominfo(strcat("/home/luisfgbs/AII/TP2/imgs/", segmentationfiles(p).name), 'UseDictionaryVR', true); 

      %melhor gama de representação
      window_center=pinfo.WindowCenter;
      window_width=pinfo.WindowWidth;
      win_lo=window_center-window_width/2;
      win_hi=window_center+window_width/2;
    
      set(gcf, 'Position',  [1000, 150, 800, 700])    

      %preparar para receber rois
      all_zoi=zeros(size(pimg));
    
      %percorrer as imagens dentro cada um dos casos clínicos
      for i=1:size(pimg, 3)
          img=simg(:,:,i);
           disp(all(img(:)==0))
      end

  end

end