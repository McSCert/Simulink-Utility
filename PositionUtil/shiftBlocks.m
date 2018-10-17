function shiftBlocks(blocks, shift)
    % SHIFTBLOCKS Shift block position.
    %
    %   Inputs:
    %       block       Simulink block fullnames or handles.
    %       shift       Vector of coordinates, in pixels: [left top right bottom].
    %
    %   Outputs:
    %       N/A

    % Convert fullnames to handles.
    blocks = inputToNumeric(blocks);

    for i = 1:length(blocks)
        b = blocks(i);
        pos = get_param(b, 'Position');
        set_param(b, 'Position', pos + shift);
    end
end