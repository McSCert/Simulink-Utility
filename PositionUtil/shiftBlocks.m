function shiftBlocks(blocks, shift)
    %
    % blocks - Cell array of blocks
    % shift - 1x4 vector to add to position value of blocks
    
    for i = 1:length(blocks)
        b = blocks{i};
        pos = get_param(b, 'Position');
        set_param(b, 'Position', pos + shift);
    end
end