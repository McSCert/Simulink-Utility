function b = contains2(str, pattern)
% CONTAINS True if pattern is found in text.
%   TF = CONTAINS(STR,PATTERN) returns 1 (true) if STR contains PATTERN,
%   and returns 0 (false) otherwise.
%
%   STR can be a character array or a cell array of characters.

    b = strfind(str, pattern);
    if iscell(str)
        for i = 1:length(b)
            if isempty(b{i})
                b{i} = 0;
            end
        end
        b = logical(cell2mat(b));
    elseif ischar(str)
        b = find(b);
        if b > 0
            b = true;
        else
            b = false;
        end
    end
end