function ports = getPorts(blk, type, varargin)
    % GETPORTS Get the ports, meeting a type constraint (see below), for a
    % block.
    %
    %   Inputs:
    %       blk         Fullname or handle of a block.
    %       type        Char array indicating the type of port.
    %                   Any single port type is accepted (case sensitive). The
    %                   following are also accepted (case insensitive):
    %                   'All' indicates all types.
    %                   'In' indicates all incoming ports (everything except
    %                       Outports and RConn ports).
    %                   'Out' indicates all outgoing ports (Outports and
    %                       RConn ports).
    %                   'Basic' indicates Inports and Outports.
    %                   'Special' indicates all ports other than Inports and
    %                       Outports.
    %                   'Connection' indicates all LConn and RConn ports.
    %                   Default: 'All'
    %       varargin    Parameter-value pairs where only the ports which have
    %                   the specified values for the corresponding parameters
    %                   will be returned.
    %
    %   Outputs:
    %       ports   List of handles.
    %
    %   Note: RConn ports are treated as outgoing ports and LConn ports are
    %   treated as incoming ports. The developers are not familiar with
    %   these ports so this may not be a correct understanding.
    %
    %   Examples:
    %       % Get all ports of the selected block:
    %       getPorts(gcb)
    %       % or:
    %       getPorts(gcb, 'All')
    %       % Get all outports of the selected block:
    %       getPorts(gcb, 'Out')
    %       % or:
    %       getPorts(gcb, 'outport')
    %       % or:
    %       getPorts(gcb, 'All', 'PortType', 'outport')
    %       % Get the inport with port number of 2:
    %       getPorts(gcb, 'inport', 'PortNumber', 2)
    %
    
    % Input handling:
    if nargin == 1
        type = 'all';
    end
    
    % 
    ph = get_param(blk, 'PortHandles');
    pfields = fieldnames(ph);
    
    typei = lower(type); % lowercase to make it case insensitive
    switch typei
        case 'all'
            indices = 1:length(pfields); % for all field types
        case 'in'
            indices = find(~or(strcmp('Outport',pfields), strcmp('RConn',pfields))); % for all input field types
        case 'out'
            indices = find( or(strcmp('Outport',pfields), strcmp('RConn',pfields))); % for all output field types
        case 'basic'
            indices = find( or(strcmp('Inport',pfields), strcmp('Outport',pfields))); % for Inport and Outport field types
        case 'special'
            indices = find(~or(strcmp('Inport',pfields), strcmp('Outport',pfields))); % for everything other than in/out ports
        case 'connection'
            indices = find( or(strcmp('LConn',pfields), strcmp('RConn',pfields)));
        otherwise
            indices = find(strcmp(type,pfields));
    end
    ports = [];
    for i = 1:length(indices)
        idx = indices(i);
        ports = [ports, ph.(pfields{idx})];
    end
    
    % Remove ports that don't match the parameter-value pair requirements.
    for i = 1:2:length(varargin)
        param = varargin{i};
        desiredValue = varargin{i+1};
        
        giveWarning = false;
        for j = length(ports):-1:1
            % Remove ports that have a different value for the same parameter or
            % if they don't even have the parameter.
            keepPort = false;
            try
                value = get_param(ports(j), param);
                if isequal(value, desiredValue)
                    keepPort = true;
                end
            catch
                giveWarning = true;
            end
            if ~keepPort
                ports(j) = [];
            end
        end
        if giveWarning
            warning(['Not all candidate ports could be compared using the parameter ', param, '.', char(10), ...
                'Ports that gave an error for that parameter are assumed not to be desired results for ' mfilename '.'])
        end
    end
end