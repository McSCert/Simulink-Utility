function sortedBlocks = sortBlocksByTop(blocks)
    % SORTBLOCKSBYTOP Sorts a cell array of blocks (format is important if
    % some spaces are empty) and returns a cell array of the blocks sorted
    % from the block with the lowest top position to the block with the
    % greatest top position (this is from high to low when looking at block
    % diagrams).
    %
    % Inputs:
    %   blocks  Cell array of Simulink blocks.
    %
    % Outputs:
    %   sortedBlocks    Cell array of blocks sorted by their top positions.
    %
    
    tops = zeros(1,length(blocks));
    for i = 1:length(blocks)
        b = blocks{i};
        pos = get_param(b, 'Position');
        tops(i) = pos(2);
    end
    [~, order] = sort(tops);
    sortedBlocks = blocks(order);
end