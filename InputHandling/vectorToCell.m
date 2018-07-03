function out = vectorToCell(in)
% VECTORTOCELL Convert input vector to a cell array of of the same
% elements.
%
%   Inputs:
%       in  A vector.
%
%   Outputs:
%       out A cell array corresponding with the input vector.
%
%   Examples:
%       vectorToCell(1)
%       vectorToCell([11, 12, 13, 14])
%       vectorToCell([11; 21; 31])
%       vectorToCell([11,12,13,14; 21, 22, 23, 24; 31, 32, 33, 34])

    if isempty(in)  % empty -> {}
        out = {};
    elseif ~iscell(in) && ~isnumeric(in) % char array -> cell array
        out = {in};
    elseif isnumeric(in) % numeric array -> cell array
        out = cell(size(in));
        for i = 1:size(in, 1)
            for j = 1:size(in, 2)
                out{i,j} = in(i,j);
            end
        end
    end
end