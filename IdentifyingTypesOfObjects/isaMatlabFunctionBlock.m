function bool = isaMatlabFunctionBlock(block)
    obj = find(slroot, '-isa', 'Stateflow.EMChart', 'Path', getfullname(block));
    bool = ~isempty(obj);
end

function bool = isaMatlabFunctionBlock_alternate(block)
    % This approach is untested
    if strcmp(get_param(block, 'BlockType'), 'SubSystem')
        bool = strcmp(get_param(block, 'SFBlockType'), 'MATLAB Function');
    end
end