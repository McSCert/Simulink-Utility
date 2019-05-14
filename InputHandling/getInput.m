function value = getInput(name, args, default)
% GETINPUT Get a specific input from a list of arguments from varargin.
%
%   Inputs:
%       name    Char array of the input name.
%       args    Cell array of all arguments pass in via varargin.
%       default Value to return if input not in list of arguments. (Optional) 
%               Default is [].
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
%
%   Requires: iscellcell.m

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