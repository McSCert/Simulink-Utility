function sels = gcls
% GCLS Get all currently selected lines.
%
%   Inputs:
%       N/A
%
%   Outputs:
%       sels   Numeric array of line handles.
%
%   Example:
%       lines = gcls

    sels = find_system(gcs, 'LookUnderMasks', 'on', 'Findall', 'on', ...
        'FollowLinks', 'on', 'Type', 'line', 'Selected', 'on');
    % Flip order. find_system returns in descending order.
    sels = flipud(sels);
end