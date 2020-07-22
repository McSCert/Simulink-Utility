function b = inRoot(block)
% INROOT Determine if the block is in the root system of a model.
%
%   Inputs:
%       block   Block path name or handle.
%
%   Outputs:
%       b       Whether it is in the root(1) or not(0).

    if strcmp(bdroot(block), get_param(block, 'Parent'))
        b = true;
    else
        b = false;
    end    
end