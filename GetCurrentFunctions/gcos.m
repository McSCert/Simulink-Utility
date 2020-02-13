function sels = gcos
% GCOS Get all currently selected Simulink objects limited to the subsystem
%   established by GCS.
%
%   Inputs:
%       N/A
%
%   Outputs:
%       sels    Numeric array of Simulink object handles (blocks, ports,
%               lines, annotations).
%
%   Example:
%       >> objects = gcos
%       
%       objects =
%           22.0005
%           6.0005
%           2.0005
    
    if isempty(gcs)
        sels = [];
    else
        selsTmp = find_system(gcs, 'SearchDepth', 1, 'LookUnderMasks', 'all', ...
            'Findall', 'on', 'FollowLinks', 'on', 'Selected', 'on');
        removeIdxs = strcmp(getfullname(selsTmp), gcs); % Find index of gcs in selection.
        sels = selsTmp(~removeIdxs); % Remove gcs from selection.
        
        % Flip order. find_system returns in descending order.
        sels = flipud(sels);
    end
end