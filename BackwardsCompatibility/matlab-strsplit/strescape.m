function str = strescape(str)
%STRESCAPE  Escape control character sequences in a string.
%   STRESCAPE(STR) converts the escape sequences in a string to the values
%   they represent.
%
%   Example:
%
%       strescape('Hello World\n')
%
%   See also SPRINTF.

%   Copyright 2012-2015 The MathWorks, Inc.

if iscell(str)
    str = cellfun(@(c)strescape(c), str, 'UniformOutput', false);
else
    idx = 1;
    % Note that only [1:end-1] of the string is checked,
    % since unescaped trailing backslashes are ignored.
    while idx < length(str)
        if str(idx) == '\'
            str(idx) = [];  % Remove the '\' escape character itself.
            str(idx) = escapeChar(str(idx));
        end
        idx = idx + 1;
    end
end

end
%--------------------------------------------------------------------------
function c = escapeChar(c)
    switch c
    case '0'  % Null.
        c = char(0);
    case 'a'  % Alarm.
        c = char(7);
    case 'b'  % Backspace.
        c = char(8);
    case 'f'  % Form feed.
        c = char(12);
    case 'n'  % New line.
        c = char(10);
    case 'r'  % Carriage return.
        c = char(13);
    case 't'  % Horizontal tab.
        c = char(9);
    case 'v'  % Vertical tab.
        c = char(11);
    case '\'  % Backslash.
        c = '\';
    otherwise
        warning(message('MATLAB:strescape:InvalidEscapeSequence', c, c));
    end
end
