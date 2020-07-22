function path = commonParents(varargin)
% COMMONPARENTS Find the first (top-most) common parent between two or more blocks
%	in the same model. This is done by comparing each element in the path, 
%   starting at the root, and stopping when they are no longer the same.
%
%   Inputs:
%       varargin    Block path names or handles.
%
%   Outputs:
%       path        Path to common parent.

    % If one block is provided, return its parent
    if nargin == 1
        path = char(get_param(varargin{1}, 'Parent'));
        return
    end
    
    % If handle inputs, change to paths for subsequent string operations
    varargin = inputToCell(varargin);
    
    % Split up paths
    paths = cell(size(varargin));
    for i = 1:nargin
        paths{i} = strsplit(varargin{i}, '/');
    end
    
    % Assume blocks are in the same model
    pathInCommon = paths{1}{1}; 
    
    for j = 2:min(cell2mat(cellfun(@length, paths, 'UniformOutput', false))) 
        % Compare against first element (it doesn't matter which)
        pathElement = paths{1}{j};
        
        % Check if the path elements are identical across all inputs
        identical = cell2mat(strfind(cellfun(@(v) v(j), paths), pathElement));
        if sum(identical) == nargin
            pathInCommon = [pathInCommon '/' pathElement];
        else
            break;
        end
    end
    
    path = pathInCommon;
end