%% 反演地表温度，输入不同反演算法的系数文件xlsx, 输入发射率值（细雪，粗雪，中粒雪，水）四种地物的结果。
%% 输入dn值


clear,clc,close all;

   %% 输入不同算法的系数文件
input_coef_filepath = 'E:\OneDrive\Phd\c_paper\3_thirdpaper\new_version\data\step1_simulation_coef\diff_method_simulation_coef_data';
% folder_name = ["fun1_OV1992", "fun2_FO1996", "fun3_PR1984", "fun4_UC1985", "fun5_BL_WD",...
        % "fun6_PP1991", "fun7_VI1991", "fun8_UL1994", "fun9_WA2014"];

%% 输入反演地表温度的路径
% input_filepath = 'E:\OneDrive\Phd\1_project\1_SDG LST\3_data_lst';
input_filepath = 'E:\OneDrive\Phd\c_paper\3_thirdpaper\picture\应用\冰间水道\new_data'; % 输入主目录
subdir_input = dir(input_filepath); % 会获取到'..'和'.'的文件名

% 设置使用给定发射率的目录
input_mui_filepath = 'F:\sdgsat\20220914\SDGSAT_class\band7_radio_clip_20220914_mii_quac.tif';
input_tis_filepath = 'F:\sdgsat\20220914\SDGSAT_class\clip_20220914_tis.tif';

%% 设置是否进行自行输入发射率还是粗糙计算
input_emi_flag= 'no';  % 这里设置yes或者no，如果设置为yes，那么就不用管land_water, 如果设置为no，则进一步判断是否为land或者water
land_water_flag = 'sea';  % 这里设置land或者sea

