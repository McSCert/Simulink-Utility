function dstPorts = getDstPorts(object)
    % GETDSTPORTS Gets the inports that act as sources for a given block or
    %   dst port.
    %
    %   Input:
    %       object      Can be either the name or the handle of a block or a
    %                   port handle.
    %
    %   Output:
    %       dstPorts    Handles of ports acting as next destinations to the object
    
    if strcmp(get_param(object, 'Type'), 'block')
        block = object;
        lines = get_param(block, 'LineHandles');
        lines = lines.Outport;
    elseif strcmp(get_param(object, 'Type'), 'port')
        port = object;
        lines = get_param(port, 'Line');
    end
    
    dstPorts = [];
    for i = 1:length(lines)
        if lines ~= -1
            dstPorts = [dstPorts; get_param(lines(i), 'DstPortHandle')];
        end
    end
    
end