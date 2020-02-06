function newLines = redraw_line_lrconn(line, autorouting)
    % Redraw line.
    %
    % Inputs:
    %   line            Simulink line handle.
    %   autorouting     Corresponds with value to pass as the autorouting
    %                   parameter to the add_line function.
    %
    % Outputs:
    %   newLines        Vector of new line handles generated from redrawing
    %                   the given line or returns the original line if it wasn't
    %                   redrawn.
    
    try
        sys = get_param(line, 'Parent');
        continueFlag = true;
    catch ME
        if strcmp(ME.identifier, 'Simulink:Commands:InvSimulinkObjHandle')
            newLines = [];
            continueFlag = false;
        else
            rethrow(ME)
        end
    end
    
    if continueFlag
        
        srcport = get_param(line, 'SrcPortHandle');
        dstports = get_param(line, 'DstPortHandle');
        
        if isequal(-1, srcport) || isequal(-1, dstports)
            % This only seems to be possible when LConn and RConn ports are
            % involved and those cases need to be handled differently.
            % For now we delete all connected lines and redraw them together.
            
            %%
            ports = get_line_ports(line);
            assert(~isempty(ports))
            
            lconns = [];
            rconns = [];
            for k = 1:length(ports)
                assert(strcmp(get_param(ports(k), 'PortType'), 'connection'), 'Unexpected case.')
                lrConnType = getLRConnType(ports(k));
                if strcmp(lrConnType, 'LConn')
                    lconns = [lconns; ports(k)];
                elseif strcmp(lrConnType, 'RConn')
                    rconns = [rconns; ports(k)];
                else
                    error('Unexpected value from getLRConnType.')
                end
            end
            
            %%
            % Layout may vary depending on how source and destination ports are
            % chosen when redrawing these lines, for now the approach is to choose a
            % single source and connect it to each other port.
            if ~isempty(rconns)
                srcport = rconns(1);
                dstports = [rconns(2:end); lconns];
            else
                srcport = lconns(1);
                dstports = lconns(2:end);
            end
            
            % Delete connected lines.
            lines = get_connected_lines(line);
            for k = 1:length(lines)
                if isValidLine(lines(k))
                    delete_line(lines(k))
                end
            end
            
            % Add lines back in with autorouting.
            newLines = zeros(1,length(dstports));
            for k = 1:length(dstports)
                dstport = dstports(k);
                newLines(k) = add_line2(sys, srcport, dstport, 'autorouting', autorouting);
            end
        else
            
            initLineParent = get_param(line, 'LineParent');
            
            % Delete and re-add.
            delete_line(line)
            newLines = zeros(1,length(dstports));
            for k = 1:length(dstports)
                dstport = dstports(k);
                newLines(k) = add_line2(sys, srcport, dstport, 'autorouting', autorouting);
            end
            
            % Add parent line(s)
            % Approach: If the line had multiple dstports, then a single line
            % parent will have been created unless the original line's line parent
            % was reused (could not confirm this is always true (but I couldn't
            % find a case that failed)).
            % Alternate approach: Get all lines coming from the source when this is
            % called, and get all lines after this is called, then take a set
            % difference of lines after minus lines before (this approach could
            % fail if Simulink reuses the deleted handles (which it shouldn't do).
            if length(dstports) > 1
                assert(length(newLines) > 1)
                lineParent = get_param(newLines(1), 'LineParent');
                assert(lineParent ~= -1)
                if lineParent ~= initLineParent % If the parent is new
                    % Add parent to newLines.
                    newLines = [lineParent, newLines];
                    for i = 2:length(newLines)
                        assert(lineParent == get_param(newLines(i), 'LineParent'), 'Expected only one unique line parent from redrawing a line.');
                    end
                end % else the parent is not new.
            end % else no parent to add.
        end
    end
end

function bool = isValidLine(line)
    try
        get_param(line, 'Handle');
        bool = true;
    catch ME
        if strcmp(ME.identifier, 'Simulink:Commands:InvSimulinkObjHandle')
            bool = false;
        else
            rethrow(ME)
        end
    end
end