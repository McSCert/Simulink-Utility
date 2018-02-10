function blockList = findReadWritesInScope(block)
% FINDREADWRITESINSCOPE Find all the Data Store Read and Data Store Write 
% blocks associated with a Data Store Memory block.

    if isempty(block)
        blockList = {};
        return
    end

    % Ensure input is a valid Data Store Memory block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'DataStoreMemory'));
    catch
        help(mfilename)
        blockList = {};
        error('Block parameter is not a Data Store Memory block.');
        return
    end

    % Get all other Data Store Memory blocks
    dataStoreName = get_param(block, 'DataStoreName');
    blockParent = get_param(block, 'parent');
    memsSameName = find_system(blockParent, 'FollowLinks', 'on', ...
        'BlockType', 'DataStoreMemory', 'DataStoreName', dataStoreName);
    memsSameName = setdiff(memsSameName, block);
    
    % Exclude any Data Store Read/Write blocks which are in the scope of 
    % other Data Store Memory blocks
    blocksToExclude = {};
    for i = 1:length(memsSameName)
        memParent = get_param(memsSameName{i}, 'parent');
        blocksToExclude = [blocksToExclude; find_system(memParent, 'FollowLinks', ...
            'on', 'BlockType', 'DataStoreRead', 'DataStoreName', dataStoreName)];
        blocksToExclude = [blocksToExclude; find_system(memParent, 'FollowLinks', ...
            'on', 'BlockType', 'DataStoreWrite', 'DataStoreName', dataStoreName)];
    end
    
    % Remove the blocks to exclude from the list of Reads/Writes with the
    % same name as input Data Store Memory block
    blockList = find_system(blockParent, 'FollowLinks', 'on', ...
        'BlockType', 'DataStoreRead', 'DataStoreName', dataStoreName);
    blockList = [blockList; find_system(blockParent, 'FollowLinks', 'on', ...
        'BlockType', 'DataStoreWrite', 'DataStoreName', dataStoreName)];
    blockList = setdiff(blockList, blocksToExclude);
end