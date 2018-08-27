function shiftBlocks(blocks, shift)
    %
    %   block       List (cell array or vector) of Simulink blocks (fullnames or
    %               handles).
    %   shift       1x4 vector to add to position value of blocks.
    
    %
    blocks = inputToNumeric(blocks);
    
    %
    for i = 1:length(blocks)
        b = blocks(i);
        pos = get_param(b, 'Position');
        set_param(b, 'Position', pos + shift);
    end
end