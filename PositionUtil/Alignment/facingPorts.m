function [bool, direction] = facingPorts(p1,p2)
    % FACINGPORTS determines if port p1 faces port p2 (direction of
    % dataflow at p1 is the same as the direction at p2 and that the ports
    % are positioned to allow a direct connection).
    % For example if p1 is an outport on the right side of a block and p2
    % is an inport on the left side of a block and p1 is further left than
    % p2, then they are facing.
    %
    %   Inputs:
    %       p1  Port handle.
    %       p2  Port handle.
    %
    %   Outputs:
    %       bool    True when p1 faces p2.
    
    flowDirection1 = getPortOrient(p1);
    flowDirection2 = getPortOrient(p2);
    
    bool = strcmp(flowDirection1, flowDirection2); % same direction of dataflow
    direction = flowDirection1;
    
    bool = bool && correctPositions(p1, p2, direction);
    
    function portOrientation = getPortOrient(port)
        parent = get_param(port,'Parent');
        blockOrientation = get_param(parent,'Orientation');
        portType = get_param(port,'PortType');
        portOrientation = getPortOrientation(blockOrientation, portType);
    end
end

function bool = correctPositions(p1, p2, direction)
    % if direction is right then p2 needs to be right of p1
    % if direction is down then p2 needs to be down of p1
    % if direction is left then p2 needs to be left of p1
    % if direction is up then p2 needs to be up of p1
    
    pos1 = get_param(p1, 'Position');
    pos2 = get_param(p2, 'Position');
    switch direction
        case 'right'
            bool = pos2(1) > pos1(1);
        case 'down'
            bool = pos2(2) > pos1(2);
        case 'left'
            bool = pos2(1) < pos1(1);
        case 'up'
            bool = pos2(2) < pos1(2);
        otherwise
            error('Unexpected direction.')
    end
end
    
function portOrientation = getPortOrientation(blockOrientation, portType)
    
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
    %directionCycle = {'right','down','left','up'};
    bo = blockOrientation;
    dpo = defaultPortOrientation;
    dc = directionCycle;
    po = dc(mod(find(strcmp(dpo,dc))+find(strcmp(bo,dc))-1,length(dc))); % Increments dpo through the cycle by the number of times it takes to get from right to bo
    portOrientation = po;
end