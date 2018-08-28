function setNamePlacements(blocks, varargin)
    % SETNAMEPLACEMENTS Set the placement of names for Simulink blocks.
    %   Default will place names along the bottom of the block.
    %
    %   Inputs:
    %       blocks      List (cell array or vector) of Simulink blocks
    %                   (fullnames or handles).
    %       varargin{1} Character array indicating where to place a block's name
    %                   with respect to the block. Options correspond with the
    %                   'NamePlacement' block property, i.e., 'normal' (default)
    %                   and 'alternate'.
    %
    %   Outputs:
    %       N/A
    %
    %   Example:
    %       setNamePlacements(gcbs, 'normal')
    %       setNamePlacements(gcbs, 'alternate')
    
    blocks = inputToNumeric(blocks);
    
    if nargin > 1
        namePlacement = varargin{1};
    else
        namePlacement = 'normal';
    end
    
    for i = 1:length(blocks)
        set_param(blocks(i), 'NamePlacement', namePlacement);
    end
end