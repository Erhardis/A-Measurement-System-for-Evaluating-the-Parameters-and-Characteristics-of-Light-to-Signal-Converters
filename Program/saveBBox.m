function saveBBox(I, bboxes, label, outDir)
    fullDir = fullfile(outDir, label);
    if ~exist(fullDir, 'dir')
        mkdir(fullDir);
    end

    bboxes = round(bboxes);

    x1 = min(bboxes(:,1), bboxes(:,3));
    x2 = max(bboxes(:,1), bboxes(:,3));
    y1 = min(bboxes(:,2), bboxes(:,4));
    y2 = max(bboxes(:,2), bboxes(:,4));

    [h, w, ~] = size(I);
    x1 = max(1, min(x1, w));
    x2 = max(1, min(x2, w));
    y1 = max(1, min(y1, h));
    y2 = max(1, min(y2, h));

    for i = 1:size(bboxes,1)
        if x1(i) > x2(i) || y1(i) > y2(i)
            warning('Error №%d', i);
            continue;
        end
        part = I(y1(i):y2(i), x1(i):x2(i), :);
        imwrite(part, fullfile(fullDir, sprintf('%s_%04d.png', label, i)));
    end
end