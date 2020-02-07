function blocks = find_top_level_blocks(model, blocktype)
    % Finds a cell array of blocks of given type in the top-level of the given
    % model, OR if no block of that type is found then the blocks of the given
    % type found one level below top-level are returned.
    %
    
    % Find top-level blocks of blocktype in model.
    blocks = find_system(model, 'SearchDepth', '1', 'FollowLinks', 'on', 'BlockType', blocktype);
    if isempty(blocks)
        % Check 1 level deeper for blocks. Some models are designed with
        % the top-level being just a subsystem with no connections, in this
        % case we should use the blocks within that subsystem.
        blocks = find_system(model, 'SearchDepth', '2', 'FollowLinks', 'on', 'BlockType', blocktype);
    end
end