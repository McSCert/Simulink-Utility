function [bool, direction] = facingPorts(p1,p2)
    % FACINGPORTS determines if port p1 faces port p2. This function says
    % two ports are facing if the side of the blocks they are on are facing
    % (e.g. the right side of one block faces the left side of another
    % block when the right side is left of the left side) and dataflow of
    % each port travels in the same direction.
    % For example if p1 is an outport on the right side of a block and p2
    % is an inport on the left side of a block and p1 is further left than
    % p2, then they are facing.
    %
    %   Inputs:
    %       p1  Port handle.
    %       p2  Port handle.
    %
    %   Outputs:
    %       bool        True when p1 faces p2.
    %       direction   Direction of flow from p1.
    
    p1_side = getPortSideOfBlock(p1);
    p2_side = getPortSideOfBlock(p2);
    
    p1_dir = getPortOrientation(p1);
    p2_dir = getPortOrientation(p2);
    
    p1_pos = get_param(p1, 'Position');
    p2_pos = get_param(p2, 'Position');
    
    cond1 = strcmp(p1_dir,p2_dir); % Same direction of dataflow
    cond2 = strcmp(p2_side, flipDirection(p1_side)); % On opposite sides of their respective blocks
    cond3 = correctPlacement(p1_side, p1_pos, p2_pos); % right before left, top before bottom

    bool = cond1 && cond2 && cond3;
    direction = p1_dir;
end

function bool = correctPlacement(p1_side, p1_pos, p2_pos)
    %
    switch p1_side
        case {'right','left'}
            xy = 1; % 1 - x-axis
        case {'up','down'}
            xy = 2; % 2 - y-axis
        otherwise
            error('Unexpected direction.')
    end
    switch p1_side
        % right/down before left/up
        case {'right','down'}
            bool = p1_pos(xy) < p2_pos(xy);
        case {'left','up'}
            bool = p2_pos(xy) < p1_pos(xy);
        otherwise
            error('Unexpected direction.')
    end
end
function side = getPortSideOfBlock(port)
    % Get the side of block the port is on
    
    if strcmp(get_param(port, 'PortType'), 'outport')
        % The port is on the same side as its orientation
        side = getPortOrientation(port);
    else
        side = flipDirection(getPortOrientation(port));
    end
end
function flip = flipDirection(dir)
    directions = {'right','down','left','up'};
    flippedDirections = {'left','up','right','down'};
    
    flipCell = flippedDirections(strcmp(dir,directions));
    assert(length(flipCell) == 1)
    flip = flipCell{1};
end