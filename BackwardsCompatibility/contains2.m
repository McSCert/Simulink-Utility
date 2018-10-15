function b = contains2(str, pattern)
% CONTAINS True if pattern is found in text.
%   TF = CONTAINS(STR,PATTERN) returns 1 (true) if STR contains PATTERN,
%   and returns 0 (false) otherwise.

    b = cell2mat(strfind(str, pattern));
    if isempty(b)
        b = false;
    end
end