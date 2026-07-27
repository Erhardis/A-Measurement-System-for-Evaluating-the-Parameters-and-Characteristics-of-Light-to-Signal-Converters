clear
close all

files = dir(fullfile('center', '*.png'));
num_files = length(files);
fprintf('Найдено файлов: %d\n', num_files);

m = zeros(num_files, 1);
for i = 1:num_files
    I = imread(fullfile('center', files(i).name));
    m(i) = mean(I(:));
end
g = (m / 255) .^ (1 / 0.45);
g_values = g(:);  
N = 14;
fprintf('Количество уникальных уровней (задано): %d\n', N);
fprintf('Количество обработанных изображений: %d\n', length(g_values));
sorted_g = sort(g_values);
total = length(sorted_g);
group_size = floor(total / N);
remainder = total - group_size * N; 
unique_vals = zeros(N, 1);
idx_start = 1;
for k = 1:N
    current_size = group_size + (k <= remainder);
    idx_end = idx_start + current_size - 1;
    unique_vals(k) = mean(sorted_g(idx_start:idx_end));
    idx_start = idx_end + 1;
end

figure;
plot(1:N, unique_vals, 'o-', 'LineWidth', 1.5);
xlabel('Transition number');
ylabel('Pixel level');
xlim([1 14]);
title(sprintf('Dynamic range (N=%d)', N));
grid on;
set(gca, 'FontSize', 14);          
set(findall(gcf, 'Type', 'text'), 'FontSize', 14); 
fprintf('Минимальная яркость: %.4f\n', min(unique_vals));
fprintf('Максимальная яркость: %.4f\n', max(unique_vals));
fprintf('Диапазон: %.4f\n', max(unique_vals) - min(unique_vals));