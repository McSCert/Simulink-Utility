function type = getLRConnType(ph)
    % Figures out if port is an LConn or an RConn assuming that
    % get_param(ph, 'PortType') is 'connection'.
    
    block = get_param(ph, 'Parent');
    blockPorts = get_param(block, 'PortHandles');
    isL = any(blockPorts.LConn == ph);
    isR = any(blockPorts.RConn == ph);
    
    assert(isL || isR)
    assert(~isL || ~isR)
    
    if isL
        type = 'LConn';
    else
        type = 'RConn';
    end
end