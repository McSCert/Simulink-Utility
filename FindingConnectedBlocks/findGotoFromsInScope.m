function blockList = findGotoFromsInScope(block)
% FINDGOTOFROMSINSCOPE Find all the Goto and From blocks associated with a 
% Goto Tag Visibility block.

    if isempty(block)
        blockList = {};
        return
    end

    % Ensure input is a valid Goto Tag Visibility block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'GotoTagVisibility'));
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            ' Block parameter is not a Goto Tag Visibility block.' char(10)])
        help(mfilename)
        blockList = {};
        return
    end
    
    % Get all other Goto Tag Visibility blocks
    gotoTag = get_param(block, 'GotoTag');
    blockParent = get_param(block, 'parent');
    tagsSameName = find_system(blockParent, 'FollowLinks', 'on', ...
        'BlockType', 'GotoTagVisibility', 'GotoTag', gotoTag);
    tagsSameName = setdiff(tagsSameName, block);
    
    % Any Goto/From blocks in their scopes are listed as blocks not in the
    % input Goto Tag Visibility block's scope
    blocksToExclude = {};
    for i = 1:length(tagsSameName)
        tagParent = get_param(tagsSameName{i}, 'parent');
        blocksToExclude = [blocksToExclude; find_system(tagParent, ...
            'FollowLinks', 'on', 'BlockType', 'From', 'GotoTag', gotoTag)];
        blocksToExclude = [blocksToExclude; find_system(tagParent, ...
            'FollowLinks', 'on', 'BlockType', 'Goto', 'GotoTag', gotoTag)];
    end
    
    % All Froms associated with local Gotos are listed as blocks not in the 
    % scope of input Goto Tag Visibility block
    localGotos = find_system(blockParent, 'FollowLinks', 'on', ...
        'BlockType', 'Goto', 'GotoTag', gotoTag, 'TagVisibility', 'local');
    for i = 1:length(localGotos)
        froms = find_system(get_param(localGotos{i}, 'parent'), ...
            'FollowLinks', 'on', 'SearchDepth', 1, 'BlockType', 'From', 'GotoTag', gotoTag);
        blocksToExclude = [blocksToExclude; localGotos{i}; froms];
    end
    
    % Remove all excluded blocks
    blockList = find_system(blockParent, 'FollowLinks', 'on', ...
        'BlockType', 'From', 'GotoTag', gotoTag);
    blockList = [blockList; find_system(blockParent, 'FollowLinks', 'on', ...
        'BlockType', 'Goto', 'GotoTag', gotoTag)];
    blockList = setdiff(blockList, blocksToExclude);
end