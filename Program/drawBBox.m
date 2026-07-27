function drawBBox(bbox, color)
    if isempty(bbox)
        return;
    end
    x = [bbox(:,1) bbox(:,3) bbox(:,3) bbox(:,1) bbox(:,1)]';
    y = [bbox(:,2) bbox(:,2) bbox(:,4) bbox(:,4) bbox(:,2)]';
    plot(x, y, 'color', color);
end