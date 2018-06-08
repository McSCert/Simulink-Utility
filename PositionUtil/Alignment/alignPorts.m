function alignPorts(port1, port2)
% ALIGNPORTS Move the second block veritcally so that the ports are aligned.

    assert(strcmp(get_param(port1, 'Type'), 'port') && (strcmp(get_param(port2, 'Type'), 'port')), ...
        'Inputs port1 and port2 must be ports.');

    port2Block = get_param(port2, 'Parent');
    port2BlockPos = get_param(port2Block, 'Position');
    
    port1Pos = get_param(port1, 'Position');    % 1x2
    port2Pos = get_param(port2, 'Position');    % 1x2
    
    portDistanceY = port2Pos(2) - port1Pos(2);
    port2BlockHeight = port2BlockPos(4) - port2BlockPos(2);    % 1x4
    
    newTop = port2BlockPos(2) - portDistanceY;
    newBottom = port2BlockPos(2) + port2BlockHeight - portDistanceY;
    set_param(port2Block, 'Position', [port2BlockPos(1), newTop, port2BlockPos(3), newBottom]);
end