function subPort = inoutblock2subport(inoutBlock)
% INOUTBLOCK2SUBPORT Get the SubSystem or ModelReference port handle corresponding 
%   to an Inport/Outport block.
%
%   Inputs:
%       inoutBlock  Inport or outport block.
%
%   Outputs:
%       subPort     Port handle, or [] if top-level of a model.
%
%   Example:
%       hdl = inoutblock2subport(gcb)

    blockType = get_param(inoutBlock, 'BlockType');
    assert(strcmp(blockType,'Inport') || strcmp(blockType,'Outport'), ...
        'Unexpected input block type.')

    pNum = str2double(get_param(inoutBlock, 'Port'));
    parent = get_param(inoutBlock, 'Parent');
    if strcmp(get_param(parent, 'Type'), 'block_diagram')
        referenceParent = get_param(parent, 'ModelReferenceParent');
            
        if referenceParent % Root of model but has a Model Reference block as parent
            [mdls, mdlblks] = find_mdlrefs(referenceParent, 'AllLevels', false);
            idx = find(ismember(mdls, parent));
            referenceBlock = cell2mat(mdlblks(idx));
            subPorts = get_param(referenceBlock, 'PortHandles');
            subPorts = getfield(subPorts, blockType);
            
            for i = 1:length(subPorts)
                if get_param(subPorts(i), 'PortNumber') == pNum
                    subPort = subPorts(i);
                    return
                end
            end
            
        else % Root of a model
            subPort = [];
        end
    else 
        subPorts = get_param(parent, 'PortHandles');
        subPorts = getfield(subPorts, blockType);

        for i = 1:length(subPorts)
            if get_param(subPorts(i), 'PortNumber') == pNum
                subPort = subPorts(i);
                return
            end
        end
        assert(exist('subPort', 'var'))
    end
end