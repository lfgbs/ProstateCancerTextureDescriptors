%% Initial configurations
clc % Clear all text from command window
close all % Close all figures previously opened
clear % Clear previous environment variables
warning('off','images:graycomatrix:scaledImageContainsNan')

list_of_exercises = { 
   'main'
   %'test2'
  };

%% Main -------------------------------------------------------------------

exercise = 'main'; % Define the name of the current exercise
if ismember(exercise, list_of_exercises) %... if exer. in list_of_exercises
  disp(['Executing ' exercise ':'])
  clearvars -except list_of_exercises 

  imagefiles = natsortfiles(dir("/home/luisfgbs/AII/TP2/imgs/ProstateCase*.dcm"));  
  segmentationfiles = natsortfiles(dir("/home/luisfgbs/AII/TP2/imgs/ProstateSeg*.dcm"));
  map_struct=load("cmap.mat");
  map=map_struct(1).cmap;

  cases={'ProstateCase1' 'ProstateCase2' 'ProstateCase3'};
  
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

          tiles=tiledlayout(3,2);
          title(tiles, append('Distribuição do Tumor ', int2str(p) ) )

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

          %Criar os paineis e a estrutura que vai guardar os campos de cada
          %um pixeis das zonas de interesse

          casename=cases(p);
          casename=casename{1};

          img_num=['img_' num2str(i, '%2d')];

          %tamanho dos paineis
          %cada painel vai ser sujeito a uma análise de GLCM
          %dimensões painel = (2n+1)*(2n+1)
          panel_size=2;

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
              tumor.(casename).CG.(img_num).(pixel_count).correlation=[];
              tumor.(casename).CG.(img_num).(pixel_count).energy=[];
              tumor.(casename).CG.(img_num).(pixel_count).homogeneity=[];

          end
      end
  end

  %Cálculo das glcms e propriedades para todos os paineis guardados

  casenames=fieldnames(tumor);
  %percorrer casos clinicos
  for cn=1:size(casenames,1)

      name=casenames(cn);
      casename=name{1};

      %percorrer zonas de interesse
      zones=fieldnames(tumor.(casename));
      for z=1:size(zones,1)

          z_name=zones(z);
          zone=z_name{1};

          Z=waitbar(0, append('Pls wait. Working on ', casename, '. Checking ', zone ));

          %percorrer as imagens do caso
          numbers=fieldnames(tumor.(casename).(zone));

          for n=1:size(numbers,1)
            
              number=numbers(n);
              img_number=number{1};

              waitbar(n/size(numbers,1),Z)

              %aceder a cada um dos pixeis assinalados pelo profissional
              counts=fieldnames(tumor.(casename).(zone).(img_number));

              %criar estrutura para guardar análise de resultados (neste momento é só cálculo de média)
              results.(casename).(zone).(img_number).avg_correlation=0;
              results.(casename).(zone).(img_number).avg_energy=0;
              results.(casename).(zone).(img_number).avg_homogeneity=0;

              for c=1:size(counts,1)

                  count=counts(c);
                  pixel_count=count{1};

                  panel=tumor.(casename).(zone).(img_number).(pixel_count).panel;

                  %calcular gray-level co-occurrence matrix
                  GLCM=graycomatrix(panel, 'Of', [0 1], 'NumLevels', 64, 'GrayLimits', [win_lo win_hi]);

                  %calcular as propriedades
                  properties=graycoprops(GLCM, 'all');

                  %saving computed values
                  tumor.(casename).(zone).(img_number).(pixel_count).glcm=GLCM;
                  tumor.(casename).(zone).(img_number).(pixel_count).correlation=properties.Correlation;
                  tumor.(casename).(zone).(img_number).(pixel_count).energy=properties.Energy;
                  tumor.(casename).(zone).(img_number).(pixel_count).homogeneity=properties.Homogeneity;

                  results.(casename).(zone).(img_number).avg_correlation=results.(casename).(zone).(img_number).avg_correlation+properties.Correlation;
                  results.(casename).(zone).(img_number).avg_energy=results.(casename).(zone).(img_number).avg_energy+properties.Energy;
                  results.(casename).(zone).(img_number).avg_homogeneity=results.(casename).(zone).(img_number).avg_homogeneity+properties.Homogeneity;            
              end

              results.(casename).(zone).(img_number).avg_correlation=results.(casename).(zone).(img_number).avg_correlation/size(counts,1);
              results.(casename).(zone).(img_number).avg_energy=results.(casename).(zone).(img_number).avg_energy/size(counts,1);
              results.(casename).(zone).(img_number).avg_homogeneity=results.(casename).(zone).(img_number).avg_homogeneity/size(counts,1);
                
          end 

          delete(Z)
          
      end
  end

  %VISUALIZAÇÃO

  %Representar as propriedades usando a imagem 6 do caso clínico n
  caseID=3;
  pimg = dicomread(strcat("/home/luisfgbs/AII/TP2/imgs/", imagefiles(caseID).name));
  pimg=squeeze(pimg);
  simg = dicomread(strcat("/home/luisfgbs/AII/TP2/imgs/", segmentationfiles(caseID).name));
  simg=squeeze(simg);

  %ir buscar a imagem
  trial=pimg(:,:,6);
  segtrial=simg(:,:,6);

  figure
  set(gcf, 'Position',  [1000, 150, 800, 700])
  imshow(trial, [win_lo win_hi])

  casenames={'ProstateCase1', 'ProstateCase2' ,'ProstateCase3'};
  cn=casenames(caseID);
  casename=cn{1};

  %carregar valores
  pixels_cg=fieldnames(tumor.(casename).CG.img_6);
  pixels_pz=fieldnames(tumor.(casename).PZ.img_6);

  correlation_values_cg=zeros(2303,5);
  correlation_values_pz=zeros(769,5);
  energy_values_cg=zeros(2303,5);
  energy_values_pz=zeros(769,5);
  homogeneity_values_cg=zeros(2303,5);
  homogeneity_values_pz=zeros(769,5);

  for pixel=1:size(pixels_cg,1)
     px=pixels_cg(pixel);
     px=px{1};
     px_values=tumor.(casename).CG.img_6.(px);

     correlation_color_idx=round((px_values.correlation+1)*122.5);
     correlation_color=map(correlation_color_idx, :);

     energy_color_idx=round(px_values.energy*255);
     energy_color=map(energy_color_idx, :);

     homogeneity_color_idx=round(px_values.homogeneity*255);
     homogeneity_color=map(homogeneity_color_idx, :);

     correlation_values_cg(pixel,:)=[correlation_color(1) correlation_color(2) correlation_color(3) px_values.y px_values.x];
     energy_values_cg(pixel,:)=[energy_color(1) energy_color(2) energy_color(3) px_values.y px_values.x];
     homogeneity_values_cg(pixel, :)=[homogeneity_color(1) homogeneity_color(2) homogeneity_color(3) px_values.y px_values.x];

  end

  for pixel=1:size(pixels_pz,1)
     px=pixels_pz(pixel);
     px=px{1};
     px_values=tumor.(casename).PZ.img_6.(px);

     correlation_color_idx=round((px_values.correlation+1)*122.5);
     correlation_color=map(correlation_color_idx, :);

     energy_color_idx=round(px_values.energy*255);
     energy_color=map(energy_color_idx, :);

     homogeneity_color_idx=round(px_values.homogeneity*255);
     homogeneity_color=map(homogeneity_color_idx, :);

     correlation_values_pz(pixel,:)=[correlation_color(1) correlation_color(2) correlation_color(3) px_values.y px_values.x];
     energy_values_pz(pixel,:)=[energy_color(1) energy_color(2) energy_color(3) px_values.y px_values.x];
     homogeneity_values_pz(pixel, :)=[homogeneity_color(1) homogeneity_color(2) homogeneity_color(3) px_values.y px_values.x];

  end

  figure
  set(gcf, 'Position',  [1000, 150, 800, 700]) 

  subplot(2,2,1)
  imshow(segtrial, [0 2])
  title('Segmentation')

  subplot(2,2,2)
  imshow(trial, [win_lo win_hi])
  title('Correlation')
  hold on;

  for v=1:size(correlation_values_cg,1)
        plot(correlation_values_cg(v,5), correlation_values_cg(v,4), 'color' , [correlation_values_cg(v,1) correlation_values_cg(v,2) correlation_values_cg(v,3)] ,'Marker', '.', 'MarkerSize', 0.01)
  end
  for v=1:size(correlation_values_pz,1)
        plot(correlation_values_pz(v,5), correlation_values_pz(v,4), 'color' , [correlation_values_pz(v,1) correlation_values_pz(v,2) correlation_values_pz(v,3)] ,'Marker', '.', 'MarkerSize', 0.01)
  end

  
  subplot(2,2,3)
  imshow(trial, [win_lo win_hi])
  title('Energy')
  hold on;

  for v=1:size(energy_values_cg,1)
        plot(energy_values_cg(v,5), energy_values_cg(v,4), 'color' , [energy_values_cg(v,1) energy_values_cg(v,2) energy_values_cg(v,3)] ,'Marker', '.', 'MarkerSize', 0.01)
  end
  for v=1:size(energy_values_pz,1)
        plot(energy_values_pz(v,5), energy_values_pz(v,4), 'color' , [energy_values_pz(v,1) energy_values_pz(v,2) energy_values_pz(v,3)] ,'Marker', '.', 'MarkerSize', 0.01)
  end

  subplot(2,2,4)
  imshow(trial, [win_lo win_hi])
  title('Homogeneity')
  hold on;

  for v=1:size(homogeneity_values_cg,1)
        plot(homogeneity_values_cg(v,5), homogeneity_values_cg(v,4), 'color' , [homogeneity_values_cg(v,1) homogeneity_values_cg(v,2) homogeneity_values_cg(v,3)] ,'Marker','.' , 'MarkerSize', 0.01)
  end
  for v=1:size(homogeneity_values_pz,1)
        plot(homogeneity_values_pz(v,5), homogeneity_values_pz(v,4), 'color' , [homogeneity_values_pz(v,1) homogeneity_values_pz(v,2) homogeneity_values_pz(v,3)] ,'Marker','.' , 'MarkerSize', 0.01)
  end

  %Análise
  %plots das averages
  casenames=fieldnames(tumor);

  for cn=1:size(casenames,1)

      name=casenames(cn);
      casename=name{1};

      figure
      set(gcf, 'Position',  [1000, 150, 800, 700]) 

      imgs=fieldnames(results.(casename).CG);

      correlation_averages_cg=zeros(size(imgs,1), 1);
      energy_averages_cg=zeros(size(imgs,1), 1);
      homogeneity_averages_cg=zeros(size(imgs,1), 1);
    
      for n=1:size(imgs)
    
          number=imgs(n);
          img_number=number{1};
          
          correlation_averages_cg(n)=results.(casename).CG.(img_number).avg_correlation;
          energy_averages_cg(n)=results.(casename).CG.(img_number).avg_energy;
          homogeneity_averages_cg(n)=results.(casename).CG.(img_number).avg_homogeneity;
    
      end
    
      imgs=fieldnames(results.(casename).PZ);
    
      correlation_averages_pz=zeros(size(imgs,1), 1);
      energy_averages_pz=zeros(size(imgs,1), 1);
      homogeneity_averages_pz=zeros(size(imgs,1), 1);
    
      for n=1:size(imgs)
    
          number=imgs(n);
          img_number=number{1};
          
          correlation_averages_pz(n)=results.(casename).PZ.(img_number).avg_correlation;
          energy_averages_pz(n)=results.(casename).PZ.(img_number).avg_energy;
          homogeneity_averages_pz(n)=results.(casename).PZ.(img_number).avg_homogeneity;
    
      end
    
      subplot(2,3,1)
      plot(correlation_averages_cg, 'LineWidth', 1, 'Marker', '.', 'MarkerSize', 10)
      title({'Correlation value (CG)', casename})
    
      subplot(2,3,2)
      plot(energy_averages_cg, 'LineWidth', 1, 'Marker', '.', 'MarkerSize', 10)
      title({'Energy value (CG)', casename})
    
      subplot(2,3,3)
      plot(homogeneity_averages_cg, 'LineWidth', 1, 'Marker', '.', 'MarkerSize', 10)
      title({'Homogeneity value (CG)', casename})
    
      subplot(2,3,4)
      plot(correlation_averages_pz, 'LineWidth', 1, 'Marker', '.', 'MarkerSize', 10)
      title({'Correlation value (PZ)', casename})
    
      subplot(2,3,5)
      plot(energy_averages_pz, 'LineWidth', 1, 'Marker', '.', 'MarkerSize', 10)
      title('Energy value (PZ)', casename)
    
      subplot(2,3,6)
      plot(homogeneity_averages_pz, 'LineWidth', 1, 'Marker', '.', 'MarkerSize', 10)
      title('Homogeneity value (PZ)', casename)

  end

end
