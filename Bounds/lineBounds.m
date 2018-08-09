function bounds = lineBounds(line)
    points = get_param(line, 'Points');
    bounds = [min(points(:,1)) min(points(:,2)) max(points(:,1)) max(points(:,2))];
end