function setOrientations(blocks,varargin)
    % SETORIENTATIONS Orient blocks. Default puts outputs on right.
    %
    %   Inputs:
    %       blocks      List (cell array or vector) of blocks (fullnames or
    %                   handles).
    %       varargin    Character array indicating a direction for a block's
    %                   outports to face (if block has no outputs, it's the
    %                   direction they would face). Options correspond with the
    %                   'Orientation' block property e.g. 'right' (default),
    %                   'left', 'up', 'down'.
    %
    %   Example:
    %       setOrientations(gcbs)
    %       setOrientations(gcbs, 'left')
    
    blocks = inputToNumeric(blocks);
    
    if nargin > 1
        direction = varargin{1};
    else
        direction = 'right';
    end % Ignore inputs beyond the second
    
    for i = 1:length(blocks)
        set_param(blocks(i), 'Orientation', direction);
    end
end