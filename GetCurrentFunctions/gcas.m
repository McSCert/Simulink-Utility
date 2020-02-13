function sels = gcas
% GCAS Get all currently selected annotations limited to the subsystem
%   established by GCS.
%
%   Inputs:
%       N/A
%
%   Outputs:
%       sels   Numeric array of annotation handles.
%
%   Example:
%       >> gcas
%
%       ans =
%           41.0005

    if isempty(gcs)
        sels = [];
    else
        sels = find_system(gcs, 'SearchDepth', 1, 'LookUnderMasks', 'all', ...
            'Findall', 'on', 'FollowLinks', 'on', 'Type', 'annotation', ...
            'Selected', 'on');
        % Flip order. find_system returns in descending order.
        sels = flipud(sels);
    end
end