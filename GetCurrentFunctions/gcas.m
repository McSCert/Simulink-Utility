function sels = gcas
% GCAS Get all currently selected annotations.
%
%   Inputs:
%       N/A
%
%   Outputs:
%       sels   Numeric array of annotation handles.
%
%   Example:
%       annotations = gcas

    sels = find_system(gcs, 'LookUnderMasks', 'on', 'Findall', 'on', ...
        'FollowLinks', 'on', 'Type', 'annotation', 'Selected', 'on');
    % Flip order. find_system returns in descending order.
    sels = flipud(sels);
end