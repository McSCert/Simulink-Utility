function t = replaceNewline(text)
% REPLACENEWLINE Replace a new line character with a space.
    t = strrep(text, char(10), ' ');
end