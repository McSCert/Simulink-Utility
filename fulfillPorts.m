function fulfillPorts(ports)
% FULFILLPORTS For any unconnected ports, creates a dummy block to connect it to 
% and does so. Outports are connected to terminators and Inports are connected
% to grounds. Unconnected ports are probably indicative of a problem so this 
% function shouldn't be used haphazardly as it may hide problems.
%
%   Inputs:
%       ports   Vector of port handles.
%
%   Outports:
%       N/A

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
        
        if strcmp(get_param(ports(i),'PortType'),'outport')
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
                
                % Get the terminator's inport
                pHandles = get_param(bHandle, 'PortHandles');
                inHandle = pHandles.Inport;
                
                % Connect terminator to ports(i)
                if hasLine
                    delete(line)
                end
                add_line(portSys, ports(i), inHandle);
            end

        else
            % Find line source if it exists
            if hasLine
                if get_param(line,'SrcPortHandle') ~= -1
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