%% %% 这里管发射率问题
switch lower(input_emi_flag)  % 转换为小写，使判断不区分大小写
    case 'yes'
        disp('你选择了 yes，请输入可见光波段数据，并调用发射率输入函数...');
        
        % 直接调用发射率计算函数
        user_input_emi(input_tis_filepath, input_mui_filepath)
    case 'no'
        disp('你选择了 no，请继续判断是否在陆地或者海洋上执行');
        %% 获取子目录文件夹
        for j = 1:length(subdir_input)
             % disp(subdir(i));
            if( isequal(subdir_input( j ).name, '.' )|| isequal(subdir_input( j ).name, '..')||~subdir_input(j ).isdir) 
                 continue;
            end
            subdir_name = subdir_input(j).name;
            % disp(subdir_name);
            
            % 获取到子目录的文件名
            sub_input_filepath = strcat(input_filepath, filesep,subdir_name);
            subdir = dir(sub_input_filepath);
        
            for i = 1 : length( subdir)
                % disp(subdir(i));
                if( isequal( subdir( i ).name, '.' )|| isequal( subdir( i ).name, '..')||~subdir( i ).isdir) 
                     continue;
                end
                % disp(i)
            
                %% 对获取的每个文件进行操作
                subpath = fullfile(sub_input_filepath, subdir( i ).name);
                  if contains(subpath, '_L4B')
                    disp('开始处理栅格数据...');
                    % 开始调用数据
                    disp('调用readxml函数读取影像的中心获取时间...');
                    input_xml_path_dir = dir(fullfile(subpath,'*.meta.xml'));
                    input_xml_path = fullfile(subpath,input_xml_path_dir.name);
                    disp(input_xml_path);
                    % 获取到中心时间
                    center_date = fun_readxml_meta(input_xml_path);
        
                    
                    disp('读取热红外数据tiff文件...')
                    filest = dir(fullfile(sub_input_filepath,subdir( i ).name,'KX10_TIS*.tiff'));
                    fileband = fullfile(sub_input_filepath,subdir( i ).name,filest.name);
                    % 得到dn值
                    DN = readgeoraster(fileband);
                    DN2 = double(DN(:,:,2));
                    DN3 = double(DN(:,:,3));
                    % Get Tiff info
                    info = geotiffinfo(fileband);
                    % % disp(info);
            
                    %% 辐射校正
                    disp('开始辐射校正...')
                    L2 = DN2.*0.003946 + 0.124622;
                    L3 = DN3.*0.005329 + 0.222530;
                    %% 得到星上亮温值
                    [BT2,BT3] = radiance2BT(L2,L3);
                    BT2_filepath=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep, center_date,'_', filest.name(1:end-5),'_new_bt2.tif');
                         if exist(BT2_filepath, 'file')
                            delete(BT2_filepath);
                         end
                         geotiffwrite(BT2_filepath,BT2,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
                     BT3_filepath=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep, center_date,'_', filest.name(1:end-5),'_new_bt3.tif');
                         if exist(BT3_filepath, 'file')
                            delete(BT3_filepath);
                         end
                         geotiffwrite(BT3_filepath,BT3,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
                    % 清除变量
                    clear L2 L3 DN  DN3
                    %% 计算地表温度值
                    
                    disp('计算地表温度...')
                    average_BT =(BT2+BT3)/2;
                    diff_BT    = (BT2-BT3);
        
                        if strcmpi(land_water_flag, 'land')  % 不区分大小写
                            disp('你选择了 land，请调用陆地发射率确定方法函数，并得到对应的发射率空间分布图')
    
                            % 给定陆地发射率设置,默认是不同颗粒雪和水的混合物体，然后判断，如果小于273.15K则是雪，如果大于等于273.15K，则是粗粒雪和水的混合体。
                             %总的发射率率
                             emi2_land = 0.9907;
                             emi3_land= 0.9816;
                             ave_emi_land = (emi2_land+emi3_land)/2;
                             dif_emi_land = emi2_land-emi3_land;
                            %水和雪的发射率值。水和粗粒径雪
                             emi2_water_snow = 0.9863;
                             emi3_water_snow = 0.9635;
                             emi2_snow = 0.9910;
                             emi3_snow = 0.9798;
    
                             %（3）fun3_PR1984，首先反演一遍
                             disp('计算第三个fun3_PR1984...')
                             input_sub_coef_file = strcat(input_coef_filepath, filesep, 'fun3_PR1984', filesep, 'fun3_PR1984.xlsx');
                             data_table_PR1984 = readtable(input_sub_coef_file); % 获取到多个角度下的系数
                             data_table_PR1984_0 = table2array(data_table_PR1984(1,:)); % 获取到第一行数据即可
                             disp(['pr1984的系数为', data_table_PR1984_0])
                             % 根据公式，计算地表温度
                             lst_data_PR1984 =data_table_PR1984_0(1,1) + data_table_PR1984_0(1,2).*BT2 + data_table_PR1984_0(1,3).*(BT2-BT3) + data_table_PR1984_0(1,4).*BT2.*emi2_land +...
                                 data_table_PR1984_0(1,5).*(BT2-BT3).*(1-emi2_land) +data_table_PR1984_0(1,6).*(BT3.*dif_emi_land);
                             lst_data_PR1984(DN2==0)=nan; % 将背景值设置为nan
    
                             %% 接着进行获取发射率图。判断如果温度大于273.15K则设置为水和粗粒雪，如果小于273.15K，则设置为不同粒径雪的平均值。
                             % 创建发射率矩阵
                             emissivity_band2 =  emi2_water_snow * ones(size(lst_data_PR1984));  % 默认值
                             emissivity_band3 =  emi3_water_snow* ones(size(lst_data_PR1984));   % 默认值
                            % 为温度大于273.15K的位置赋值
                             emissivity_band2(lst_data_PR1984<273.15) = emi2_snow;
                             emissivity_band3(lst_data_PR1984 < 273.15) =  emi3_snow;
                         
                            %%  继续反演。
                             ave_emissivity = (emissivity_band2+emissivity_band3)/2;
                             dif_emissivity = emissivity_band2-emissivity_band3;
                             % 根据公式，计算地表温度
                             lst_data_PR1984 =data_table_PR1984_0(1,1) + data_table_PR1984_0(1,2).*BT2 + data_table_PR1984_0(1,3).*(BT2-BT3) + data_table_PR1984_0(1,4).*BT2.*emissivity_band2 +...
                                 data_table_PR1984_0(1,5).*(BT2-BT3).*(1-emissivity_band2) +data_table_PR1984_0(1,6).*(BT3.*dif_emissivity);
                             lst_data_PR1984(DN2==0)=nan; % 将背景值设置为nan
                             % 将结果保存为整形数值
                             lst_data_PR1984 = int32(lst_data_PR1984*1000);
                             lst_out_PR1984=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep, center_date,'_', filest.name(1:end-5),'_fun3_PR1984_new.tif');
                             if exist(lst_out_PR1984, 'file')
                                delete(lst_out_PR1984);
                             end
                             geotiffwrite(lst_out_PR1984, lst_data_PR1984,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
                             clear lst_data_PR1984
                            
    
                               %（7）fun7_VI1991
                             disp('计算第七个fun7_VI1991...')
                             input_sub_coef_file = strcat(input_coef_filepath, filesep, 'fun7_VI1991', filesep, 'fun7_VI1991.xlsx');
                             data_table_VI1991 = readtable(input_sub_coef_file); % 获取到多个角度下的系数
                             data_table_VI1991_0 = table2array(data_table_VI1991(1,:)); % 获取到第一行数据即可
                             % 根据公式，计算地表温度
                             lst_data_VI1991 =data_table_VI1991_0(1,1) + data_table_VI1991_0(1,2).*BT2 + data_table_VI1991_0(1,3).*(BT2-BT3)...
                                 + data_table_VI1991_0(1,4).*(1-ave_emi_land)./ave_emi_land + data_table_VI1991_0(1,5).*(dif_emi_land./ave_emi_land);
                             lst_data_VI1991(DN2==0)=nan; % 将背景值设置为nan
                              %% 接着进行获取发射率图。。
                             % 创建发射率矩阵
                             emissivity_band2 =  emi2_water_snow * ones(size(lst_data_VI1991));  % 默认值
                             emissivity_band3 = emi3_water_snow* ones(size(lst_data_VI1991));   % 默认值
                            % 为温度大于273.15K的位置赋值
                             emissivity_band2(lst_data_VI1991<273.15) = emi2_snow;
                             emissivity_band3(lst_data_VI1991 < 273.15) =  emi3_snow;
                         
                            %%  继续反演。
                             ave_emissivity = (emissivity_band2+emissivity_band3)/2;
                             dif_emissivity = emissivity_band2-emissivity_band3;
                             lst_data_VI1991 =data_table_VI1991_0(1,1) + data_table_VI1991_0(1,2).*BT2 + data_table_VI1991_0(1,3).*(BT2-BT3)...
                                 + data_table_VI1991_0(1,4).*(1-ave_emissivity)./ave_emissivity + data_table_VI1991_0(1,5).*(dif_emissivity./ave_emissivity);
                             lst_data_VI1991(DN2==0)=nan; % 将背景值设置为nan
                             % 将结果保存为整形数值
                             lst_data_VI1991 = int32(lst_data_VI1991*1000);
                             lst_out_VI1991=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep,  center_date,'_', filest.name(1:end-5),'_fun7_VI1991_new.tif');
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
                                 + data_table_UL1994_0(1,4).*(1-ave_emi_land) + data_table_UL1994_0(1,5).*dif_emi_land;
                             lst_data_UL1994(DN2==0)=nan; % 将背景值设置为nan
                             %% 接着进行获取发射率图
                             % 创建发射率矩阵
                             emissivity_band2 =  emi2_water_snow * ones(size(lst_data_UL1994));  % 默认值
                             emissivity_band3 =  emi3_water_snow* ones(size(lst_data_UL1994));   % 默认值
                            % 为温度大于273.15K的位置赋值
                             emissivity_band2(lst_data_UL1994<273.15) = emi2_snow;
                             emissivity_band3(lst_data_UL1994<273.15) = emi3_snow;
                         
                            %%  继续反演。
                             ave_emissivity = (emissivity_band2+emissivity_band3)/2;
                             dif_emissivity = emissivity_band2-emissivity_band3;
                             % 根据公式，计算地表温度
                             lst_data_UL1994 =data_table_UL1994_0(1,1) + data_table_UL1994_0(1,2).*BT2 + data_table_UL1994_0(1,3).*(BT2-BT3)...
                                 + data_table_UL1994_0(1,4).*(1-ave_emissivity) + data_table_UL1994_0(1,5).*dif_emissivity;
                             lst_data_UL1994(DN2==0)=nan; % 将背景值设置为nan
                             % 将结果保存为整形数值
                             lst_data_UL1994 = int32(lst_data_UL1994*1000);
                             lst_out_UL1994=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep, center_date,'_',  filest.name(1:end-5),'_fun8_UL1994_new.tif');
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
                                 + data_table_enter2019_0(1,4).*ave_emi_land + data_table_enter2019_0(1,5).*ave_emi_land.*(BT2-BT3) +data_table_enter2019_0(1,6).*dif_emi_land;
                             lst_data_enter2019(DN2==0)=nan; % 将背景值设置为nan
                             %% 接着进行获取发射率图。
    
                             % 创建发射率矩阵
                             emissivity_band2 =  emi2_water_snow * ones(size(lst_data_enter2019));  % 默认值
                             emissivity_band3 = emi3_water_snow* ones(size(lst_data_enter2019));   % 默认值
                            % 为温度大于273.15K的位置赋值
                             emissivity_band2(lst_data_enter2019<273.15) = emi2_snow;
                             emissivity_band3(lst_data_enter2019 < 273.15) =  emi3_snow;
                         
                            %%  继续反演。
                             ave_emissivity = (emissivity_band2+emissivity_band3)/2;
                             dif_emissivity = emissivity_band2-emissivity_band3;
    
                              % 根据公式，计算地表温度
                             lst_data_enter2019 =data_table_enter2019_0(1,1) + data_table_enter2019_0(1,2).*BT2 + data_table_enter2019_0(1,3).*(BT2-BT3)...
                                 + data_table_enter2019_0(1,4).*ave_emissivity + data_table_enter2019_0(1,5).* ave_emissivity.*(BT2-BT3) +data_table_enter2019_0(1,6).*dif_emissivity ;
                             lst_data_enter2019(DN2==0)=nan; % 将背景值设置为nan
                             % 将结果保存为整形数值
                             lst_data_enter2019 = int32(lst_data_enter2019*1000);
                             lst_out_enter2019=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep, center_date,'_', filest.name(1:end-5),'_fun10_enter2019_new.tif');
                             if exist(lst_out_enter2019, 'file')
                                delete(lst_out_enter2019);
                             end 
                             geotiffwrite(lst_out_enter2019, lst_data_enter2019,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
                             clear  lst_data_enter2019
                             clear DN2 BT2 BT3 average_BT par3 par4
                
                             disp_out =strcat('第', num2str(i-2),'个文件运行结束');
                     
        
                        %%  针对海洋区域反演    
                        elseif strcmpi(land_water_flag, 'sea')
                            disp('你选择了sea，请调用海洋发射率确定方法函数，并得到对应的发射率空间分布图');
                            % 给定海洋发射率设置,海洋区域由于不清楚是否为水，还是冰，还是雪，因此首先基于总的发射率设置
                            %总的发射率率
                             emi2_sea = 0.9899;
                             emi3_sea= 0.9773;
                             ave_emi_sea = (emi2_sea+emi3_sea)/2;
                             dif_emi_sea = emi2_sea-emi3_sea;
                            %冰和粗雪的发射率值。
                             emi2_ice_snow = 0.9899;
                             emi3_ice_snow = 0.9749;
                             % 水和冰的发射率，这里大于271.5K的时候，应当设置，水，冰和粗颗粒雪的混合体
                             emi2_water_ice = 0.9875;
                             emi3_water_ice = 0.9713;
                             %如果大于273.15K，则设置为水的发射率。
                             emi2_water = 0.9899;
                             emi3_water = 0.9869;
    
                             %（3）fun3_PR1984，首先反演一遍
                             disp('计算第三个fun3_PR1984...')
                             input_sub_coef_file = strcat(input_coef_filepath, filesep, 'fun3_PR1984', filesep, 'fun3_PR1984.xlsx');
                             data_table_PR1984 = readtable(input_sub_coef_file); % 获取到多个角度下的系数
                             data_table_PR1984_0 = table2array(data_table_PR1984(1,:)); % 获取到第一行数据即可
                             % 根据公式，计算地表温度
                             lst_data_PR1984 =data_table_PR1984_0(1,1) + data_table_PR1984_0(1,2).*BT2 + data_table_PR1984_0(1,3).*(BT2-BT3) + data_table_PR1984_0(1,4).*BT2.*emi2_sea +...
                                 data_table_PR1984_0(1,5).*(BT2-BT3).*(1-emi2_sea) +data_table_PR1984_0(1,6).*(BT3.*dif_emi_sea);
                             lst_data_PR1984(DN2==0)=nan; % 将背景值设置为nan
    
                             %% 接着进行获取发射率图。判断如果温度大于271.5K则设置为水，如果小于271.5K，则设置为冰和雪的平均值。
                             % 这里存在的问题是大于271.5K，可能还是雪。
                             % 创建发射率矩阵
                             emissivity_band2 =  emi2_water_ice * ones(size(lst_data_PR1984));  % 默认值
                             emissivity_band3 = emi3_water_ice* ones(size(lst_data_PR1984));   % 默认值
                            % 为温度大于273.15K的位置赋值
                             emissivity_band2(lst_data_PR1984<271.5) = emi2_ice_snow;
                             emissivity_band3(lst_data_PR1984 < 271.5) =  emi3_ice_snow;
                             %对于大于273.15K的设置为水
                             emissivity_band2(lst_data_PR1984>273.15) = emi2_water;
                             emissivity_band3(lst_data_PR1984> 273.15) =  emi3_water;
                            %%  继续反演。
                             ave_emissivity = (emissivity_band2+emissivity_band3)/2;
                             dif_emissivity = emissivity_band2-emissivity_band3;
                             % 根据公式，计算地表温度
                             lst_data_PR1984 =data_table_PR1984_0(1,1) + data_table_PR1984_0(1,2).*BT2 + data_table_PR1984_0(1,3).*(BT2-BT3) + data_table_PR1984_0(1,4).*BT2.*emissivity_band2 +...
                                 data_table_PR1984_0(1,5).*(BT2-BT3).*(1-emissivity_band2) +data_table_PR1984_0(1,6).*(BT3.*dif_emissivity);
                             lst_data_PR1984(DN2==0)=nan; % 将背景值设置为nan
                             % 将结果保存为整形数值
                             lst_data_PR1984 = int32(lst_data_PR1984*1000);
                             lst_out_PR1984=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep, center_date,'_', filest.name(1:end-5),'_fun3_PR1984_new.tif');
                             if exist(lst_out_PR1984, 'file')
                                delete(lst_out_PR1984);
                             end
                             geotiffwrite(lst_out_PR1984, lst_data_PR1984,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
                             clear lst_data_PR1984
                            
    
                               %（7）fun7_VI1991
                             disp('计算第七个fun7_VI1991...')
                             input_sub_coef_file = strcat(input_coef_filepath, filesep, 'fun7_VI1991', filesep, 'fun7_VI1991.xlsx');
                             data_table_VI1991 = readtable(input_sub_coef_file); % 获取到多个角度下的系数
                             data_table_VI1991_0 = table2array(data_table_VI1991(1,:)); % 获取到第一行数据即可
                             % 根据公式，计算地表温度
                             lst_data_VI1991 =data_table_VI1991_0(1,1) + data_table_VI1991_0(1,2).*BT2 + data_table_VI1991_0(1,3).*(BT2-BT3)...
                                 + data_table_VI1991_0(1,4).*(1-ave_emi_sea)./ave_emi_sea + data_table_VI1991_0(1,5).*(dif_emi_sea./ave_emi_sea);
                             lst_data_VI1991(DN2==0)=nan; % 将背景值设置为nan
                              %% 接着进行获取发射率图。判断如果温度大于271.5K则设置为水，如果小于271.5K，则设置为冰和雪的平均值。
                             % 这里存在的问题是大于271.5K，可能还是雪。
                             % 创建发射率矩阵
                             emissivity_band2 =  emi2_water_ice * ones(size(lst_data_VI1991));  % 默认值
                             emissivity_band3 = emi3_water_ice* ones(size(lst_data_VI1991));   % 默认值
                            % 为温度大于273.15K的位置赋值
                             emissivity_band2(lst_data_VI1991<271.5) = emi2_ice_snow;
                             emissivity_band3(lst_data_VI1991< 271.5) =  emi3_ice_snow;
                            %对于大于273.15K的设置为水
                             emissivity_band2(lst_data_VI1991>273.15) = emi2_water;
                             emissivity_band3(lst_data_VI1991> 273.15) =  emi3_water;
                            %%  继续反演。
                             ave_emissivity = (emissivity_band2+emissivity_band3)/2;
                             dif_emissivity = emissivity_band2-emissivity_band3;
                             lst_data_VI1991 =data_table_VI1991_0(1,1) + data_table_VI1991_0(1,2).*BT2 + data_table_VI1991_0(1,3).*(BT2-BT3)...
                                 + data_table_VI1991_0(1,4).*(1-ave_emissivity)./ave_emissivity + data_table_VI1991_0(1,5).*(dif_emissivity./ave_emissivity);
                             lst_data_VI1991(DN2==0)=nan; % 将背景值设置为nan
                             % 将结果保存为整形数值
                             lst_data_VI1991 = int32(lst_data_VI1991*1000);
                             lst_out_VI1991=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep,  center_date,'_', filest.name(1:end-5),'_fun7_VI1991_new.tif');
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
                                 + data_table_UL1994_0(1,4).*(1-ave_emi_sea) + data_table_UL1994_0(1,5).*dif_emi_sea;
                             lst_data_UL1994(DN2==0)=nan; % 将背景值设置为nan
                             %% 接着进行获取发射率图。判断如果温度大于271.5K则设置为水，如果小于271.5K，则设置为冰和雪的平均值。
                             % 这里存在的问题是大于271.5K，可能还是雪。
                             % 创建发射率矩阵
                             emissivity_band2 =  emi2_water_ice * ones(size(lst_data_UL1994));  % 默认值
                             emissivity_band3 = emi3_water_ice* ones(size(lst_data_UL1994));   % 默认值
                            % 为温度大于273.15K的位置赋值
                             emissivity_band2(lst_data_UL1994<271.5) = emi2_ice_snow;
                             emissivity_band3(lst_data_UL1994 < 271.5) =  emi3_ice_snow;
                             %对于大于273.15K的设置为水
                             emissivity_band2(lst_data_UL1994>273.15) = emi2_water;
                             emissivity_band3(lst_data_UL1994> 273.15) =  emi3_water;
                            %%  继续反演。
                             ave_emissivity = (emissivity_band2+emissivity_band3)/2;
                             dif_emissivity = emissivity_band2-emissivity_band3;
                             % 根据公式，计算地表温度
                             lst_data_UL1994 =data_table_UL1994_0(1,1) + data_table_UL1994_0(1,2).*BT2 + data_table_UL1994_0(1,3).*(BT2-BT3)...
                                 + data_table_UL1994_0(1,4).*(1-ave_emissivity) + data_table_UL1994_0(1,5).*dif_emissivity;
                             lst_data_UL1994(DN2==0)=nan; % 将背景值设置为nan
                             % 将结果保存为整形数值
                             lst_data_UL1994 = int32(lst_data_UL1994*1000);
                             lst_out_UL1994=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep, center_date,'_',  filest.name(1:end-5),'_fun8_UL1994_new.tif');
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
                                 + data_table_enter2019_0(1,4).*ave_emi_sea + data_table_enter2019_0(1,5).*ave_emi_sea.*(BT2-BT3) +data_table_enter2019_0(1,6).*dif_emi_sea;
                             lst_data_enter2019(DN2==0)=nan; % 将背景值设置为nan
                             %% 接着进行获取发射率图。判断如果温度大于271.5K则设置为水，如果小于271.5K，则设置为冰和雪的平均值。
                             % 这里存在的问题是大于271.5K，可能还是雪。
                             % 创建发射率矩阵
                             emissivity_band2 =  emi2_water_ice * ones(size(lst_data_enter2019));  % 默认值
                             emissivity_band3 = emi3_water_ice* ones(size(lst_data_enter2019));   % 默认值
                            % 为温度大于273.15K的位置赋值
                             emissivity_band2(lst_data_enter2019<271.5) = emi2_ice_snow;
                             emissivity_band3(lst_data_enter2019 < 271.5) = emi3_ice_snow;
                            %对于大于273.15K的设置为水
                             emissivity_band2(lst_data_enter2019>273.15) = emi2_water;
                             emissivity_band3(lst_data_enter2019> 273.15) = emi3_water;
                            %%  继续反演。
                             ave_emissivity = (emissivity_band2+emissivity_band3)/2;
                             dif_emissivity = emissivity_band2-emissivity_band3;
    
                              % 根据公式，计算地表温度
                             lst_data_enter2019 =data_table_enter2019_0(1,1) + data_table_enter2019_0(1,2).*BT2 + data_table_enter2019_0(1,3).*(BT2-BT3)...
                                 + data_table_enter2019_0(1,4).*ave_emissivity + data_table_enter2019_0(1,5).* ave_emissivity.*(BT2-BT3) +data_table_enter2019_0(1,6).*dif_emissivity ;
                             lst_data_enter2019(DN2==0)=nan; % 将背景值设置为nan
                             % 将结果保存为整形数值
                             lst_data_enter2019 = int32(lst_data_enter2019*1000);
                             lst_out_enter2019=strcat(sub_input_filepath, filesep, subdir( i ).name, filesep, center_date,'_', filest.name(1:end-5),'_fun10_enter2019_new.tif');
                             if exist(lst_out_enter2019, 'file')
                                delete(lst_out_enter2019);
                             end 
                             geotiffwrite(lst_out_enter2019, lst_data_enter2019,info.SpatialRef,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
                             clear  lst_data_enter2019
                             clear DN2 BT2 BT3 average_BT par3 par4
                
                             disp_out =strcat('第', num2str(i-2),'个文件运行结束');
                 
                        else
                            error('输入必须是 land 或 water！');
                        end
            % if end
            end     
            end
       end
  otherwise
       error('输入必须是 yes 或 no！');
end % switch end
% disp('运行结束！')





