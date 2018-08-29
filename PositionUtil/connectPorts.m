function lineHandle = connectPorts(address, port1, port2, varargin)
    % CONNECTPORTS Connect two unconnected ports.
    %
    % Inputs:
    %   address     System name.
    %   port1       A port to connect to port2.
    %   port2       A port to connect to port1.
    %   varargin    Options for add_line (e.g. 'autorouting', 'on').
    %
    % Outputs:
    % 	lineHandles New line handle.
    
    % Input checks
    assert(strcmp(get_param(port1, 'Type'), 'port'), ...
        'Input port1 is expected to be a port handle.')
    assert(strcmp(get_param(port2, 'Type'), 'port'), ...
        'Input port2 is expected to be a port handle.')
    assert(get_param(port1, 'Line') == -1 || ...
        strcmp(get_param(port1, 'PortType'), 'outport'), ...
        'Input port1 already has a line connection.');
    assert(get_param(port2, 'Line') == -1 || ...
        strcmp(get_param(port2, 'PortType'), 'outport'), ...
        'Input port2 already has a line connection.');
    
    port1Type = get_param(port1, 'PortType');
    port2Type = get_param(port2, 'PortType');
    
    errMsg = ['Connecting a line to an Ifaction port of a block with an ' ...
        'unresolved link status may crash MATLAB (due to a MATLAB bug.'];
    if strcmp(port1Type, 'Ifaction')
        ls1 = get_param(get_param(port1, 'Parent'), 'LinkStatus');
        assert(~strcmp(ls1, 'unresolved'), errMsg);
    elseif strcmp(port2Type, 'Ifaction')
        ls2 = get_param(get_param(port2, 'Parent'), 'LinkStatus');
        assert(~strcmp(ls2, 'unresolved'), errMsg);
    end
    
    pfields = {'Inport'; 'Outport'; 'Enable'; 'Trigger'; 'State'; ...
        'LConn'; 'RConn'; 'Ifaction'; 'Reset'};
    infields = lower(setdiff(pfields, {'Outport'}));
    
    assert(xor(any(strcmp(port1Type, infields)), any(strcmp(port2Type, infields))), ...
        'One port must be a source and one must be a destination');
    assert(xor(strcmp(port1Type, 'outport'), strcmp(port2Type, 'outport')), ...
        'One port must be a source and one must be a destination');
    
    % Connect ports
    if strcmp(port1Type, 'outport')
        lineHandle = makeLine(address, port1, port2, varargin{:});
    else
        lineHandle = makeLine(address, port2, port1, varargin{:});
    end
end

function lineH = makeLine(address, out, in, varargin)
    % Connect out to in
    lineH = add_line(address, out, in, varargin{:});
    
    % TODO: If new line is branching, move the connecting point to the furthest 
    % common spot on the two lines .
end

function lineH = makeLine_using_add_line_with_points(address, out, in, varargin)
    % Connect out to in even if a segmented line needs to be created
    %
    % Note this function was made under the belief that the regular use of the
    % add_line function would not work for segmented lines (this was wrong).
    %
    % This approach may be prone to failure when the if with condition
    % ~isSuccess(...) is entered numerous times (through multiple calls) at the
    % given address.
    
    lh = get_param(out, 'Line');
    if lh == -1
        % Ports are not in use, add line normally.
        lineH = add_line(address, out, in, varargin{:});
    else
        % Need to make a segmented/branched line.
        
        if ~isempty(varargin)
            warning([mfilename ' cannot use the options for add_line since a segmented line is being added.'])
        end
        
        % It's possible that MathWorks bug report 1585586 can occur in here,
        % but I failed to duplicate the bug.
        
        % Add line from a point on the existing line of out to the position of
        % the inport.
        points = get_param(lh, 'Points');
        lineH = add_line(address, [points(1,:); get_param(in, 'Position')]);
        
        if ~isSuccess(lineH, out, in)
            % Line was created between different ports.
            % Solution: Move blocks to no-man's land and try again.
            % We'll assume no blocks are near the lower x,y bounds of
            % Simulink instead of checking for vacant space directly.
            
            delete_line(lineH)
            
            outBlock = get_param(out, 'Parent');
            inBlock = get_param(in, 'Parent');
            
            posOut = get_param(outBlock, 'Position');
            posIn = get_param(inBlock, 'Position');
            
            temp = get_param(outBlock, 'PortHandles');
            nOut = length(temp.Outport);
            temp = get_param(inBlock, 'PortHandles');
            nIn = length(temp.Inport);
            
            % Set arbitrary position factors. Resulting heights should
            % be sufficient to separate the ports enough to avoid a
            % repeat of the problem.
            hOut = 30*nOut; hIn = 30*nIn; w = 100; a = -32700; s = w+200;
            
            set_param(outBlock, 'Position', [a a a+w a+hOut])
            set_param(inBlock, 'Position', [a+s a a+s+w a+hIn])
            
            points = get_param(lh, 'Points');
            if isempty(varargin)
                lineH = add_line(address, [points(1,:); get_param(in, 'Position')]);
            else
                lineH = add_line(address, [points(1,:); get_param(in, 'Position')]);
            end
            
            % Put things back
            set_param(outBlock, 'Position', posOut)
            set_param(inBlock, 'Position', posIn)
            
            assert(isSuccess(lineH, out, in), 'Failed to connect ports.')
        end
    end
    
    function bool = isSuccess(line, src, dst)
        bool = get_param(line, 'SrcPortHandle') == src ...
            && get_param(line, 'DstPortHandle') == dst;
    end
end