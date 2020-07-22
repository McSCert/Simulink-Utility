function path = commonParent(sys1, sys2)
% COMMONPARENT Find the first (top-most) common parent between two blocks.
%
%   Inputs:
%       sys1    Block path name or handle.
%       sys2    Block path name or handle.
%
%   Outputs:
%       path    Path to common parent.
%
%   See COMMONPARENTS for finding a common parent for multiple blocks.

    % If handles, change to paths for later string operations
    if isnumeric(sys1)
        sys1 = getfullname(sys1);
    end
    if isnumeric(sys2)
        sys2 = getfullname(sys2);
    end
    
    % Compare each element in the path, starting at the root
    path1 = strsplit(sys1, '/');
    path2 = strsplit(sys2, '/');
    
    commonPath = path1{1};
    for i = 2:min(length(path1), length(path2))
        if strcmp(path1{i}, path2{i})
            commonPath =  [commonPath '/' path1{i}];
        else
            break;
        end
    end
    path = commonPath;
end