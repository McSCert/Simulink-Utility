function moveBelow(topBlock,botBlock,buffer)
    %
    %
    % Inputs:
    %   topBlock    Reference block.
    %   botBlock    Move this block below the reference.
    %   buffer      Amount below the reference to move botBlock.
    %
    
    pos1 = get_param(topBlock, 'Position');
    pos2 = get_param(botBlock, 'Position');
    
    shift = (pos1(4)+buffer-pos2(2))*[0 1 0 1]; % [0 1 0 1] only shifts top and bottom
    set_param(botBlock, 'Position', pos2 + shift)
end