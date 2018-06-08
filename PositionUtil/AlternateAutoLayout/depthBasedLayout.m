function depthBasedLayout(blocks, depths, varargin)
    % TODO fix header comments.
    % DEPTHBASEDLAYOUT
    %
    % Inputs:
    %   blocks
    %   depths
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'ColumnJustification'
    %   Value:  {'left'} - (Default) All blocks in a column will share a
    %               left position.
    %           {'right'} - All blocks in a column will share a right
    %               position.
    %           {'center'} - All blocks in a column will be centered around
    %               the same point on the horizontal axis.
    %	Parameter: 'ColumnWidthMode'
    %   Value:  {'MaxBlock'} - Each column is as wide as the widest block
    %               in the input set of blocks.
    %           {'MaxColBlock'} - (Default) Each column is as wide as the
    %               widest block in that column.
    %   Parameter: 'HorizSpacing' - Refers to space between columns.
    %   Value:  Any double. Default: 100.
    %   Parameter: 'HeightPerPort'
    %   Value:  Any double. Default: 10.
    %   Parameter: 'BaseBlockHeight'
    %   Value:  Any double. Default: 10.
    %   Parameter: 'VertSpacing' - Refers to space between blocks within a
    %       column.
    %   Value:  Any double. Default: 30.
    %
    % Outputs:
    %   N/A
    %
    
    % Handle parameter-value pairs
    ColumnJustification = 'left';
    ColumnWidthMode = 'maxcolblock';
    HorizSpacing = 80;
    HeightPerPort = 10;
    BaseBlockHeight = 10;
    VertSpacing = 30;
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('ColumnJustification')
                assert(any(strcmp(value,{'left','right','center'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                ColumnJustification = value;
            case lower('ColumnWidthMode')
                assert(any(strcmp(value,lower({'MaxBlock','MaxColBlock'}))), ...
                    ['Unexpected value for ' param ' parameter.'])
                ColumnWidthMode = value;
            case lower('HorizSpacing')
                HorizSpacing = value;
            case lower('HeightPerPort')
                HeightPerPort = value;
            case lower('BaseBlockHeight')
                BaseBlockHeight = value;
            case lower('VertSpacing')
                VertSpacing = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    % Rotate all blocks to a right orientation
    setOrientations(blocks)
    
    % TODO Get depths from blocks rather than an input
    % Note: depths(i) must correspond with blocks{i}
    assert(length(depths) == length(blocks))
    
    % Sort blocks into a cell array based on depth.
    % i.e. All depth X blocks are in a cell array in the first
    blx_by_depth = cell(1,length(blocks));
    for i = 1:length(blocks)
        d = depths(i);
        if isempty(blx_by_depth{d})
            blx_by_depth{d} = cell(1,length(blocks));
        end
        blx_by_depth{d}{i} = blocks{i};
    end
    blx_by_depth(cellfun('isempty',blx_by_depth)) = [];
    for i = 1:length(blx_by_depth)
        blx_by_depth{i}(cellfun('isempty',blx_by_depth{i})) = [];
    end
    
    % TODO Set blocks to desired widths - actual position horizontally doesn't
    % matter yet
    
    % Get column widths in a vector.
    switch ColumnWidthMode
        case 'maxblock'
            width = getMaxWidth(blocks); % Maximum width among all blocks
            colWidths = width*ones(1,length(blx_by_depth));
        case 'maxcolblock'
            colWidths = zeros(1,length(blx_by_depth));
            for i = 1:length(blx_by_depth)
                width = getMaxWidth(blx_by_depth{i}); % Maximum width in ith column
                colWidths(i) = width;
            end
        otherwise
            error('Unexpected paramter.')
    end
    
    % Place blocks in their respective columns - height doesn't matter yet
    columnLeft = 100; % Left-most point in the current column. Arbitrarily 100 for first column.
    for i = 1:length(blx_by_depth)
        % For each column:
        colWidth = colWidths(i); % Get width of current column
        for j = 1:length(blx_by_depth{i})
            % Place each block
            
            b = blx_by_depth{i}{j}; % Get current block
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
    for i = length(blx_by_depth):-1:1
        % For each column:
        
        % Align blocks (make diagram cleaner and provides a means of
        % ordering when determining heights)
        alignOut(blx_by_depth{i}); % Align based on outports -- arbitrarily chosen over inports, however this dictates the order in which we're handling the columns (from right-to-left)
        
        % Spread out blocks that overlap vertically
        orderedColumn = sortBlocksByTop(blx_by_depth{i});
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