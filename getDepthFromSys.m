function depth = getDepthFromSys(sys, sys2)
    % Get depth of sys2 from sys
    % Return -1 if sys2 is not in sys
    
    sys = getfullname(sys);
    sys2 = getfullname(sys2);
    
    if strcmp(sys,sys2)
        depth = 0;
    elseif strcmp(bdroot(sys2),sys2)
        depth = -1;
    else
        parentDepth = getDepthFromSys(sys, get_param(sys2, 'Parent'));
        if parentDepth ~= -1
            depth = parentDepth + 1;
        else
            depth = parentDepth;
        end
    end
end