function b = iscellcell(c)
% ISCELLCELL Whether the input is a cell array containing at least another cell.
%
%   Inputs:
%       c   Cell array.
%
%   Outputs:
%       b   Whether the it is a cell array of cells(1) or not(0).
%
%   Example:
%       iscellcell({'a'})
%           ans = 0
%
%       iscellcell({{'a'}, {'b'}})
%           ans = 1

    b = false;
    if iscell(c)
        for i = 1:length(c)
            if iscell(c{i})
                b = true;
            end
        end
    end
end