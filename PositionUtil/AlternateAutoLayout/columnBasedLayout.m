function columnBasedLayout(blocks, cols, varargin)
    % TODO fix header comments.
    % COLUMNBASEDLAYOUT
    %
    % Inputs:
    %   blocks
    %   cols
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %	Parameter: 'ColumnWidthMode'
    %   Value:  {'MaxBlock'} - Each column is as wide as the widest block
    %               in the input set of blocks.
    %           {'MaxColBlock'} - (Default) Each column is as wide as the
    %               widest block in that column.
    %   Parameter: 'ColumnJustification'
    %   Value:  {'left'} - (Default) All blocks in a column will share a
    %               left position.
    %           {'right'} - All blocks in a column will share a right
    %               position.
    %           {'center'} - All blocks in a column will be centered around
    %               the same point on the horizontal axis.
    %   Parameter: 'HorizSpacing' - Refers to space between columns.
    %   Value:  Any double. Default: 100.
    %   Parameter: 'HeightPerPort'
    %   Value:  Any double. Default: 10.
    %   Parameter: 'BaseBlockHeight'
    %   Value:  Any double. Default: 10.
    %   Parameter: 'VertSpacing' - Refers to space between blocks within a
    %       column.
    %   Value:  Any double. Default: 30.
    %   Parameter: 'AlignmentType'
    %   Value:  {'Source'} - (Default) Try to align a blocks with a source.
    %           {'Dest'} - Try to align a blocks with a destination.
    %
    % Outputs:
    %   N/A
    %
    
    % Handle parameter-value pairs
    ColumnWidthMode = lower('MaxColBlock');
    ColumnJustification = 'left';
    HorizSpacing = 80;
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
    
    % Rotate all blocks to a right orientation
    setOrientations(blocks)
    
    % TODO Add option to determine columns in a smart way
    
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
    
    % TODO Set blocks to desired widths - actual position horizontally doesn't
    % matter yet
    
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
            [bwidth, pos] = getBlockWidth(b);
            switch ColumnJustification
                case 'left'
                    shift = [columnLeft 0 columnLeft+bwidth 0];
                case 'right'
                    shift = [columnLeft+colWidth-bwidth 0 columnLeft+colWidth 0];
                case 'center'
                    shift = [columnLeft+(colWidth-bwidth)/2 0 columnLeft+(colWidth+bwidth)/2 0];
                otherwise
                    error('Unexpected paramter.')
            end
            set_param(b, 'Position', [0 pos(2) 0 pos(4)] + shift);
            
        end
        
        % Advance column
        columnLeft = columnLeft + colWidth + HorizSpacing;
    end
    
    % Set blocks to desired heights - actual position vertically doesn't
    % matter yet
    for i = 1:length(blocks)
        b = blocks{i}; % Get current block
        pos = get_param(b, 'Position');
        
        numInports = length(getPorts(b, 'Inport'));
        numOutports = length(getPorts(b, 'Outport'));
        
        desiredHeight = BaseBlockHeight + HeightPerPort * max([0, numInports, numOutports]);
        
        set_param(b, 'Position', [pos(1), pos(2), pos(3), pos(2)+desiredHeight]);
    end
    
    % Align and spread vertically
    % TODO figure out how to preserve the alignment without causing overlap
    % (this would involve resizing blocks so the ports are far enough apart
    % as well as figuring out when not to bother e.g. if many in and
    % outports and alignment is infeasible)
    
    switch AlignmentType
        case lower('Source')
            colOrder = 1:length(blx_by_col);
            pType = 'Inport';
        case lower('Dest')
            colOrder = length(blx_by_col):-1:1;
            pType = 'Outport';
        otherwise
            error('Unexpected paramter.')
    end
    
    for i = colOrder
        % For each column:
        
        % Align blocks (make diagram cleaner and provides a means of
        % ordering when determining heights)
        alignBlocks(blx_by_col{i}, 'PortType', pType);
        
        % Spread out blocks that overlap vertically
        orderedColumn = sortBlocksByTop(blx_by_col{i});
        for j = 1:length(orderedColumn)
            %
            
            b = orderedColumn{j};
            
            % Detect any remaining blocks in current column overlapping
            % current block
            [~, overlaps] = detectOverlaps(b,orderedColumn(j+1:end),'OverlapType','Vertical');
            
            % If there is any overlap, move all overlappings blocks below b
            for over = overlaps
                
                % TODO When setting buffer, depending on an input option,
                % increase the buffer based on parameters of b showing
                % below b
                buffer = VertSpacing;
                moveBelow(b,over{1},buffer);
            end
        end
    end
    
    % Redraw lines
    redraw_lines(gcs, 'autorouting', 'on');
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