function inoutBlock = subport2inoutblock(subPort)
% SUBPORT2INOUTBLOCK Get the Inport/Outport block corresponding to a 
%   SubSystem or ModelReference Inport/Outport (i.e. the inport within it).
%
%   Inputs:
%       subPort         Port handle.
%
%   Outputs:
%       inoutBlock      Fullname of corresponding block (path).
%
%   Example:
%       ports = get_param(gcb, 'PortHandles');
%       firstInport = ports.Inport(1);
%       blkName = subport2inoutblock(firstInport);

    parent = get_param(subPort, 'Parent');

    % Input checks
    assert(strcmp(get_param(subPort, 'Type'), 'port'), ...
        'Input is expected to be a port handle.')
    portType = get_param(subPort, 'PortType');
    
    parentType = get_param(parent, 'BlockType');
    assert(strcmp(parentType, 'SubSystem') || strcmp(parentType, 'ModelReference'), ...
        'Input is expected to belong to a SubSystem or Model Reference.')
    
    assert(strcmp(portType, 'outport') || strcmp(portType, 'inport'), ...
        'Input is expected to be either an inport or outport.')

    % Match up port numbers to get the name
    pNum = get_param(subPort, 'PortNumber');
    blockType = [upper(portType(1)), portType(2:end)]; % Capitalize
    if strcmp(parentType, 'ModelReference')
        inoutBlock = cell2mat(find_in_models(parent, 'SearchDepth', 1, ...
            'LookUnderMasks', 'All', ...
            'BlockType', blockType, 'Port', num2str(pNum)));
    else
        inoutBlock = cell2mat(find_system(parent, 'SearchDepth', 1, ...
            'LookUnderMasks','All','IncludeCommented','on','Variants','AllVariants', ...
            'BlockType', blockType, 'Port', num2str(pNum)));
    end
end