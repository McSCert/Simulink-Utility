function ports = getPorts(blk, type)
    % GETPORTS Get the ports meeting a type constraint (see below) for a given
    %   block.
    %
    %   Inputs:
    %       blk     Fullname or handle of a block.
    %       type    Char array indicating the type of port.
    %               Any single port type is accepted (case sensitive). The
    %               following are also accepted (case insensitive):
    %               'All' indicates all types.
    %               'In' indicates all incoming ports (everything except Outports).
    %               'Out' indicates all outgoing ports (Outports).
    %               'Basic' indicates Inports and Outports.
    %               'Special' indicates all ports other than Inports and Outports.
    %
    %   Outputs:
    %       ports   List of handles.
    
    ph = get_param(blk, 'PortHandles');
    pfields = fieldnames(ph);
    
    typei = lower(type); % lowercase to make it case insensitive
    switch typei
        case 'all'
            indices = 1:length(pfields); % for all field types
        case 'in'
            indices = find(~strcmp('Outport',pfields)); % for all inport field types
        case 'out'
            indices = find( strcmp('Outport',pfields)); % for Outport field type
        case 'basic'
            indices = find( or(strcmp('Inport',pfields), strcmp('Outport',pfields))); % for Inport and Outport field types
        case 'special'
            indices = find(~or(strcmp('Inport',pfields), strcmp('Outport',pfields))); % for everything other than in/out ports
        otherwise
            indices = find(strcmp(type,pfields));
    end
    ports = [];
    for i = 1:length(indices)
		idx = indices(i);
        ports = [ports, ph.(pfields{idx})];
    end
end