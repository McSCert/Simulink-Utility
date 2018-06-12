function columnBasedLayout(blocks, cols, varargin)
    % COLUMNBASEDLAYOUT Lays out blocks in columns
    %
    % Inputs:
    %   blocks      Cellarray of blocks.
    %   cols        Vector of same length as blocks. The number at each
    %               point indicates which column to place the corresponding
    %               block in. The minimum column is 1 and it is the
    %               furthest left in the Simulink diagram.
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %	Parameter: 'ColumnWidthMode'
    %   Value:  'MaxBlock' - Each column is as wide as the widest block
    %               in the input set of blocks.
    %           'MaxColBlock' - (Default) Each column is as wide as the
    %               widest block in that column.
    %   Parameter: 'ColumnJustification'
    %   Value:  'left' - (Default) All blocks in a column will share a
    %               left position.
    %           'right' - All blocks in a column will share a right
    %               position.
    %           'center' - All blocks in a column will be centered around
    %               the same point on the horizontal axis.
    %   Parameter: 'HorizSpacing' - Refers to space between columns.
    %   Value:  Any double. Default: 100.
    %   Parameter: 'MethodForDesiredHeight'
    %   Value:  'Compact' - (Default) Uses HeightPerPort and
    %               BaseBlockHeight parameters only.
    %           Other options correspond with options for the Method
    %           parameter in adjustHeightForConnectedBlocks.m: Currently the
    %           supported options from there are:
    %           'Sum'
    %           'SumMax'
    %           'MinMax'- This option doesn't make much sense to use here.
    %   Parameter: 'HeightPerPort'
    %   Value:  Any double. Default: 10.
    %   Parameter: 'BaseBlockHeight'
    %   Value:  Any double. Default: 10.
    %   Parameter: 'VertSpacing' - Refers to space between blocks within a
    %       column (essentially this is used where alignment fails).
    %   Value:  Any double. Default: 30.
    %   Parameter: 'AlignmentType'
    %   Value:  'Source' - (Default) Try to align a blocks with a source.
    %           'Dest' - Try to align a blocks with a destination.
    %
    % Outputs:
    %   N/A
    %
    
    % Handle parameter-value pairs
    ColumnWidthMode = lower('MaxColBlock');
    ColumnJustification = 'left';
    HorizSpacing = 80;
    MethodForDesiredHeight = lower('Compact');
    HeightPerPort = 10;
    BaseBlockHeight = 10;
    VertSpacing = 30;
    AlignmentType = lower('Source');
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('ColumnWidthMode')
                assert(any(strcmp(value,lower({'MaxBlock','MaxColBlock'}))), ...
                    ['Unexpected value for ' param ' parameter.'])
                ColumnWidthMode = value;
            case lower('ColumnJustification')
                assert(any(strcmp(value,{'left','right','center'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                ColumnJustification = value;
            case lower('HorizSpacing')
                HorizSpacing = value;
            case lower('MethodForDesiredHeight')
                assert(any(strcmpi(value,{'Compact','Sum','SumMax','MinMax'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                MethodForDesiredHeight = value;
            case lower('HeightPerPort')
                HeightPerPort = value;
            case lower('BaseBlockHeight')
                BaseBlockHeight = value;
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
    
    % Ensure all blocks are in the same system
    for i = 1:length(blocks)
        assert(strcmp(get_param(blocks{1}, 'Parent'), get_param(blocks{i}, 'Parent')), ...
            'Expecting all blocks to be directly within the same system.')
    end
    
    % Rotate all blocks to a right orientation (for left-to-right dataflow)
    setOrientations(blocks)
    
    % Place names on bottom of blocks
    setNamePlacements(blocks)
    
    % TODO Add option to determine columns in a smart way
    % Add option when determining columns to place in/outports in the
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
    
    % Get column widths in a vector.
    switch ColumnWidthMode
        case 'maxblock'
            width = getMaxWidth(blocks); % Maximum width among all blocks
            colWidths = width*ones(1,length(blx_by_col));
        case 'maxcolblock'
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
            
            switch ColumnJustification
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
    for i = colOrder
        for j = 1:length(blx_by_col{i})
            b = blx_by_col{i}{j}; % Get current block
            
            pos = get_param(b, 'Position');
            
            % TODO Move compactHeight into adjustHeight
            % TODO Current implementation expands blocks down regardless of
            % input parameters - fix that.
            switch MethodForDesiredHeight
                case lower('Compact')
                    desiredHeight = compactHeight(b, BaseBlockHeight, HeightPerPort);
                otherwise
                    [success, position] = adjustHeight(b, ...
                        'Buffer', BaseBlockHeight, ...
                        'ConnectionType', notPType, ...
                        'Method', MethodForDesiredHeight, ...
                        'HeightPerPort', HeightPerPort, ...
                        'PerformOperation', 'off');
                    
                    % TODO use the following parameter in the call above:
                    %   'ConnectedBlocks', connBlocks, ...
                    % connBlocks should be either the blocks that connect
                    % to the current block and are 1 column right or left
                    % depending on AlignmentType
                    % If going 1 column over would exit bounds or if there
                    % are no connBlocks then just get the compactHeight
                    
                    if ~success
                        desiredHeight = compactHeight(b, BaseBlockHeight, HeightPerPort);
                    else
                        desiredHeight = position(4) - position(2);
                    end
            end
            
            set_param(b, 'Position', [pos(1), pos(2), pos(3), pos(2)+desiredHeight]);
        end
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
            [~, overlaps] = detectOverlaps(b,orderedColumn(j+1:end),'OverlapType','Vertical');
            
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

function desiredHeight = compactHeight(block, BaseBlockHeight, HeightPerPort)
    numInports = length(getPorts(block, 'Inport'));
    numOutports = length(getPorts(block, 'Outport'));
    
    desiredHeight = BaseBlockHeight + HeightPerPort * max([0, numInports, numOutports]);
end