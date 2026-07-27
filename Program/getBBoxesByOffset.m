function boxes = getBBoxesByOffset(x, y, offset, tform)
    [X, Y] = ndgrid(x, y);
    points = [X(:), Y(:)];                
    n = size(points, 1);
    corners_local = [points + offset(1:2); points + offset(3:4)];
    corners_img = transformPointsInverse(tform, corners_local);
    boxes = [corners_img(1:n, :), corners_img(n+1:end, :)];
end