function lines = remove_child_lines(lines, varargin)
    % REMOVE_CHILD_LINES Removes lines when their parent line is in the list.
    % (Also removes if the parent's parent is in the list and so on).
    %
    % Inputs:
    %   lines       Vector of Simulink lines.
    %   varargin{1} Mode: 'IfParentExists' or 'All'
    %               (Default) 'IfParentExists' - remove line if any parent is
    %                   found recursively (same functionality described above).
    %               'All' - remove any lines that have a parent.
    %
    % Outputs:
    %   lines   Vector of Simulink lines. Same as input, but with appropriate
    %           lines removed.
    
    if ~isempty(varargin)
        mode = lower(varargin{1});
    else
        mode = 'all';
    end
    
    switch mode
        case 'ifparentexists'
            for i = length(lines):-1:1
                if ancestor_in_list(lines(i), lines)
                    % An ancestor of the line is already in the list.
                    lines(i) = []; % Remove line
                end
            end
        case 'all'
            for i = length(lines):-1:1
                if get_param(lines(i), 'LineParent') ~= -1
                    % There is a parent
                    lines(i) = []; % Remove line
                end
            end
        otherwise
            error('Unexpected value for optional argument. Expecting ''IfParentExists'' or ''All''.')
    end
end

function bool = ancestor_in_list(line, lineArray)
    % Recursively looks for a parent of line in the lineArray.
    % line - a line
    % lineArray - a vector of lines
    parentLn = get_param(line, 'LineParent');
    if parentLn ~= -1
        % There is a parent.
        if isempty(find(parentLn == lineArray, 1))
            % Parent not in list.
            % Check if another ancestor is in list.
            bool = ancestor_in_list(parentLn, lineArray);
        else
            % Parent in list.
            bool = true;
        end
    else
        % There is no parent to begin with.
        bool = false;
    end
end