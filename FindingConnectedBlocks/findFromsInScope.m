function froms = findFromsInScope(block)
% FINDFROMSINSCOPE Find all the From blocks associated with a Goto block.

    if isempty(block)
        froms = {};
        return
    end
    
    % Ensure block parameter is a valid Goto block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'Goto'));
    catch
        help(mfilename)
        froms = {};
        error('Block parameter is not a Goto block.');
        return
    end
    
    tag = get_param(block, 'GotoTag');
    scopedTags = find_system(bdroot(block), 'FollowLinks', 'on', ...
        'BlockType', 'GotoTagVisibility', 'GotoTag', tag);
    level = get_param(block, 'parent');
    tagVis = get_param(block, 'TagVisibility');

    % If there are no corresponding tags, Goto is assumed to be
    % local, and all local Froms corresponding to the tag are found
    if strcmp(tagVis, 'local')
        froms = find_system(level, 'FollowLinks', 'on', 'SearchDepth', 1, ...
            'BlockType', 'From', 'GotoTag', tag);
        return
    elseif strcmp(tagVis, 'scoped');
        visibilityBlock = findVisibilityTag(block);
        froms = findGotoFromsInScope(visibilityBlock);
        blocksToExclude = find_system(get_param(visibilityBlock, 'parent'), ...
            'FollowLinks', 'on', 'BlockType', 'Goto', 'GotoTag', tag);
        froms = setdiff(froms, blocksToExclude);
    else
        fromsToExclude = {};

        for i = 1:length(scopedTags)
            fromsToExclude = [fromsToExclude find_system(get_param(scopedTags{i}, 'parent'), ...
                'FollowLinks', 'on', 'BlockType', 'From', 'GotoTag', tag)];
        end

        localGotos = find_system(bdroot(block), 'BlockType', 'Goto', 'TagVisibility', 'local');
        for i = 1:length(localGotos)
            fromsToExclude = [fromsToExclude find_system(get_param(localGotos{i}, 'parent'), ...
                'SearchDepth', 1, 'FollowLinks', 'on', 'BlockType', 'From', 'GotoTag', tag)];
        end
        
        froms = find_system(bdroot(block), 'FollowLinks', 'on', ...
            'BlockType', 'From', 'GotoTag', tag);
        froms = setdiff(froms, fromsToExclude);
    end
end