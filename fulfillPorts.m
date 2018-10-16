function handles = fulfillPorts(ports)
% FULFILLPORTS For unconnected ports, creates a Ground or Terminator block
%   and connects to it with a signal line. Outports are connected to Terminators
%   and Inports are connected to Grounds. Already connected ports are skipped.
%
%   Inputs:
%       ports   Vector of port handles.
%
%   Outports:
%       N/A

    handles = ones(size(ports)) * -1; % -1 if no terminator/ground added
    for i = 1:length(ports)

        % Find line if it exists
        line = get_param(ports(i), 'Line');
        if line ~= -1
            hasLine = true;
        else
            hasLine = false;
        end

        % Get the port's system
        portSys = get_param(get_param(ports(i), 'Parent'), 'Parent');

        if strcmp(get_param(ports(i), 'PortType'), 'outport')
            % Find line destination if it exists
            if hasLine
                if get_param(line,'DstPortHandle') ~= -1
                    hasDst = true;
                else
                    hasDst = false;
                end
            else
                hasDst = false;
            end

            if ~hasDst
                % Create terminator
                bHandle = add_block('built-in/Terminator', ...
                    [portSys '/generated_terminator'], 'MakeNameUnique', 'on');
                handles(i) = bHandle;

                % Get the terminator's inport
                pHandles = get_param(bHandle, 'PortHandles');
                inHandle = pHandles.Inport;

                % Connect terminator to ports(i)
                if hasLine
                    delete(line)
                end
                add_line(portSys, ports(i), inHandle);
            end

        else % Inport, Trigger
            % Find line source if it exists
            if hasLine
                if get_param(line, 'SrcPortHandle') ~= -1
                    hasSrc = true;
                else
                    hasSrc = false;
                end
            else
                hasSrc = false;
            end

            if ~hasSrc
                % Create ground
                bHandle = add_block('built-in/Ground', ...
                    [portSys '/generated_ground'], 'MakeNameUnique', 'on');
                 handles(i) = bHandle;

                % Get the ground's inport
                pHandles = get_param(bHandle, 'PortHandles');
                outHandle = pHandles.Outport;

                % Connect ground to ports(i)
                if hasLine
                    delete(line)
                end
                add_line(portSys, outHandle, ports(i));
            end
        end
    end
end