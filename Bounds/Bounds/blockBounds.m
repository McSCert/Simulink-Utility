function bounds = blockBounds(block)
    
    % TODO allow extra arguments to specify that parameters showing with
    % the block should be accounted for.
    bounds = get_param(block,'Position');
end