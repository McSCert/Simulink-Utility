function b = startsWith2(str, pattern)
% STARTSWITH True if text starts with pattern.

    b = regexp(str, ['^' pattern '.*']);

end
