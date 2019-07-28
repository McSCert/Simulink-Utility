function connectedLines = get_connected_lines(lines)
    % Get all lines connected to the given vector of line handles
    %
    % This function incorrectly assumes that a series of connected lines are
    % connected by line parents and children. It seems like this assumption can
    % be violated when LConn and RConn ports are involved.
    
    connectedLines = get_connected_lines_aux(lines, []);
end

function connectedLines = get_connected_lines_aux(currentLines, oldLines)
    %
    % currentLines have not been checked for new connections yet
    % oldLines have been checked for new connections already
    %
    
    % Get new lines from current lines.
    newLines = [];
    for i = 1:length(currentLines)
        lineChildren = get_param(currentLines(i), 'LineChildren');
        if isequal(lineChildren, -1)
            lineChildren = [];
        end
        
        lineParent = get_param(currentLines(i), 'LineParent');
        if isequal(lineParent, -1)
            lineParent = [];
        end
        
        newLines = [newLines; lineParent; lineChildren];
    end
    newLines = setdiff(newLines, [currentLines; oldLines]);
    
    % Get all connected lines.
    connectedLines = [currentLines; oldLines]; % Init.
    if ~isempty(newLines)
        connectedLines = get_connected_lines_aux(newLines, connectedLines);
    end % else the given lines are all of the lines
end