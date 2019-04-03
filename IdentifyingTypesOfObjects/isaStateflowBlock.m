function bool = isaStateflowBlock(block)
    if strcmp(get_param(block, 'BlockType'), 'SubSystem')
        bool = strcmp(get_param(block, 'SFBlockType'), 'Chart');
    end
end