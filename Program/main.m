close all; clear variables; clc;

N_HOR = 18;                 
N_VER = 10;                 
CENTER_FRACTION = 0.5;      
TRANSITION_WIDTH = 0.5;     
TRANSITION_HEIGHT = 0.5;    
SAVE_IMAGES = true;
FILENAME = '4kSony.png';
OUTPUT_ROOT = 'cropped';    
N_GRADATIONS = 14;          

MTF_TARGET_FREQ = 0.5;      
MTF_WIN_SIZE = 20;          

I = im2double(imread(FILENAME));
figure; imshow(I); title('Исходное изображение');

disp('Автоматическое обнаружение не удалось или размер не совпадает.');
disp('Выберите 4 угловых узла в порядке: верхний левый, верхний правый, нижний левый, нижний правый.');
[x_corners, y_corners] = getpts;
if numel(x_corners) < 4
    error('Error');
end
corners_img = [x_corners(1:4), y_corners(1:4)];

corners_world = [0, 0; N_HOR, 0; 0, N_VER; N_HOR, N_VER];

tform = fitgeotrans(corners_world, corners_img, 'projective');

[X, Y] = ndgrid(0:N_HOR, 0:N_VER);
nodes_world = [X(:), Y(:)];

srcPoints = transformPointsForward(tform, nodes_world);
nodes_img = srcPoints;


[center_boxes, hor_boxes, ver_boxes] = computeBBoxesFromGrid(nodes_img, N_HOR, N_VER, ...
    CENTER_FRACTION, TRANSITION_WIDTH, TRANSITION_HEIGHT);

num_centers = size(center_boxes, 1);
m_vals = zeros(num_centers, 1);

for idx = 1:num_centers
    box = round(center_boxes(idx, :));
    x1 = max(1, box(1)); x2 = min(size(I,2), box(3));
    y1 = max(1, box(2)); y2 = min(size(I,1), box(4));
    if x1 > x2 || y1 > y2
        warning('Пропуск вырожденного центрального бокса №%d', idx);
        continue;
    end
    patch = I(y1:y2, x1:x2, :);
    m_vals(idx) = mean(patch, 'all'); 
end

g_vals = m_vals .^ (1/0.45);

[sorted_g, sort_idx] = sort(g_vals);
total = num_centers;
group_size = floor(total / N_GRADATIONS);
remainder = total - group_size * N_GRADATIONS;

labels_sorted = zeros(total, 1);
start = 1;
for k = 1:N_GRADATIONS
    current_size = group_size + (k <= remainder);
    labels_sorted(start:start+current_size-1) = k;
    start = start + current_size;
end

labels = zeros(total, 1);
labels(sort_idx) = labels_sorted;

fprintf('Градации присвоены. Диапазон групп: 1..%d\n', N_GRADATIONS);

cell_centers = zeros(N_HOR, N_VER, 2);
for i = 1:N_HOR
    for j = 1:N_VER
        
        idx = @(ix, iy) (iy)*(N_HOR+1) + ix + 1;
        p1 = nodes_img(idx(i-1, j-1), :); 
        p2 = nodes_img(idx(i,   j-1), :); 
        p3 = nodes_img(idx(i,   j),   :); 
        p4 = nodes_img(idx(i-1, j),   :); 
        pts = [p1; p2; p3; p4];
        cell_centers(i,j,:) = mean(pts, 1);
    end
end

figure; imshow(I); hold on;
if ~isempty(hor_boxes)
    drawBBox(hor_boxes, 'g');
    fprintf('Найдено %d горизонтальных переходов\n', size(hor_boxes, 1));
end
if ~isempty(ver_boxes)
    drawBBox(ver_boxes, 'y');
    fprintf('Найдено %d вертикальных переходов\n', size(ver_boxes, 1));
end
if ~isempty(center_boxes)
    drawBBox(center_boxes, 'b');
    fprintf('Найдено %d центральных квадратов\n', size(center_boxes, 1));
end

