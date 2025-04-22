%% 给定meta.xml的路径，然后返回出最终的中心时间结果,也可以获得开始，结束的时间。

function center_date = fun_readxml_meta(filepath_name)

xml_read = xmlread(filepath_name);
% disp(xml_read.getElementsByTagName)
id_start= xml_read.getElementsByTagName('StartTime');
id_center= xml_read.getElementsByTagName('CenterTime');
% id_end= xml_read.getElementsByTagName('EndTime');
length = id_start.getLength;  % 只有一个
for i = 0 : length-1    
    start_array= char(id_start.item(i).getFirstChild.getData);    % 提取当前节点的内容,内容为char型
    center_array = char(id_center.item(i).getFirstChild.getData);
    % end_array = char(id_end.item(i).getFirstChild.getData);
end

%对获取的数组进行第一个元素的获取
str_year = start_array(1:4);
str_month = start_array(6:7);
str_day = start_array(9:10);


% %获取开始值的小时和分钟
% start_str_hour = start_array(12:13);
% start_str_min = start_array(15:16);


%获取中心值的小时和分钟
center_str_hour = center_array(12:13);
center_str_min = center_array(15:16);

% %获取结束值的小时和分钟
% end_str_hour = end_array(12:13);
% end_str_min =end_array(15:16);

% start_date = strcat(str_year, '-', str_month,'-', str_day, '-', start_str_hour, '-' , start_str_min);
center_date = strcat(str_year, '-', str_month,'-', str_day, '-', center_str_hour, '-' , center_str_min);
% end_date = strcat(str_year, '-', str_month,'-', str_day, '-', end_str_hour, '-' , end_str_min);


end
