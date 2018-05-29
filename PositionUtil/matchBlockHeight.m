function matchBlockHeight(block, blocks)
    % MATCHBLOCKHEIGHT Adjusts top and bottom positions of a given set of
    % blocks to be the same as an input block.
    %
    % Input:
    %   block   Simulink block fullname or handle.
    %   blocks  Cell array of Simulink block fullnames or handles.
    %
    % Effect:
    %   Blocks shrink or grow around their centre point to match the height
    %   of the given block.
    
    pos = get_param(block,'Position');
    height = pos(4)-pos(2);
    
    for i = 1:length(blocks)
        pos = get_param(blocks{i},'Position');
        vert_center = (pos(4)+pos(2))/2;
        
        newPosition = [pos(1), vert_center-ceil(height/2), pos(3), vert_center+floor(height/2)];
        set_param(blocks{i},'Position', newPosition)
    end
end