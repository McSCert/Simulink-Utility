
function visBlock = findVisibilityTag(block)
% FINDVISIBILITYTAG Find the Goto Visibility Tag block associated with a
% scoped Goto or From block.

    if isempty(block)
        visBlock = {};
        return
    end

    % Ensure input is a valid Goto/From block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'Goto') || strcmp(blockType, 'From'));
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            ' Block parameter is not a Goto or From block.' char(10)])
        help(mfilename)
        visBlock = {};
        return
    end

    tag = get_param(block, 'GotoTag');
    scopedTags = find_system(bdroot(block), 'FollowLinks', 'on', ...
        'BlockType', 'GotoTagVisibility', 'GotoTag', tag);
    level = get_param(block, 'parent');
    levelSplit = regexp(level, '/', 'split');

    currentLevel = '';

    % Find the Goto Tag Visibility block that is the closest, but above the 
    % block, in the subsystem hierarchy by comparing their addresses
    for i = 1:length(scopedTags)
        % Get the level of tag visibility block
        tagScope = get_param(scopedTags{i}, 'parent');
        tagScopeSplit = regexp(tagScope, '/', 'split');
        inter = tagScopeSplit(ismember(tagScopeSplit, levelSplit));
        
        % Check if it is above the block
        if (length(inter) == length(tagScopeSplit))
            currentLevelSplit = regexp(currentLevel, '/', 'split');
            % If it is the closest to the Goto/From, note that as the correct
            % scope for the visibility block
            if isempty(currentLevel) || length(currentLevelSplit) < length(tagScopeSplit)
                currentLevel = tagScope;
            end
        end
    end
    
    if ~isempty(currentLevel)
        visBlock = find_system(currentLevel, 'FollowLinks', 'on', ...
            'SearchDepth', 1, 'BlockType', 'GotoTagVisibility', 'GotoTag', tag);
        visBlock = visBlock{1};
    else
        visBlock = {};
    end
end