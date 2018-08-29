function position = alignPorts(port1, port2, varargin)
% ALIGNPORTS Move the second block veritcally so that the ports are aligned.
% Return position of the moved block.

    % Option to not perform the operation, but just return the position that
    % the second block would have been moved to.
    if isempty(varargin)
        performAlign = true;
    else
        performAlign = varargin{1};
    end

    %
    assert(strcmp(get_param(port1, 'Type'), 'port') && (strcmp(get_param(port2, 'Type'), 'port')), ...
        'Inputs port1 and port2 must be ports.');

    % Ensure the ports are facing otherwise alignment won't look good
    [bool, direction] = facingPorts(port1,port2);
    assert(bool)
    
    %
    port2Block = get_param(port2, 'Parent'); % blocks being moved
    port2BlockPos = get_param(port2Block, 'Position');
    
    port1Pos = get_param(port1, 'Position');    % 1x2
    port2Pos = get_param(port2, 'Position');    % 1x2
    
    portDistanceY = port1Pos(2) - port2Pos(2);
    
    if any(strcmp(direction,{'right','left'}))
        shift = (portDistanceY)*[0 1 0 1]; % shift on y axis
    elseif any(strcmp(direction,{'down','up'}))
        shift = (port1Pos(1) - port2Pos(1))*[1 0 1 0]; % shift on x axis
    end
    
    position = port2BlockPos + shift;
    if performAlign
        set_param(port2Block, 'Position', position)
    end % else return position
end