function sels = gcos
    % GCOS Get all currently selected Simulink objects.
    %
    % Inputs:
    %   N/A
    %
    % Outputs:
    %   sels    Numeric array of Simulink object handles (blocks, ports,
    %           lines, annotations).
    %
    % Example:
    %   objs = gcos
    %

    % FUTURE WORK:
    % Accept varargin to indicate which object type(s) to return.
    
    sels = find_system(gcs, 'LookUnderMasks', 'on', 'Findall', 'on', ...
        'FollowLinks', 'on', 'Selected', 'on');
    % Flip order. find_system returns in descending order.
    sels = flipud(sels);
end