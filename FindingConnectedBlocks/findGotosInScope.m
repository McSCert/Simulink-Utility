function goto = findGotosInScope(block)
% FINDGOTOSINSCOPE Find the Goto block associated with a From block.

    if isempty(block)
        goto = {};
        return
    end

    % Ensure block parameter is a valid From block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'From'));
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            ' Block parameter is not a From block.' char(10)])
        help(mfilename)
        goto = {};
        return
    end
    
    tag = get_param(block, 'GotoTag');
    goto = find_system(get_param(block, 'parent'),'SearchDepth', 1,  ...
        'FollowLinks', 'on', 'BlockType', 'Goto', 'GotoTag', tag, 'TagVisibility', 'local');
    if ~isempty(goto)
        return
    end
    
    % Get the corresponding Gotos for a given From that are in the
    % correct scope
    visibilityBlock = findVisibilityTag(block);
    if isempty(visibilityBlock)
        goto = find_system(bdroot(block), 'FollowLinks', 'on', ...
            'BlockType', 'Goto', 'GotoTag', tag, 'TagVisibility', 'global');
        return
    end
    goto = findGotoFromsInScope(visibilityBlock);
    blocksToExclude = find_system(get_param(visibilityBlock, 'parent'), ...
        'FollowLinks', 'on', 'BlockType', 'From', 'GotoTag', tag);
    goto = setdiff(goto, blocksToExclude);
end