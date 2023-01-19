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

  cases={'ProstateCase1' 'ProstateCase2' 'ProstateCase3'};
  
  %percorrer todos os casos clínicos disponibilizados
  for p=1:size(imagefiles,1)

      casename=cases(p);
      casename=casename{1};
       
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

          tiles=tiledlayout(3,2);
          title(tiles, strcat('Distribuição do Tumor ', int2str(p) ) )

          %MR da prostata
          p_slice=pimg(:,:,i);
          %segmentação
          s_slice=simg(:,:,i);

          %analisar possíveis regiões da segmentação (zona peripheral PZ,
          %glândula central CG

          %Central Gland 
          cg_mask=s_slice==2;
          cg=double(p_slice(:,:));
          cg(~cg_mask)=nan;
          nexttile
          imshow(cg, [win_lo win_hi])
          title('Central Gland')
          
          %PZ
          pz_mask=s_slice==1;
          pz=double(p_slice(:,:));
          pz(~pz_mask)=nan;
          nexttile
          imshow(pz, [win_lo win_hi])
          title('Peripheral Zone')

          %Valores da imagem original mas apenas na região de interesse
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
          end

          nexttile        
          imshow(zoi, [win_lo win_hi]);
          title('Roi extraction')
 
          pause(0.1)    

          %fazer o estudo do GLCMs para cada um dos pixeis das região de
          %interesse CG e PZ

          img_num=['img_' num2str(i, '%2d')];

          %tamanho dos paineis
          %cada painel vai ser sujeito a uma análise de GLCM
          panel_size=4;

          %PZ
          [y,x]=find(pz>0);

          %percorrer cada um dos pixeis que compoem a zona periferica
          for k=1:size(y,1)

              pixel_count=['px_' num2str(k, '%2d')];

              panel=p_slice(y(k)-panel_size:y(k)+panel_size, x(k)-panel_size:x(k)+panel_size);

              tumor.(casename).PZ.(img_num).(pixel_count).x=x(k);
              tumor.(casename).PZ.(img_num).(pixel_count).y=y(k);
              tumor.(casename).PZ.(img_num).(pixel_count).panel=panel;
              tumor.(casename).PZ.(img_num).(pixel_count).glcm=[];
              tumor.(casename).PZ.(img_num).(pixel_count).contrast=[];
              tumor.(casename).PZ.(img_num).(pixel_count).correlation=[];
              tumor.(casename).PZ.(img_num).(pixel_count).energy=[];
              tumor.(casename).PZ.(img_num).(pixel_count).homogeneity=[];
              
              %offsets=[0 1; -1 1; -1 0; -1 -1];
              %GLCMS=graycomatrix(panel, 'Of', offsets, 'NumLevels', 64, 'GrayLimits', [win_lo win_hi]);

              %{
              %VISUALIZAÇÃO DAS GLCMs
              for g=1:4
                  subplot(2,2,g)
                  imshow(GLCMS(:,:,g), [])
              end
    
              pause(0.1)
              %}

          end

          %CG
          [y,x]=find(cg>0);

          %percorrer cada um dos pixeis que compoem a glândula central
          for k=1:size(y,1)

              pixel_count=['px_' num2str(k, '%2d')];

              panel=p_slice(y(k)-panel_size:y(k)+panel_size, x(k)-panel_size:x(k)+panel_size);

              tumor.(casename).CG.(img_num).(pixel_count).x=x(k);
              tumor.(casename).CG.(img_num).(pixel_count).y=y(k);
              tumor.(casename).CG.(img_num).(pixel_count).panel=panel;
              tumor.(casename).CG.(img_num).(pixel_count).glcm=[];
              tumor.(casename).CG.(img_num).(pixel_count).contrast=[];
              tumor.(casename).CG.(img_num).(pixel_count).correlation=[];
              tumor.(casename).CG.(img_num).(pixel_count).energy=[];
              tumor.(casename).CG.(img_num).(pixel_count).homogeneity=[];

              
              %offsets=[0 1; -1 1; -1 0; -1 -1];
              %GLCMS=graycomatrix(panel, 'Of', offsets, 'NumLevels', 64, 'GrayLimits', [win_lo win_hi]);

          end

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
  
  %percorrer todos os casos clínicos disponibilizados
  for p=1:size(imagefiles,1)

      casename=cases(p);
      casename=casename{1};
       
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

          tiles=tiledlayout(3,2);
          title(tiles, strcat('Distribuição do Tumor ', int2str(p) ) )

          %MR da prostata
          p_slice=pimg(:,:,i);
          %segmentação
          s_slice=simg(:,:,i);

          %analisar possíveis regiões da segmentação (zona peripheral PZ,
          %glândula central CG

          %Central Gland 
          cg_mask=s_slice==2;
          cg=double(p_slice(:,:));
          cg(~cg_mask)=nan;
          nexttile
          imshow(cg, [win_lo win_hi])
          title('Central Gland')
          
          %PZ
          pz_mask=s_slice==1;
          pz=double(p_slice(:,:));
          pz(~pz_mask)=nan;
          nexttile
          imshow(pz, [win_lo win_hi])
          title('Peripheral Zone')

          %Valores da imagem original mas apenas na região de interesse
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
          end

          nexttile        
          imshow(zoi, [win_lo win_hi]);
          title('Roi extraction')
 
          pause(0.01)    

          %fazer o estudo do GLCMs para cada um dos pixeis das região de
          %interesse CG e PZ

          img_num=['img_' num2str(i, '%2d')];

          %tamanho dos paineis
          %cada painel vai ser sujeito a uma análise de GLCM
          panel_size=4;

          %PZ
          [y,x]=find(pz>0);

          %percorrer cada um dos pixeis que compoem a zona periferica
          for k=1:size(y,1)

              pixel_count=['px_' num2str(k, '%2d')];

              panel=p_slice(y(k)-panel_size:y(k)+panel_size, x(k)-panel_size:x(k)+panel_size);

              tumor.(casename).PZ.(img_num).(pixel_count).x=x(k);
              tumor.(casename).PZ.(img_num).(pixel_count).y=y(k);
              tumor.(casename).PZ.(img_num).(pixel_count).panel=panel;
              tumor.(casename).PZ.(img_num).(pixel_count).glcm=[];
              tumor.(casename).PZ.(img_num).(pixel_count).contrast=[];
              tumor.(casename).PZ.(img_num).(pixel_count).correlation=[];
              tumor.(casename).PZ.(img_num).(pixel_count).energy=[];
              tumor.(casename).PZ.(img_num).(pixel_count).homogeneity=[];

          end

          %CG
          [y,x]=find(cg>0);

          %percorrer cada um dos pixeis que compoem a glândula central
          for k=1:size(y,1)

              pixel_count=['px_' num2str(k, '%2d')];

              panel=p_slice(y(k)-panel_size:y(k)+panel_size, x(k)-panel_size:x(k)+panel_size);

              tumor.(casename).CG.(img_num).(pixel_count).x=x(k);
              tumor.(casename).CG.(img_num).(pixel_count).y=y(k);
              tumor.(casename).CG.(img_num).(pixel_count).panel=panel;
              tumor.(casename).CG.(img_num).(pixel_count).glcm=[];
              tumor.(casename).CG.(img_num).(pixel_count).contrast=[];
              tumor.(casename).CG.(img_num).(pixel_count).correlation=[];
              tumor.(casename).CG.(img_num).(pixel_count).energy=[];
              tumor.(casename).CG.(img_num).(pixel_count).homogeneity=[];

          end

      end

  end

  %Cálculo das glcms e propriedades para todos os paineis guardados

  casenames=fieldnames(tumor);
  %percorrer casos clinicos
  for name=casenames

      casename=name{1};

      %percorrer zonas de interesse
      zones=fieldnames(tumor.(casename));
      for zone=zones

          z_name=zone{1};

          %percorrer as imagens do caso
          numbers=fieldnames(tumor.(casename).(z_name));

          for number=numbers
            
              img_number=number{1};

              %aceder a cada um dos pixeis assinalados pelo profissional
              counts=fieldnames(tumor.(casename).(z_name).(img_number));

              for count=counts

                  pixel_count=count{1};

                  panel=tumor.(casename).(z_name).(img_number).(pixel_count).panel;

                  %calcular gray-level co-occurrence matrix
                  GLCM=graycomatrix(panel, 'Of', [0 1], 'NumLevels', 64, 'GrayLimits', [win_lo win_hi]);

                  %calcular as propriedades
                  properties=graycoprops(GLCM, 'all');

                  %saving computed values
                  tumor.(casename).(z_name).(img_number).(pixel_count).glcm=GLCM;
                  tumor.(casename).(z_name).(img_number).(pixel_count).contrast=properties.Contrast;
                  tumor.(casename).(z_name).(img_number).(pixel_count).correlation=properties.Correlation;
                  tumor.(casename).(z_name).(img_number).(pixel_count).energy=properties.Energy;
                  tumor.(casename).(z_name).(img_number).(pixel_count).homogeneity=properties.Homogeneity;

                  disp('HERE')
            
              end

          end           
            
      end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%FUNCTIONS%%%%%%%%%%%%%%%%%%
