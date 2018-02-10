function reads = findReadsInScope(block)
% FINDREADSINSCOPE Find all the Data Store Read blocks associated with a Data
% Store Write block.

    if isempty(block)
        reads = {};
        return
    end

    % Ensure input is a valid data store write block
    try
        assert(strcmp(get_param(block, 'type'), 'block'));
        blockType = get_param(block, 'BlockType');
        assert(strcmp(blockType, 'DataStoreWrite'));
    catch
        help(mfilename)
        reads = {};
        error('Block parameter is not a Data Store Write block.');
        return
    end
    
    dataStoreName = get_param(block, 'DataStoreName');
    memBlock = findDataStoreMemory(block);
    reads = findReadWritesInScope(memBlock);
    blocksToExclude = find_system(get_param(memBlock, 'parent'), 'FollowLinks', ...
        'on', 'BlockType', 'DataStoreWrite', 'DataStoreName', dataStoreName);
    reads = setdiff(reads, blocksToExclude);
end