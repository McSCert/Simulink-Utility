function [width, pos] = getBlockWidth(block)
    % GETBLOCKWIDTH Find width of given block.
    %
    % Inputs:
    %	block 	Simulink block fullname or handle.
    %
    % Outputs:
    %	width 	Width of the block.
    %	pos 	Position of the block given as [left, top, right, bottom].
    %
    % Examples:
    %	w = getBlockWidth(gcb);
    %	[width, position] = getBlockWidth(gcbh);
    %
    % Anticipated Changes:
    %	Add parameters to determine the position in different ways. E.g. to provide a buffer or to account for parameters appearing below/above the block.
    %

    pos = get_param(block, 'Position');
    width = pos(3)-pos(1);
end