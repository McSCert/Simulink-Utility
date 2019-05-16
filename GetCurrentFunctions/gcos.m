function sels = gcos
% GCOS Get all currently selected Simulink objects.
%
%   Inputs:
%       N/A
%
%   Outputs:
%       sels    Numeric array of Simulink object handles (blocks, ports,
%               lines, annotations).
%
%   Example:
%       >> gcos
%       
%       ans =
%           22.0005
%           6.0005
%           2.0005
    
    sels = find_system(gcs, 'LookUnderMasks', 'on', 'Findall', 'on', ...
        'FollowLinks', 'on', 'Selected', 'on');
    % Flip order. find_system returns in descending order.
    sels = flipud(sels);
end