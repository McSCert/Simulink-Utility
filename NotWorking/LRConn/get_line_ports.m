function ports = get_line_ports(line)
    % Gets all ports that the given line connects with.
    % The focus of this function is to give correct results even when the line
    % connects to connection ports (i.e. LConn and RConn ports).
    %
    %   Inputs:
    %       line    Line handle.
    %
    %   Outputs:
    %       ports   Vector of port handles.
    %
    
    lines = get_connected_lines(line);
    
    sys = get_param(line, 'Parent');
    sysPorts = find_system(sys, 'SearchDepth', '1', 'FindAll', 'on', 'Type', 'port');
    
    ports = [];
    for i = 1:length(sysPorts)
        tmpLine = get_param(sysPorts(i), 'Line');
        
        if any(tmpLine == lines)
            % The port connected to tmpLine is one of the ports linked to the
            % original line.
            
            ports = [ports; sysPorts(i)];
        end % else the port connected to tmpLine is unrelated.
    end
end

function ports = get_line_ports_old(line)
    % This approach doesn't work for LConn and RConn blocks because lines
    % connected to them don't always have a SrcPortHandle or DstPortHandle.
    %
    %   Inputs:
    %       line    Line handle.
    %
    %   Outputs:
    %       ports   Vector of port handles.
    %
    
    lines = get_connected_lines(line);
    
    ports = [];
    for i = 1:length(lines)
        srcPorts = get_param(lines(i), 'SrcPortHandle');
        dstPorts = get_param(lines(i), 'DstPortHandle');
        
        for j = 1:length(srcPorts)
            if ~isequal(srcPorts(j), -1)
                ports = [ports; srcPorts(j)];
            end
        end
        
        for j = 1:length(dstPorts)
            if ~isequal(dstPorts(j), -1)
                ports = [ports; dstPorts(j)];
            end
        end
    end
end