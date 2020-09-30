function joinedStr = strjoin(str, delimiter)
%STRJOIN  Append elements of a string array
%   S = STRJOIN(C) constructs S by linking the elements of C with a space
%   between each element. C can be a string array or cell array of
%   character vectors. S is a string scalar when C is a string array.  S is
%   a character vector when C is a cell array of character vectors.
%
%   S = STRJOIN(C, DELIMITER) constructs S by linking each element of C
%   with the elements of DELIMITER. DELIMITER can be either a string or a
%   cell array of character vectors having one fewer element than C.
%
%   If DELIMITER is a character vector it will interpret these escape
%   sequences:
%       \\   Backslash             \n   New line
%       \0   Null                  \r   Carriage return
%       \a   Alarm                 \t   Horizontal tab
%       \b   Backspace             \v   Vertical tab
%       \f   Form feed
%
%   If DELIMITER is a string array or cell array of character vectors, then
%   all characters in DELIMITER are inserted as literal text, and escape
%   characters are not interpreted.
%
%   Examples:
%
%       c = {'one', 'two', 'three'};
%
%       % Join with space.
%       strjoin(c)
%       % 'one two three'
%
%       % Join as a comma separated list.
%       strjoin(c, ', ')
%       % 'one, two, three'
%
%       % Join with a cell array of character vectors DELIMITER.
%       strjoin(c, {' + ', ' = '})
%       % 'one + two = three'
%
%   See also JOIN, SPLIT, STRCAT, STRSPLIT

%   Copyright 2012-2016 The MathWorks, Inc.

    if nargin < 1 || nargin > 2
        narginchk(1, 2);
    end
    
    v = ver('Simulink');
    v = str2double(v.Version);
    if v > 8.8 
        stringsInThisVersion = true;
        strIsString  = isstring(str);
    else
        stringsInThisVersion = false;
        strIsString = false;
    end
    strIsCellstr = iscellstr(str);
    
    % Check input arguments.
    if ~strIsCellstr && ~strIsString
        error(message('MATLAB:strjoin:InvalidCellType'));
    end

    numStrs = numel(str);

    if nargin < 2
        delimiter = {' '};
    elseif ischar(delimiter)
        delimiter = {strescape(delimiter)};
    elseif iscellstr(delimiter) || (stringsInThisVersion && isstring(delimiter))
        numDelims = numel(delimiter);
        if numDelims ~= 1 && numDelims ~= numStrs-1 
            error(message('MATLAB:strjoin:WrongNumberOfDelimiterElements'));
        elseif v > 8.8 && strIsCellstr && isstring(delimiter)
            delimiter = cellstr(delimiter);
        end
        delimiter = reshape(delimiter, numDelims, 1);
    else
        error(message('MATLAB:strjoin:InvalidDelimiterType'));
    end

    str = reshape(str, numStrs, 1);
    
    if strIsString
        if isempty(str)
            joinedStr = string('');
        else
            joinedStr = join(str, delimiter);
        end
    elseif numStrs == 0
        joinedStr = '';
    else
        joinedCell = cell(2, numStrs);
        joinedCell(1, :) = str;
        joinedCell(2, 1:numStrs-1) = delimiter;

        joinedStr = [joinedCell{:}];
    end
end