for i = 1:N_HOR
    for j = 1:N_VER
        idx = (j-1)*N_HOR + i;  
        grad = labels(idx);
        x_center = cell_centers(i, j, 1);
        y_center = cell_centers(i, j, 2);
        text(x_center, y_center, num2str(grad), ...
            'HorizontalAlignment', 'center', ...
            'Color', 'red', 'FontSize', 8, 'FontWeight', 'bold');
    end
end
title('Обнаруженные области с номерами градаций');

if SAVE_IMAGES
    
    center_dir = fullfile(OUTPUT_ROOT, 'center');
    if ~exist(center_dir, 'dir'); mkdir(center_dir); end
    for idx = 1:num_centers
        box = round(center_boxes(idx, :));
        x1 = max(1, box(1)); x2 = min(size(I,2), box(3));
        y1 = max(1, box(2)); y2 = min(size(I,1), box(4));
        if x1 > x2 || y1 > y2; continue; end
        patch = I(y1:y2, x1:x2, :);
        grad = labels(idx);
        filename = sprintf('center_%02d_%04d.png', grad, idx);
        imwrite(patch, fullfile(center_dir, filename));
    end
    fprintf('Центральные квадраты сохранены в "%s"\n', center_dir);

    
    hor_dir = fullfile(OUTPUT_ROOT, 'horizontal');
    if ~exist(hor_dir, 'dir'); mkdir(hor_dir); end
    hor_idx = 0;
    for i = 1:N_HOR-1
        for j = 1:N_VER
            hor_idx = hor_idx + 1;
            left_global = (j-1)*N_HOR + i;
            right_global = (j-1)*N_HOR + (i+1);
            grad_left = labels(left_global);
            grad_right = labels(right_global);
            box = hor_boxes(hor_idx, :);
            x1 = max(1, round(box(1))); x2 = min(size(I,2), round(box(3)));
            y1 = max(1, round(box(2))); y2 = min(size(I,1), round(box(4)));
            if x1 > x2 || y1 > y2; continue; end
            patch = I(y1:y2, x1:x2, :);
            filename = sprintf('horizontal_%02d_%02d_%04d.png', grad_left, grad_right, hor_idx);
            imwrite(patch, fullfile(hor_dir, filename));
        end
    end
    fprintf('Горизонтальные переходы сохранены в "%s"\n', hor_dir);

   
    ver_dir = fullfile(OUTPUT_ROOT, 'vertical');
    if ~exist(ver_dir, 'dir'); mkdir(ver_dir); end
    ver_idx = 0;
    for i = 1:N_HOR
        for j = 1:N_VER-1
            ver_idx = ver_idx + 1;
            top_global = (j-1)*N_HOR + i;
            bottom_global = j*N_HOR + i;
            grad_top = labels(top_global);
            grad_bottom = labels(bottom_global);
            box = ver_boxes(ver_idx, :);
            x1 = max(1, round(box(1))); x2 = min(size(I,2), round(box(3)));
            y1 = max(1, round(box(2))); y2 = min(size(I,1), round(box(4)));
            if x1 > x2 || y1 > y2; continue; end
            patch = I(y1:y2, x1:x2, :);
            filename = sprintf('vertical_%02d_%02d_%04d.png', grad_top, grad_bottom, ver_idx);
            imwrite(patch, fullfile(ver_dir, filename));
        end
    end
    fprintf('Вертикальные переходы сохранены в "%s"\n', ver_dir);

    disp(['Все фрагменты сохранены в папку "' OUTPUT_ROOT '"']);
end


