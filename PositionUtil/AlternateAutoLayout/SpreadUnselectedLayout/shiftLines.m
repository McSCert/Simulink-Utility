function shiftLines(lines, shift)
    %
    % lines - Cell array of lines
    % shift - 1x2 vector to add to all points of each line
    
    for i = 1:length(lines)
        l = lines{i};
        points = get_param(l, 'Points');
        
        for j = 1:length(points)
            points(j) = points(j) + shift;
        end
        set_param(l, 'Points', points);
    end
end