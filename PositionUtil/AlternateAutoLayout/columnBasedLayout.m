function columnBasedLayout(blocks, varargin)
    % COLUMNBASEDLAYOUT Lays out blocks in columns
    %
    % Inputs:
    %   blocks      Cellarray of blocks.
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'Columns'
    %   Value:  Vector of same length as blocks. The number at each point
    %       indicates which column to place the corresponding block in. The
    %       minimum column is 1 and it is the furthest left in the Simulink
    %       diagram. (Default) Use a certain function to find reasonable
    %       columns automatically.
    %   Parameter: 'WidthMode'
    %   Value:  'AsIs' - (Default) After initial adjustment of widths, no
    %               change is made.
    %           'MaxBlock' - After initial adjustment of widths, each block
    %               in each column is made as wide as the widest block in
    %               the input set of blocks.
    %           'MaxColBlock' - After initial adjustment of widths, each
    %               block in each column is made as wide as the widest
    %               block in that column.
    %	Parameter: 'ColumnWidthMode'
    %   Value:  'MaxBlock' - Each column is as wide as the widest block
    %               in the input set of blocks.
    %           'MaxColBlock' - (Default) Each column is as wide as the
    %               widest block in that column.
    %   Parameter: 'ColumnAlignment'
    %   Value:  'left' - (Default) All blocks in a column will share a
    %               left position.
    %           'right' - All blocks in a column will share a right
    %               position.
    %           'center' - All blocks in a column will be centered around
    %               the same point on the horizontal axis.
    %   Parameter: 'HorizSpacing' - Refers to space between columns.
    %   Value:  Any double. Default: 100.
    %   Parameter: 'MethodForDesiredHeight'
    %   Value:  'Compact' - (Default)
    %           'Sum'
    %           'SumMax'
    %           'MinMax' - This option doesn't make much sense to use here.
    %   Parameter: 'VertSpacing' - Refers to space between blocks within a
    %       column (essentially this is used where alignment fails).
    %   Value:  Any double. Default: 30.
    %   Parameter: 'AlignmentType'
    %   Value:  'Source' - (Default) Try to align a blocks with a source.
    %           'Dest' - Try to align a blocks with a destination.
    % Parameter-Value pairs from adjustHeightForConnectedBlocks that may also be passed:
    %   Parameter: 'Buffer'
    %   Value:  Any double. Default: 5.
    %   Parameter: 'HeightPerPort'
    %   Value:  Any double. Default: 30.
    %   Parameter: 'BaseHeight'
    %   Value:  'Basic'
    %           'SingleConnection' - (Default)
    %   Parameter: 'MethodMin'
    %   Value:  'Compact' - (Default)
    %           'None'
    %
    % Outputs:
    %   N/A
    %
    % Examples: (These examples were simply pulled from my history)
    %   columnBasedLayout(gcbs, 'Columns', ones(1,length(gcbs)), 'WidthMode', 'MaxColBlock', 'MethodForDesiredHeight', 'Sum')
    %   columnBasedLayout(gcbs, 'WidthMode', 'MaxColBlock', 'MethodForDesiredHeight', 'Sum')
    %   columnBasedLayout(gcbs, 'WidthMode', 'MaxColBlock', 'MethodForDesiredHeight', 'Compact')
    %   columnBasedLayout(gcbs, 'WidthMode', 'MaxColBlock', 'MethodForDesiredHeight', 'Compact', 'AlignmentType', 'Dest')
    %   columnBasedLayout(gcbs, 'WidthMode', 'MaxColBlock', 'MethodForDesiredHeight', 'Sum', 'AlignmentType', 'Dest')
    %   columnBasedLayout(gcbs, 'MethodForDesiredHeight', 'Sum', 'AlignmentType', 'Dest')
    
    % Handle parameter-value pairs
    Columns = -1*ones(1,length(blocks)); % indicates to find cols automatically
    WidthMode = lower('AsIs');
    ColumnWidthMode = lower('MaxColBlock');
    ColumnAlignment = 'left';
    HorizSpacing = 80;
    MethodForDesiredHeight = lower('Compact');
    HeightPerPort = 30;
    Buffer = 5;
    BaseHeight = lower('SingleConnection');
    MethodMin = lower('Compact');
    VertSpacing = 30;
    AlignmentType = lower('Source');
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('Columns')
                assert(length(value) == length(blocks), ...
                    ['Unexpected value for ' param ' parameter.'])
                Columns = value;
            case lower('WidthMode')
                assert(any(strcmp(value,lower({'AsIs','MaxBlock','MaxColBlock'}))), ...
                    ['Unexpected value for ' param ' parameter.'])
                WidthMode = value;
            case lower('ColumnWidthMode')
                assert(any(strcmp(value,lower({'MaxBlock','MaxColBlock'}))), ...
                    ['Unexpected value for ' param ' parameter.'])
                ColumnWidthMode = value;
            case lower('ColumnAlignment')
                assert(any(strcmp(value,{'left','right','center'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                ColumnAlignment = value;
            case lower('HorizSpacing')
                HorizSpacing = value;
            case lower('MethodForDesiredHeight')
                assert(any(strcmpi(value,{'Compact','Sum','SumMax','MinMax'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                MethodForDesiredHeight = value;
            case lower('HeightPerPort')
                HeightPerPort = value;
            case lower('Buffer')
                Buffer = value;
            case lower('BaseHeight')
                assert(any(strcmpi(value,{'SingleConnection','Basic'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                BaseHeight = value;
            case lower('MethodMin')
                assert(any(strcmpi(value,{'Compact','None'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                MethodMin = value;
            case lower('VertSpacing')
                VertSpacing = value;
            case lower('AlignmentType')
                assert(any(strcmp(value,lower({'Source','Dest'}))), ...
                    ['Unexpected value for ' param ' parameter.'])
                AlignmentType = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    % Convert blocks to cell array of names
    blocks = inputToCell(inputToNumeric(blocks));
    
    % Ensure all blocks are in the same system
    for i = 1:length(blocks)
        assert(strcmp(get_param(blocks{1}, 'Parent'), get_param(blocks{i}, 'Parent')), ...
            'Expecting all blocks to be directly within the same system.')
    end
    
    % Rotate all blocks to a right orientation (for left-to-right dataflow)
    setOrientations(blocks)
    
    % Place names on bottom of blocks
    setNamePlacements(blocks)
    
    % Determine which columns to use automatically
    if ~isempty(Columns) && all(Columns(1) == -1)
        cols = getImpactDepths(blocks);
    else
        cols = Columns;
    end
    % TODO: Add option when determining columns to place in/outports in the
    % first/last column specfically
    assert(length(cols) == length(blocks))
    
    % Sort blocks into a cell array based on designated column.
    % i.e. All column X blocks will be in a cell array in the Xth cell of
    % blx_by_col
    blx_by_col = cell(1,length(blocks));
    for i = 1:length(blocks)
        d = cols(i);
        if isempty(blx_by_col{d})
            blx_by_col{d} = cell(1,length(blocks));
        end
        blx_by_col{d}{i} = blocks{i};
    end
    blx_by_col(cellfun('isempty',blx_by_col)) = [];
    for i = 1:length(blx_by_col)
        blx_by_col{i}(cellfun('isempty',blx_by_col{i})) = [];
    end
    
    % Set blocks to desired widths - actual position horizontally doesn't
    % matter yet
    for i = 1:length(blocks)
        adjustWidth(blocks{i});
    end
    % Adjust widths again to make them more consistent within a column
    % (depending on an input parameter)
    switch WidthMode
        case lower('AsIs')
            blockWidths = -1*ones(1,length(blocks)); % -1 to indicate no change
        case lower('MaxBlock')
            width = getMaxWidth(blocks); % Maximum width among all blocks
            blockWidths = width*ones(1,length(blocks));
        case lower('MaxColBlock')
            blockWidths = -1*ones(1,length(blocks));
            count = 0;
            for i = 1:length(blx_by_col)
                width = getMaxWidth(blx_by_col{i}); % Maximum width in ith column
                for j = 1:length(blx_by_col{i})
                    blockWidths(count+j) = width;
                end
                count = count + length(blx_by_col{i});
            end
        otherwise
            error('Unexpected paramter.')
    end
    count = 0;
    for i = 1:length(blx_by_col)
        for j = 1:length(blx_by_col{i})
            b = blx_by_col{i}{j};
            pos = get_param(b, 'Position');
            if blockWidths(count+j) ~= -1
                set_param(b, 'Position', pos + [0 0 pos(1)-pos(3)+blockWidths(count+j) 0]);
            end
        end
        count = count + length(blx_by_col{i});
    end
    
    % Get column widths in a vector.
    switch ColumnWidthMode
        case lower('MaxBlock')
            width = getMaxWidth(blocks); % Maximum width among all blocks
            colWidths = width*ones(1,length(blx_by_col));
        case lower('MaxColBlock')
            colWidths = zeros(1,length(blx_by_col));
            for i = 1:length(blx_by_col)
                width = getMaxWidth(blx_by_col{i}); % Maximum width in ith column
                colWidths(i) = width;
            end
        otherwise
            error('Unexpected paramter.')
    end
    
    % Place blocks in their respective columns - height doesn't matter yet
    columnLeft = 100; % Left-most point in the current column. Arbitrarily 100 for first column.
    for i = 1:length(blx_by_col)
        % For each column:
        colWidth = colWidths(i); % Get width of current column
        for j = 1:length(blx_by_col{i})
            % Place each block
            
            b = blx_by_col{i}{j}; % Get current block
            
            % TODO use input parameter to get raw width or width including
            % width of text beneath the block
            [bwidth, pos] = getBlockWidth(b);
            
            switch ColumnAlignment
                case 'left'
                    shift = [columnLeft 0 columnLeft+bwidth 0];
                case 'right'
                    shift = [columnLeft+colWidth-bwidth 0 columnLeft+colWidth 0];
                case 'center'
                    shift = [columnLeft+(colWidth-bwidth)/2 0 columnLeft+(colWidth+bwidth)/2 0];
                otherwise
                    error('Unexpected paramter value.')
            end
            set_param(b, 'Position', [0 pos(2) 0 pos(4)] + shift);
            
        end
        
        % Advance column
        columnLeft = columnLeft + colWidth + HorizSpacing;
    end
    
    % Set variables determined by AlignmentType
    switch AlignmentType
        case lower('Source')
            colOrder = 1:length(blx_by_col);
            pType = 'Inport';
            notPType = 'Outport';
        case lower('Dest')
            colOrder = length(blx_by_col):-1:1;
            pType = 'Outport';
            notPType = 'Inport';
        otherwise
            error('Unexpected paramter.')
    end
    
    % Set blocks to desired heights - actual position vertically doesn't
    % matter yet
    setHeights(blx_by_col, colOrder, Buffer, BaseHeight, MethodMin, notPType, 'Compact', HeightPerPort) % First pass to set to base heights
    switch MethodForDesiredHeight
        case 'Compact'
            % Do nothing
        otherwise
            % Second pass to determine new heights based on previous ones
            setHeights(blx_by_col, colOrder, Buffer, BaseHeight, MethodMin, notPType, MethodForDesiredHeight, HeightPerPort)
    end
    
    % Align and spread vertically
    for i = colOrder
        % For each column:
        
        % Align blocks (make diagram cleaner and provides a means of
        % ordering when determining heights)
        [ports, ~] = alignBlocks(blx_by_col{i}, 'PortType', pType);
        
        % Get a desired ordering for which blocks are higher
        % First sort by port heights
        [orderedPorts, ~] = sortPortsByTop(ports);
        orderedParents = get_param(orderedPorts, 'Parent');
        % But not all blocks will have a port, so add the blocks that
        % aren't accounted for
        orderedColumn = [orderedParents; setdiff(blx_by_col{i}, orderedParents)']; % 
        
        % Alternate ordering approach
        %orderedColumn = sortBlocksByTop(blx_by_col{i});
        
        % Spread out blocks that overlap vertically
        for j = 1:length(orderedColumn)
            %
            
            b = orderedColumn{j};
            
            % Detect any remaining blocks in current column overlapping
            % current block
            [~, overlaps] = detectOverlaps(b,orderedColumn(j+1:end), ...
                'OverlapType', 'Vertical', 'VirtualBounds', [0 0 0 VertSpacing]);
            
            % If there is any overlap, move all overlappings blocks below b
            for over = overlaps
                
                % TODO When setting buffer use an input option to determine
                % whether or not to increase the buffer based on parameters
                % of b showing below b
                buffer = VertSpacing;
                moveBelow(b,over{1},buffer);
            end
        end
    end
    
    % Redraw lines
    if ~isempty(blocks)
        sys = get_param(blocks{1}, 'Parent');
        redraw_lines(sys, 'autorouting', 'on');
    end
    
    % TODO Do something with annotations

    % Zoom on system (if it ends up zoomed out that means there is
    % something near the borders)
    if ~isempty(blocks)
        sys = get_param(blocks{1}, 'Parent');
        set_param(sys, 'Zoomfactor', 'Fit to view');
    end
end

function maxWidth = getMaxWidth(blocks)
    % blocks - cell array of blocks
    
    maxWidth = 0;
    for i = 1:length(blocks)
        bwidth = getBlockWidth(blocks{i});
        if bwidth > maxWidth
            maxWidth = bwidth;
        end
    end
end

function [width, pos] = getBlockWidth(block)
    pos = get_param(block, 'Position');
    width = pos(3)-pos(1);
end

function [height, pos] = getBlockHeight(block)
    pos = get_param(block, 'Position');
    height = pos(4)-pos(2);
end

function setHeights(blx_by_col, colOrder, Buffer, BaseHeight, MethodMin, connType, Method, HeightPerPort)
    for i = colOrder(length(colOrder):-1:1) % Reverse column order
        for j = 1:length(blx_by_col{i})
            b = blx_by_col{i}{j}; % Get current block
            
            pos = get_param(b, 'Position');
            
            % TODO Current implementation expands blocks down regardless of
            % input parameters - fix that - though it doesn't really matter
            % since alignment will occur still.
            
            [~, adj_position] = adjustHeight(b, ...
                'Buffer', Buffer, ...
                'ConnectionType', connType, ...
                'Method', Method, ...
                'MethodMin', MethodMin, ...
                'HeightPerPort', HeightPerPort, ...
                'BaseHeight', BaseHeight, ...
                'PerformOperation', 'off');
            
            % TODO use the following parameter in the call above:
            %   'ConnectedBlocks', connBlocks, ...
            % connBlocks should be either the blocks that connect
            % to the current block and are 1 column right or left
            % depending on AlignmentType
            % If going 1 column over would exit bounds or if there
            % are no connBlocks then just get the compactHeight
            
            desiredHeight = adj_position(4) - adj_position(2);
            
            set_param(b, 'Position', [pos(1), pos(2), pos(3), pos(2)+desiredHeight]);
        end
    end
end