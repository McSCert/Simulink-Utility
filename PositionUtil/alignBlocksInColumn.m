function alignBlocksInColumn(blocks, ColumnAlignment, varargin)
	% ALIGNBLOCKINCOLUMN Align given blocks into a column. Can align to the left, right, or with the same center.
	%
	% Inputs:
	% 	blocks 			Cell array of Simulink block fullnames or handles.
	%	ColumnAlignment	Char array indicating how to align the blocks.
	%						'left' - Blocks will share a leftmost coordinate.
	%						'right' - Blocks will share a rightmost coordinate.
	%						'center' - Blocks will share their center on the x-axis.
	%	varargin{1}		Leftmost position of the column.
	%	varargin{2}		Width of the column.
	%					Both varargin parameters must be given if either is.
	%					The varargin parameters are just used to calculate the point
	%					to anchor each block to depending on ColumnAlignment.
	%					By default, the anchor is determined by the leftmost point 
	%					among the blocks, the rightmost point, or the center of them 
	%					as appropriate.
	%
	% Outputs:
	%	N/A
	%
	% Examples:
	%	% Move blocks to the leftmost position among them.
	%	alignBlocksInColumn(gcbs, 'left')
	%	% Move block left positions to 100
	%	alignBlocksInColumn(gcbs, 'left', 100, 300) % The 300 here isn't used. 
	%	% Move block right positions to 400.
	%	alignBlocksInColumn(gcbs, 'right', 100, 300) % The right is calculated by 100+300.
	%	% Center blocks around 250.
	%	alignBlocksInColumn(gcbs, 'center', 100, 300) % The center is calculated by 100+300/2.
	%
	
	if nargin == 2 && ~isempty(blocks)
		pos1 = get_param(blocks{1}, 'Position');
		columnLeft = pos1(1); % Leftmost position in blocks
		columnRight = pos1(3); % Rightmost position in blocks
		for i = 2:length(blocks)
			b = blocks{i};
			pos = get_param(b, 'Position');
			
			if pos(1) < columnLeft
				columnLeft = pos(1);
			end
			if pos(3) > columnRight
				columnRight = pos(3);
			end
		end
		columnCenter = (leftmost + rightmost) / 2; % Center position of blocks
	elseif nargin == 4
		columnLeft = varargin{1}; % Anchor if aligning left
		colWidth = varargin{2};
		columnRight = leftmost + colWidth; % Anchor if aligning right
		columnCenter = leftmost + colWidth/2; % Anchor if aligning center
	else
		error(['Expected 2 or 4 arguments to ' mfilename])
	end

	for i = 1:length(blocks)
        % Place each block
        
        b = blocks{i}; % Get current block
        
        % TODO use input parameter to get raw width or width including
        % width of text beneath the block
        [bwidth, pos] = getBlockWidth(b);
        
        switch ColumnAlignment
            case 'left'
                shift = [columnLeft 0 columnLeft+bwidth 0];
            case 'right'
                shift = [columnRight-bwidth 0 columnRight 0];
            case 'center'
                shift = [columnCenter-bwidth/2 0 columnCenter+bwidth/2 0];
            otherwise
                error('Unexpected argument value.')
        end
        set_param(b, 'Position', [0 pos(2) 0 pos(4)] + shift);
        
    end
end