function ports = getPorts(blk, type)
% GETPORTS Get the ports meeting a type constraint (see below) for a given 
%   block.
%
%   Inputs:
%       blk     Fullname or handle of a block.
%       type    Char array indicating the type of port. 
%               Any single port type is accepted. The following are also
%               accepted:
%               'All' indicates all types.
%               'In' indicates all incoming ports (everything except Outports).
%               'Special' indicates all ports other than Inports/Outports.
%
%   Outputs:
%       ports   List of handles.

    ph = get_param(blk, 'PortHandles');
    pfields = fieldnames(ph);
    ports = [];

    switch type
        case 'All'
            for i = 1:length(pfields) % for all field types
                ports = [ports, ph.(pfields{i})];
            end
        case 'In'
            for i = setdiff(1:length(pfields), 2) % for all inport field types
                ports = [ports, ph.(pfields{i})];
            end
        case 'Special'
            for i = 3:length(pfields) % for everything other than in/out ports
                ports = [ports, ph.(pfields{i})];
            end
        otherwise
            ports = ph.(type);
    end
end