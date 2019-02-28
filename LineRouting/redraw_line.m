function newLines = redraw_line(line, autorouting)
    % Redraw line.
    %
    % Inputs:
    %   line            Simulink line handle.
    %   autorouting     Corresponds with value to pass as the autorouting
    %                   parameter to add_line function.
    % 
    % Outputs:
    %   newLines        Vector of new line handles generated from redrawing
    %                   the given line.
    
    sys = get_param(line, 'Parent');
    
    initLineParent = get_param(line, 'LineParent');
    
    srcport = get_param(line, 'SrcPortHandle');
    dstports = get_param(line, 'DstPortHandle');
    
    % Delete and re-add.
    delete_line(line)
    newLines = zeros(1,length(dstports));
    for k = 1:length(dstports)
        dstport = dstports(k);
        newLines(k) = add_line(sys, srcport, dstport, 'autorouting', autorouting);
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