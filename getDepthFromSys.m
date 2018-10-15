function depth = getDepthFromSys(sys, sys2)
% GETDEPTHFROMSYS Return the depth of a subsystem with repect to another subsystem.
%   If sys2 is not a child of sys, -1 is returned.
%
%   Inputs:
%       sys     Parent subsystem.
%       sys2    Child subsystem.
%
%   Outputs:
%       depth   Number of hierarichal levels that sys2 is below sys.

    sys = getfullname(sys);
    sys2 = getfullname(sys2);

    if strcmp(sys, sys2)
        depth = 0;
    elseif strcmp(bdroot(sys2), sys2)
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