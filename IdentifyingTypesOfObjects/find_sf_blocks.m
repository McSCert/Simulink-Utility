function [blocks, types] = find_sf_blocks(sys)
    % FIND_SF_BLOCKS Find blocks in sys with 'SFBlockType' parameter that is not
    % 'NONE'.
    %
    % Inputs:
    %   sys     Simulink system.
    %
    % Outputs:
    %   blocks  nx1 cell array of block names.
    %   types   nx1 cell array of the corresponding block's 'SFBlockType'.
    %
    
    blocks = {};
    types = {};
    
    sysBlocks = find_system(sys, 'Type', 'Block');
    for i = 1:length(sysBlocks)
        b = sysBlocks{i};
        if strcmp(get_param(b, 'BlockType'), 'SubSystem')
            type = get_param(b, 'SFBlockType');
            if ~strcmp(type, 'NONE')
                blocks{end+1} = b;
                types{end+1} = type;
            end
        end
    end
    blocks = blocks';
    types = types';
end