function srcPorts = getSrcPorts(object)
    % GETSRCPORTS Gets the outports that act as sources for a given block or
    %   dst port. In this function, an outport is its own source.
    %
    %   Input:
    %       object      Can be either the name or the handle of a block or a
    %                   port handle.
    %
    %   Output:
    %       srcPorts    Handles of ports acting as sources to the object.
    
    if strcmp(get_param(object,'Type'), 'port') ...
            && strcmp(get_param(object,'PortType'), 'outport')
        srcPorts = object;
    else
        % Get next outports from handle h at current depth
        srcPorts = getSrcs(object, 'IncludeImplicit', 'on', ...
            'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
            'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'outport'});
    end
end

function srcPorts = getSrcPorts_old(object)
    if strcmp(get_param(object, 'Type'), 'block')
        block = object;
        lines = get_param(block, 'LineHandles');
        lines = lines.Inport;
    elseif strcmp(get_param(object, 'Type'), 'port')
        port = object;
        lines = get_param(port, 'Line');
    else
        error(['Error: ' mfilename 'expected object type to be ''block'' or ''port'''])
    end
    
    srcPorts = [];
    for i = 1:length(lines)
        if lines(i) ~= -1
            srcPorts(end+1) = get_param(lines(i), 'SrcPortHandle');
        end
    end
end