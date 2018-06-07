function out = inputToCell(in)
% INPUTTOCELL Convert input to a cell array of paths.
%   Many of the built-in Simulink functions will take as input an array 
%   of handles (which are numeric), cell array of path names (character arrays), 
%   or a character array. This function takes any of the aforementioned types
%   and outputs a cell array of path names. This gives the user many options
%   when providing input.
%
%   Inputs:
%       in  Path names or handles.
%
%   Outputs:
%       out Cell array of path names.
%
%   Examples:
%       inputToCell(gcbh)

    out = in;
    if isempty(in)  % empty -> {}
        out = {};
    elseif ~iscell(in) && ~isnumeric(in) % char array -> cell array
        out = {in};
    elseif isnumeric(in) % numeric array of handles -> cell array of path names
        paths = cell(1, length(in));
        for i = 1:length(in)
            paths{i} = getfullname(in(i));  
        end
        out = paths;
    elseif iscell(in) % cell of numeric handles or char array paths -> cell of path names
        cellfun(@getfullname, in, 'un', 0);
    end
end