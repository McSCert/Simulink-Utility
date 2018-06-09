function portOrientation = getPortOrientation(port)
    parent = get_param(port,'Parent');
    blockOrientation = get_param(parent,'Orientation');
    portType = get_param(port,'PortType');
    portOrientation = getPortOrientFromBlockOrentation(blockOrientation, portType);
end

function portOrientation = getPortOrientFromBlockOrentation(blockOrientation, portType)
    
    if any(strcmp(portType, {'inport','outport'}))
        defaultOrientation = 'right';
    else
        defaultOrientation = 'down';
    end
    
    if strcmp(defaultOrientation, 'right')
        portOrientation = blockOrientation;
    else
        switch blockOrientation
            case 'right'
                portOrientation = 'down';
            case 'down'
                portOrientation = 'left';
            case 'left'
                portOrientation = 'up';
            case 'up'
                portOrientation = 'right';
            otherwise
                error('Unexpected block orientation.')
        end
    end
end

function portOrientation = getPortOrientationGeneral(blockOrientation, defaultPortOrientation, directionCycle)
    % An approach to getting port orientation that doesn't rely on
    % conditions.
    
    %directionCycle = {'right','down','left','up'};
    bo = blockOrientation;
    dpo = defaultPortOrientation;
    dc = directionCycle;
    po = dc(mod(find(strcmp(dpo,dc))+find(strcmp(bo,dc))-1,length(dc))); % Increments dpo through the cycle by the number of times it takes to get from right to bo
    portOrientation = po;
end