function maxDepth = find_max_depth(sys)
    % Find maximum depth from given subsystem.
    
    [~, subsystems] = find_subsystems(sys);
    
    maxDepth = 1;
    for i = 1:length(subsystems)
        sub = subsystems{i};
        if get_depth(sys, sub) + 1 > maxDepth
            maxDepth = get_depth(sys, sub) + 1;
        end
    end
end

function depth = get_depth(sys, block, varargin)
    
    if isempty(varargin)
        depth = 0;
    else
        depth = varargin{1};
    end
    
    if ~strcmp(sys, block)
        parent = get_param(block, 'Parent');
        depth = get_depth(sys, parent, depth + 1);
    end
end