function  user_input_emi(input_tis_filepath, input_mui_filepath)

    clc,close all;

   %% 输入不同算法的系数文件
    input_coef_filepath = 'E:\OneDrive\Phd\c_paper\3_thirdpaper\new_version\data\step1_simulation_coef\diff_method_simulation_coef_data';
    % folder_name = ["fun1_OV1992", "fun2_FO1996", "fun3_PR1984", "fun4_UC1985", "fun5_BL_WD",...
            % "fun6_PP1991", "fun7_VI1991", "fun8_UL1994", "fun9_WA2014"];
    % 首先获取到可见光
    mui_data = readgeoraster(input_mui_filepath);
    %设置多个发射率值
    emi2_water_ice = 0.9883;
    emi3_water_ice = 0.9735;
    % 粗粒径雪和冰
    emi2_snow_ice = 0.9863;
    emi3_snow_ice = 0.9635;
    % 不同粒径雪的平均值
    emi2_snow = 0.9910;
    emi3_snow = 0.9798;
    % 纯水的发射率值
    %如果大于273.15K，则设置为水的发射率。
    emi2_water = 0.9899;
    emi3_water = 0.9869;


    % 判断值大小，如果大于0.7，则设置不同类型雪的发射率；如果是小于0.15则给定冰和雪的发射率均质，大于0.15小于0.6则给定粗颗粒雪和冰的均质
    emissivity_band2 =  emi2_water_ice * ones(size(mui_data));  % 默认值
    emissivity_band3 =  emi3_water_ice* ones(size(mui_data));
    class_data = 0* ones(size(mui_data));
    % 为大于0.15的值
    emissivity_band2(mui_data>1500) = emi2_snow_ice;
    emissivity_band3(mui_data> 1500) =  emi3_snow_ice;
    class_data(mui_data> 1500) =  1;
    % 大于0.6的赋值
    emissivity_band2(mui_data>7000) = emi2_snow;
    emissivity_band3(mui_data> 7000) =  emi3_snow;
    class_data(mui_data> 7000) = 2;
    ave_emissivity = (emissivity_band2+emissivity_band3)/2;
    dif_emissivity = emissivity_band2-emissivity_band3;

    DN = readgeoraster(input_tis_filepath);
    DN2 = double(DN(:,:,2));
    DN3 = double(DN(:,:,3));
    % Get Tiff info
    info = geotiffinfo(input_tis_filepath);
    % % disp(info);
    
    %% 辐射校正
    disp('开始辐射校正...')
    L2 = DN2.*0.003946 + 0.124622;
    L3 = DN3.*0.005329 + 0.222530;
    %% 得到星上亮温值
    [BT2,BT3] = radiance2BT(L2,L3);
    [parent_folder, filename, ~] = fileparts(input_tis_filepath);
    BT2_filepath=strcat(parent_folder,filesep,filename,'_','_new_bt2.tif');
     if exist(BT2_filepath, 'file')
        delete(BT2_filepath);
     end
     geotiffwrite(BT2_filepath,BT2,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
    BT3_filepath=strcat(parent_folder,filesep,filename,'_','_new_bt3.tif');
     if exist(BT3_filepath, 'file')
        delete(BT3_filepath);
     end
     geotiffwrite(BT3_filepath,BT3,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
    % 清除变量
    clear L2 L3 DN  DN3
    %% 计算地表温度值
    
    disp('计算地表温度...')
    % average_BT =(BT2+BT3)/2;
    % diff_BT    = (BT2-BT3);
    % 

   
%（3）fun3_PR1984
     disp('计算第三个fun3_PR1984...')
     input_sub_coef_file = strcat(input_coef_filepath, filesep, 'fun3_PR1984', filesep, 'fun3_PR1984.xlsx');
     data_table_PR1984 = readtable(input_sub_coef_file); % 获取到多个角度下的系数
     data_table_PR1984_0 = table2array(data_table_PR1984(1,:)); % 获取到第一行数据即可
     disp(['pr1984的系数为', data_table_PR1984_0])
     % 根据公式，计算地表温度
     lst_data_PR1984 =data_table_PR1984_0(1,1) + data_table_PR1984_0(1,2).*BT2 + data_table_PR1984_0(1,3).*(BT2-BT3) + data_table_PR1984_0(1,4).*BT2.*emissivity_band2 +...
         data_table_PR1984_0(1,5).*(BT2-BT3).*(1-emissivity_band2) +data_table_PR1984_0(1,6).*(BT3.*dif_emissivity);
     lst_data_PR1984(DN2==0)=nan; % 将背景值设置为nan

     % 判断如果值中有大于273.15K的值，那么就给定其水体的发射率。
     emissivity_band2( lst_data_PR1984>273.15) = emi2_water;
     emissivity_band3( lst_data_PR1984>273.15) =  emi3_water;
     ave_emissivity = (emissivity_band2+emissivity_band3)/2;
     dif_emissivity = emissivity_band2-emissivity_band3;
     % 再次反演一遍
     lst_data_PR1984 =data_table_PR1984_0(1,1) + data_table_PR1984_0(1,2).*BT2 + data_table_PR1984_0(1,3).*(BT2-BT3) + data_table_PR1984_0(1,4).*BT2.*emissivity_band2 +...
         data_table_PR1984_0(1,5).*(BT2-BT3).*(1-emissivity_band2) +data_table_PR1984_0(1,6).*(BT3.*dif_emissivity);
     lst_data_PR1984(DN2==0)=nan; % 将背景值设置为nan
     % 将结果保存为整形数值
     lst_data_PR1984 = int32(lst_data_PR1984*1000);
     lst_out_PR1984=strcat(parent_folder,filesep,filename,'_','pr1984_retrieval_new_emi.tif');
     emi2_out=strcat(parent_folder,filesep,filename,'_','new_emi2.tif');
     emi3_out=strcat(parent_folder,filesep,filename,'_','new_emi3.tif');
     class_out = strcat(parent_folder,filesep,filename,'_','new_class_map.tif');
     if exist(lst_out_PR1984, 'file')
        delete(lst_out_PR1984);
     end
     geotiffwrite(lst_out_PR1984, lst_data_PR1984,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
     geotiffwrite( emi2_out, emissivity_band2,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
     geotiffwrite( emi3_out, emissivity_band3,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
     geotiffwrite( class_out, class_data,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
     clear lst_data_PR1984


     %（7）fun7_VI1991
     disp('计算第七个fun7_VI1991...')
     input_sub_coef_file = strcat(input_coef_filepath, filesep, 'fun7_VI1991', filesep, 'fun7_VI1991.xlsx');
     data_table_VI1991 = readtable(input_sub_coef_file); % 获取到多个角度下的系数
     data_table_VI1991_0 = table2array(data_table_VI1991(1,:)); % 获取到第一行数据即可
     % 根据公式，计算地表温度
     lst_data_VI1991 =data_table_VI1991_0(1,1) + data_table_VI1991_0(1,2).*BT2 + data_table_VI1991_0(1,3).*(BT2-BT3)...
         + data_table_VI1991_0(1,4).*(1-ave_emissivity)./ave_emissivity + data_table_VI1991_0(1,5).*(dif_emissivity./ave_emissivity);
     lst_data_VI1991(DN2==0)=nan; % 将背景值设置为nan

      % 判断如果值中有大于273.15K的值，那么就给定其水体的发射率。
     emissivity_band2( lst_data_VI1991>273.15) = emi2_water;
     emissivity_band3(lst_data_VI1991>273.15) =  emi3_water;
     ave_emissivity = (emissivity_band2+emissivity_band3)/2;
     dif_emissivity = emissivity_band2-emissivity_band3;
     %再反演一遍
      % 根据公式，计算地表温度
     lst_data_VI1991 =data_table_VI1991_0(1,1) + data_table_VI1991_0(1,2).*BT2 + data_table_VI1991_0(1,3).*(BT2-BT3)...
         + data_table_VI1991_0(1,4).*(1-ave_emissivity)./ave_emissivity + data_table_VI1991_0(1,5).*(dif_emissivity./ave_emissivity);
     lst_data_VI1991(DN2==0)=nan; % 将背景值设置为nan
     % 将结果保存为整形数值
     lst_data_VI1991 = int32(lst_data_VI1991*1000);
     lst_out_VI1991=strcat(parent_folder,filesep,filename,'_','vi1991_retrieval_new_emi.tif');
     if exist(lst_out_VI1991, 'file')
        delete(lst_out_VI1991)
     end
     geotiffwrite(lst_out_VI1991, lst_data_VI1991,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
     clear  lst_data_VI1991

      %（8）fun8_UL1994
     disp('计算第八个fun8_UL1994...')
     input_sub_coef_file = strcat(input_coef_filepath, filesep, 'fun8_UL1994', filesep, 'fun8_UL1994.xlsx');
     data_table_UL1994 = readtable(input_sub_coef_file); % 获取到多个角度下的系数
     data_table_UL1994_0 = table2array(data_table_UL1994(1,:)); % 获取到第一行数据即可
     % 根据公式，计算地表温度
     lst_data_UL1994 =data_table_UL1994_0(1,1) + data_table_UL1994_0(1,2).*BT2 + data_table_UL1994_0(1,3).*(BT2-BT3)...
         + data_table_UL1994_0(1,4).*(1-ave_emissivity) + data_table_UL1994_0(1,5).*dif_emissivity;
     lst_data_UL1994(DN2==0)=nan; % 将背景值设置为nan
     % 判断如果值中有大于273.15K的值，那么就给定其水体的发射率。
     emissivity_band2( lst_data_UL1994>273.15) = emi2_water;
     emissivity_band3(lst_data_UL1994>273.15) =  emi3_water;
     ave_emissivity = (emissivity_band2+emissivity_band3)/2;
     dif_emissivity = emissivity_band2-emissivity_band3;
     %再反演一遍
     lst_data_UL1994 =data_table_UL1994_0(1,1) + data_table_UL1994_0(1,2).*BT2 + data_table_UL1994_0(1,3).*(BT2-BT3)...
         + data_table_UL1994_0(1,4).*(1-ave_emissivity) + data_table_UL1994_0(1,5).*dif_emissivity;
     lst_data_UL1994(DN2==0)=nan; % 将背景值设置为nan
     % 将结果保存为整形数值
     lst_data_UL1994 = int32(lst_data_UL1994*1000);
     lst_out_UL1994=strcat(parent_folder,filesep,filename,'_','ul1994_retrieval_new_emi.tif');
     if exist(lst_out_UL1994, 'file')
        delete(lst_out_UL1994);
     end
     geotiffwrite(lst_out_UL1994, lst_data_UL1994,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
     clear lst_data_UL1994 

    

       %（10）fun10_enter2019
     disp('计算第十个fun10_enter2019...')
     input_sub_coef_file = strcat(input_coef_filepath, filesep, 'fun10_enter2019', filesep, 'fun10_enter2019.xlsx');
     data_table_enter2019 = readtable(input_sub_coef_file); % 获取到多个角度下的系数
     data_table_enter2019_0 = table2array(data_table_enter2019(1,:)); % 获取到第一行数据即可
     % 根据公式，计算地表温度
     lst_data_enter2019 =data_table_enter2019_0(1,1) + data_table_enter2019_0(1,2).*BT2 + data_table_enter2019_0(1,3).*(BT2-BT3)...
         + data_table_enter2019_0(1,4).*ave_emissivity + data_table_enter2019_0(1,5).*ave_emissivity.*(BT2-BT3) +data_table_enter2019_0(1,6).*dif_emissivity ;
     lst_data_enter2019(DN2==0)=nan; % 将背景值设置为nan
     emissivity_band2(lst_data_enter2019>273.15) = emi2_water;
     emissivity_band3(lst_data_enter2019>273.15) =  emi3_water;
     ave_emissivity = (emissivity_band2+emissivity_band3)/2;
     dif_emissivity = emissivity_band2-emissivity_band3;
     %再反演一遍
     lst_data_enter2019 =data_table_enter2019_0(1,1) + data_table_enter2019_0(1,2).*BT2 + data_table_enter2019_0(1,3).*(BT2-BT3)...
         + data_table_enter2019_0(1,4).*ave_emissivity + data_table_enter2019_0(1,5).*ave_emissivity.*(BT2-BT3) +data_table_enter2019_0(1,6).*dif_emissivity ;
     lst_data_enter2019(DN2==0)=nan; % 将背景值设置为nan
     % 将结果保存为整形数值
     lst_data_enter2019 = int32(lst_data_enter2019*1000);
     lst_out_enter2019=strcat(parent_folder,filesep,filename,'_','enter2019_retrieval_new_emi.tif');
     if exist(lst_out_enter2019, 'file')
        delete(lst_out_enter2019);
     end 
     geotiffwrite(lst_out_enter2019, lst_data_enter2019,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
     clear  lst_data_enter2019
     clear DN2 BT2 BT3 average_BT par3 par4
    
end