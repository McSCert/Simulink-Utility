function newBlocks = branching2multiple(blocks, bTypes)
    % BRANCHING2MULTIPLE Blocks of any of the given block types that are
    % followed by a branched line will be split into multiple blocks of
    % that type with no branched line. The block types must have no input
    % ports and exactly 1 outport.
    %
    % Input:
    %   blocks  A vector of handles of blocks that are allowed to be
    %           copied.
    %   bTypes  Cell array of chars of block types for which to make copies
    %           instead of branching. Each block type has no input ports
    %           and 1 outport.
    %
    % Output:
    %   newBlocks   A vector of handles of blocks created.
    %
    
    blocks = inputToNumeric(blocks);
    
    % For all constants
    % Get the single line which exits the block
    % If the line is a branching line, then get the list of ports it
    % connects to
    % Create a copy (with unique name) of the original block for each port
    % beyond the first
    % Delete the branching line
    % Create a line from the single outport of the original block/each
    % copied block to different ports in the list generated earlier
    % Each of the ports in the list should be connected
    newBlocks = [];
    for i = 1:length(bTypes)
        bType = bTypes{i};
        blocks_of_bType = blocks(strcmp(get_param(blocks, 'BlockType'), bType)); % get blocks with current blockType as bType
        for j = 1:length(blocks_of_bType)
            block = blocks_of_bType(j);
            
            dsts = getDsts(block, 'IncludeImplicit', 'off', ...
                'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
                'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'line'});
            assert(length(dsts) == 1)
            line = dsts(1);
            
            if isBranching(line)
                dsts = getDsts(block, 'IncludeImplicit', 'off', ...
                    'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
                    'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'ins'});
                
                
                srcBlocks = zeros(1,length(dsts));
                srcBlocks(1) = block;
                for k = 2:length(dsts)
                    srcBlocks(k) = copy_block(block, sys); % returns generated block handle
                end
                newBlocks = [newBlocks, srcBlocks];
                
                delete_line(line)
                
                for k = 1:length(dsts)
                    oport = getPorts(srcBlocks(k), 'Out');
                    assert(length(oport) == 1)
                    connectPorts(sys, oport(1), dsts(k));
                end
            end
        end
    end
end

function newBlocks = branching2multiple_sys(sys, bTypes)
    % This is an old function, now run:
    % blocks = find_system(sys, 'LookUnderMasks','All', ...
    %   'IncludeCommented','off', 'Variants','AllVariants');
    % blocks = inputToCell(blocks);
    % branching2multiple(blocks, bTypes);
    %
    % BRANCHING2MULTIPLE_SYS Blocks of any of the given block types that are
    % followed by a branched line will be split into multiple blocks of
    % that type with no branched line. The block types must have no input
    % ports and exactly 1 outport.
    %
    % Input:
    %   sys     A Simulink system.
    %   bTypes  Cell array of chars of block types for which to make copies
    %           instead of branching. Each block type has no input ports
    %           and 1 outport.
    %
    % Output:
    %   newBlocks   A vector of handles of blocks created.
    %
    
    % For all constants
    % Get the single line which exits the block
    % If the line is a branching line, then get the list of ports it
    % connects to
    % Create a copy (with unique name) of the original block for each port
    % beyond the first
    % Delete the branching line
    % Create a line from the single outport of the original block/each
    % copied block to different ports in the list generated earlier
    % Each of the ports in the list should be connected
    newBlocks = [];
    for i = 1:length(bTypes)
        bType = bTypes{i};
        blocks = find_system_BlockType(sys, bType);
        for j = 1:length(blocks)
            block = get_param(blocks{j}, 'Handle');
            
            dsts = getDsts(block, 'IncludeImplicit', 'off', ...
                'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
                'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'line'});
            assert(length(dsts) == 1)
            line = dsts(1);
            
            if isBranching(line)
                dsts = getDsts(block, 'IncludeImplicit', 'off', ...
                    'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
                    'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'ins'});
                
                
                srcBlocks = zeros(1,length(dsts));
                srcBlocks(1) = block;
                for k = 2:length(dsts)
                    srcBlocks(k) = copy_block(block, sys); % returns generated block handle
                end
                newBlocks = [newBlocks, srcBlocks];
                
                delete_line(line)
                
                for k = 1:length(dsts)
                    oport = getPorts(srcBlocks(k), 'Out');
                    assert(length(oport) == 1)
                    connectPorts(sys, oport(1), dsts(k));
                end
            end
        end
    end
end

function blocks = find_system_BlockType(sys, bType)
    blocks = find_system(sys, ...
        'LookUnderMasks','All', ...
        'IncludeCommented','off', ...
        'Variants','AllVariants', ...
        'BlockType', bType);
    blocks = inputToCell(blocks);
end

function branchingImplicit2multipleImplicit(sys)
    % Old function, branching2multiple_sys(sys, {'From','DataStoreRead'})
    % has the same effect.
    %
    % implicit signals that are followed by a branched line will be split
    % into multiple implicit signals with no branched line.
    % i.e. If the output of a From branches to 2 input ports, then the
    % result will have 2 Froms, one going to each of the 2 input ports that
    % were branched to. Likewise for DataStoreReads
    
    % For all froms, also for all reads
    % Get the single line which exits the block
    % If the line is a branching line, then get the list of ports it
    % connects to
    % Create a copy (with unique name) of the original block for each port
    % beyond the first
    % Delete the branching line
    % Create a line from the single outport of the original block/each
    % copied block to different ports in the list generated earlier
    % Each of the ports in the list should be connected
    bTypes = {'From','DataStoreRead'};
    for i = 1:length(bTypes)
        bType = bTypes{i};
        blocks = find_system_BlockType(sys, bType);
        for j = 1:length(blocks)
            block = get_param(blocks{j}, 'Handle');
            
            dsts = getDsts(block, 'IncludeImplicit', 'off', ...
                'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
                'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'line'});
            assert(length(dsts) == 1)
            line = dsts(1);
            
            if isBranching(line)
                dsts = getDsts(block, 'IncludeImplicit', 'off', ...
                    'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
                    'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'ins'});
                
                
                srcBlocks = zeros(1,length(dsts));
                srcBlocks(1) = block;
                for k = 2:length(dsts)
                    srcBlocks(k) = copy_block(block, sys);
                end
                
                delete_line(line)
                
                for k = 1:length(dsts)
                    oport = getPorts(srcBlocks(k), 'Out');
                    assert(length(oport) == 1)
                    connectPorts(sys, oport(1), dsts(k));
                end
            end
        end
    end
end