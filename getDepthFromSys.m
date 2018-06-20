function depth = getDepthFromSys(sys, sys2)
    % Get depth of sys2 from sys
    % Return -1 if sys2 is not in sys
    
    if strcmp(sys,sys2)
        depth = 0;
    elseif strcmp(bdroot(sys2),sys2)
        depth = -1;
    else
        depth = getDepthFromSys(sys, get_param(sys2, 'Parent')) + 1;
    end
end