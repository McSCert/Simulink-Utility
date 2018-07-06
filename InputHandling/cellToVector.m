function out = cellToVector(in)
% CELLTOVECTOR Convert input cell array to a vector of the same elements.
%
%   Inputs:
%       in  A cell array of elements compatible for a vector.
%
%   Outputs:
%       out A vector corresponding with the input cell array.

    if isempty(in)  % empty -> []
        out = [];
    elseif iscell(in) % cell array -> numeric array
        out = zeros(size(in));
        for i = 1:size(in, 1)
            for j = 1:size(in, 2)
                out(i,j) = in{i,j};
            end
        end
    end
end