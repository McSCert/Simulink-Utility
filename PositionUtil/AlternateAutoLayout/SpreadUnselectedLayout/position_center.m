function center = position_center(position)
    % position given as [left top right bottom]
    
    left = position(1);
    top = position(2);
    right = position(3);
    bottom = position(4);
    
    x = (left+right)/2;
    y = (top+bottom)/2;
    
    center = [x y];
end
    