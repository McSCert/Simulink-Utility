function [overlap_exists, overlaps] = detectOverlaps(baseBlock, otherBlocks, varargin)
    % TODO fix header comments
    % DETECTOVERLAPS
    %
    % Inputs:
    %   baseBlock   Simulink block. We're checking if any other block
    %               overlaps this.
    %   otherBlocks Cell array of Simulink blocks.
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'OverlapType'
    %   Value:  {'Vertical'} - Detects any overlap with respect to top and
    %               bottom positions (i.e. blocks could be offset on the
    %               x-axis, but still be deemed overlapping).
    %           {'Horizontal'} - Detects any overlap with respect to left
    %               and right positions (i.e. blocks could be offset on the
    %               y-axis, but still be deemed overlapping).
    %           {'Any'} - Detects blocks with either a vertical or
    %               horizontal overlap.
    %           {'All'} - (Default) Detects blocks sharing space.
    %
    % Outputs:
    %   overlap_exists  True if any overlaps were detected.
    %   overlaps        Cell array of Simulink blocks in otherBlocks that
    %                   overlap baseBlock.
    %
    
    % Handle parameter-value pairs
    OverlapType = lower('All');
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('OverlapType')
                assert(any(strcmp(value,lower({'Vertical','Horizontal','Any','All'}))), ...
                    ['Unexpected value for ' param ' parameter.'])
                OverlapType = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    overlap_exists = false; % Guess no overlaps
    overlaps = cell(1,length(otherBlocks));
    for i = 1:length(otherBlocks)
        switch OverlapType
            case lower('Vertical')
                % Detect vertical overlaps
                overlapFound = isOverlap(baseBlock,otherBlocks{i},[2,4]); % Check for vertical overlap
            case lower('Horizontal')
                % Detect horizontal overlaps
                overlapFound = isOverlap(baseBlock,otherBlocks{i},[1,3]); % Check for vertical overlap
            case lower('Any')
                % Detect vertical or horizontal overlaps
                overlapFound = isOverlap(baseBlock,otherBlocks{i},[2,4]) ...
                    || isOverlap(baseBlock,otherBlocks{i},[1,3]);
            case lower('All')
                % Detect vertical and horizontal overlaps (i.e. both
                % occurring at once)
                overlapFound = isOverlap(baseBlock,otherBlocks{i},[2,4]) ...
                    && isOverlap(baseBlock,otherBlocks{i},[1,3]);
            otherwise
                error('Unexpected paramter.')
        end
        if overlapFound
            overlap_exists = true;
            overlaps{i} = otherBlocks{i};
        end
    end
    overlaps(cellfun('isempty',overlaps)) = []; % Empty elements are non-matches and should be removed
end

function bool = isOverlap(block1, block2, dims)
    %
    % dims = [2,4] checks for vertical overlap
    % dims = [1,3] checks for horizontal overlap
    pos1 = get_param(block1, 'Position');
    pos2 = get_param(block2, 'Position');
    
    bool = isRangeOverlap(pos1(dims),pos2(dims));
end

function bool = isRangeOverlap(range1,range2)
    assert(range1(1)<=range1(2))
    assert(range2(1)<=range2(2))
    
    bool = range1(1)<=range2(2) && range2(1)<=range1(2);
end