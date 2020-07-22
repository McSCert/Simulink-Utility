function b = inParentDescendants(sys, block)
% INPARENTDESCENDANTS Determine if block is contained in a system that is a 
%   common parent's descendant (not including itself).
%
%   Inputs:
%       sys     System path name.
%       block   Name of block.
%
%   Outputs:
%       b       System containing block.

    sys2 = get_param(block, 'Parent'); % Get system where block is located
    
    common = commonParent(sys, sys2);
    
    if ~strcmp(common, sys) && ~strcmp(common, sys2)
        % Check that it is a parent
        r = ['^' common '/[(\w|\s)]*$'];
        sys2 = regexp(sys2, r, 'match');

        if ~isempty(sys2)
            b = true;
        else
            b = false;
        end
    else
        b = false;
    end
end