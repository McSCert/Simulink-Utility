function value = getInput(name, args, default)
% GETINPUT Get a specific input from a list of arguments from varargin.
%
%   Inputs:
%       name    Char array of the input name.
%       args    Cell array of all arguments pass in via varargin.
%       default (Optional) Value to return if input not in list of arguments.
%               Returns [] if not given and not in arguments list.
%
%   Outputs:
%       value   Value of the input specified by the input name.
%
%   Example:
%       >> getInput('BlockType', {'Name', 'Example', 'BlockType', 'SubSystem'})
%           ans =
%               'SubSystem'
%
%       >> getInput('otherFiles', {'imageFile', 'test.png', 'otherFiles', {'file1', 'file2'}})
%           ans =
%               1x2 cell array
%                   {'file1'}    {'file2'}

    if nargin == 2
        default = [];
    else
        assert(nargin == 3, 'Error: Expecting 2 or 3 inputs.')
    end

    if iscellcell(args)
        idx = find(strcmp(args, name));
        exists = ~isempty(idx);
    else
        args2 = cellfun(@num2str, args, 'un', 0);
        [exists, idx] = ismember(name, args2);
    end

    if exists && length(args) > idx
        value = args{idx+1};
    else
        value = default;
    end
end

function b = iscellcell(c)
% ISCELLCELL Whether the input is a cell array of cells.
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