if SAVE_IMAGES
    
    f_common = linspace(0, 1, 500);
    mtf_map = containers.Map();
    
    hor_dir = fullfile(OUTPUT_ROOT, 'horizontal');
    if isfolder(hor_dir)
        hor_files = dir(fullfile(hor_dir, 'horizontal_*.png'));
        for k = 1:length(hor_files)
            fname = hor_files(k).name;
            tokens = regexp(fname, 'horizontal_(\d+)_(\d+)_\d+\.png', 'tokens');
            if isempty(tokens); continue; end
            a = str2double(tokens{1}{1});
            b = str2double(tokens{1}{2});
            key = sprintf('%d_%d', min(a,b), max(a,b));  
            
            fullpath = fullfile(hor_dir, fname);
            img = imread(fullpath);
            if size(img,3)==3; img = rgb2gray(img); end
            img = im2double(img);
            
            res = compute_mtf(img, MTF_WIN_SIZE);
            if ~res.success; continue; end
            
            mtf_interp = interp1(res.f, res.mtf, f_common, 'linear', 'extrap');
            mtf_interp = max(0, min(1, mtf_interp)); 
            if isKey(mtf_map, key)
                mtf_map(key) = [mtf_map(key); mtf_interp];
            else
                mtf_map(key) = mtf_interp;
            end
        end
    end
    
    ver_dir = fullfile(OUTPUT_ROOT, 'vertical');
    if isfolder(ver_dir)
        ver_files = dir(fullfile(ver_dir, 'vertical_*.png'));
        for k = 1:length(ver_files)
            fname = ver_files(k).name;
            tokens = regexp(fname, 'vertical_(\d+)_(\d+)_\d+\.png', 'tokens');
            if isempty(tokens); continue; end
            a = str2double(tokens{1}{1});
            b = str2double(tokens{1}{2});
            key = sprintf('%d_%d', min(a,b), max(a,b));
            
            fullpath = fullfile(ver_dir, fname);
            img = imread(fullpath);
            if size(img,3)==3; img = rgb2gray(img); end
            img_rot = rot90(img, 1);  
            img_rot = im2double(img_rot);
            
            res = compute_mtf(img_rot, MTF_WIN_SIZE);
            if ~res.success; continue; end
            
            mtf_interp = interp1(res.f, res.mtf, f_common, 'linear', 'extrap');
            mtf_interp = max(0, min(1, mtf_interp)); 
            if isKey(mtf_map, key)
                mtf_map(key) = [mtf_map(key); mtf_interp];
            else
                mtf_map(key) = mtf_interp;
            end
        end
    end
      
    avg_mtf = containers.Map();
    keys_all = keys(mtf_map);
    for i = 1:length(keys_all)
        key = keys_all{i};
        mtf_list = mtf_map(key);  
        avg_mtf(key) = mean(mtf_list, 1);
    end
    
    
    j_vals = 2:N_GRADATIONS;
    num_j = length(j_vals);
    num_f = length(f_common);
    
    Z_mtf = nan(num_j, num_f);
    
    for idx_j = 1:num_j
        j = j_vals(idx_j);
        key = sprintf('1_%d', j);
        if isKey(avg_mtf, key)
            curve = avg_mtf(key);  
            Z_mtf(idx_j, :) = curve(:)';
        else
            warning('Нет данных для пары %s', key);
        end
    end
    
    figure('Name', 'MTF');
    contourf(f_common, 1:num_j, Z_mtf, 20, 'LineColor', 'k');
    xlabel('f');
    ylabel('Transition');
    title('MTF (Contour)');
    colorbar;
    colormap jet;
    set(gca, 'YDir', 'reverse');
    yticks(1:num_j);
    yticklabels(arrayfun(@(j) sprintf('1-%d', j), j_vals, 'UniformOutput', false));
    ylim([0.5 num_j+0.5]);
    

    set(gca, 'FontSize', 14);         
    set(findall(gcf, 'Type', 'text'), 'FontSize', 14); 
    set(findall(gcf, 'Type', 'colorbar'), 'FontSize', 12); 
       
    figure('Name', 'MTF');
    waterfall(f_common, 1:num_j, Z_mtf);
    xlabel('f');
    ylabel('Transition');
    zlabel('MTF');
    title('MTF (Waterfall)');
    colormap jet;
    set(gca, 'YDir', 'reverse');
    yticks(1:num_j);
    yticklabels(arrayfun(@(j) sprintf('1-%d', j), j_vals, 'UniformOutput', false));
    ylim([0.5 num_j+0.5]);
    view(45, 30);  
    
    set(gca, 'FontSize', 14);         
    set(findall(gcf, 'Type', 'text'), 'FontSize', 14); 
    set(findall(gcf, 'Type', 'colorbar'), 'FontSize', 12); 
end

