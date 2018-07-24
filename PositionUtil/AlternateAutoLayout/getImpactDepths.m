function depths = getImpactDepths(blocks)
    
    % This is just an arbitrary and reasonable approach (i.e. specific
    % choices about what depths a block should have were not made for
    % particular reasons)
    %
    % perhaps it should be that blocks have maximum depth except when a
    % part of a loop
    
    blocks = inputToNumeric(blocks); % Want cell array of block handles
    
    if isempty(blocks)
        depths = [];
    else
        block2struct = containers.Map('KeyType', 'double', 'ValueType', 'double'); % Convert from block handle to index in impactStruct
        for i = 1:length(blocks)
            block = blocks(i);
            block2struct(block) = i;
        end
        
        impactStruct = cell(1, length(blocks));
        for i = 1:length(blocks)
            block = blocks(i);
            
            dsts = getDsts(block, 'IncludeImplicit', 'on', ...
                'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
                'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'block'});
            dsts = remove_if_not_key(dsts, block2struct);
            
            srcs = getSrcs(block, 'IncludeImplicit', 'on', ...
                'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
                'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'block'});
            srcs = remove_if_not_key(srcs,block2struct);
            
            impactStruct{i} =  struct('block', block, 'dstblocks', dsts, 'srcblocks', srcs);
        end
        
        first_sources = []; % Initial guess
        for i = 1:length(impactStruct)
            if isempty(impactStruct{i}.srcblocks)
                first_sources = [first_sources, impactStruct{i}.block];
            end
        end
        
        if isempty(first_sources)
            first_sources = blocks(1);
        end
        
        depths = getDepths(first_sources, impactStruct, block2struct);
    end
end

function depths = getDepths(first_sources, impactStruct, block2struct)
    depths = zeros(1,length(impactStruct)); % Initialize (note 0 is not allowed in final depths)
    depths = getDepths_Aux(first_sources, impactStruct, block2struct, 1, depths);
    assert(all(depths ~= 0))
end

function depths = getDepths_Aux(srcs, impactStruct, block2struct, minDepth, depths)
    for i = 1:length(srcs)
        block = srcs(i);
        index = block2struct(block);
        
        depths(index) = minDepth;
        
        dsts = impactStruct{index}.dstblocks;
        for j = 1:length(dsts)
            depth = depths(block2struct(dsts(j)));
            if 0 == depth
                depths = getDepths_Aux(impactStruct{index}.dstblocks, impactStruct, block2struct, minDepth+1, depths);
            end
        end
    end
end

function keys = remove_if_not_key(items, map)
    keys = items;
    for i = length(keys):-1:1
        if ~map.isKey(keys(i))
            keys(i) = [];
        end
    end
end