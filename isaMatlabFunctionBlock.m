function bool = isaMatlabFunctionBlock(block)
    obj = find(slroot, '-isa', 'Stateflow.EMChart', 'Path', getfullname(block));
    bool = ~isempty(obj);
end