function sels = gcls
    % GCLS Get all currently selected lines limited to the subsystem
    %   established by GCS.
    %
    %   Inputs:
    %       N/A
    %
    %   Outputs:
    %       sels   Numeric array of line handles.
    %
    %   Example:
    %       >> lines = gcls
    %
    %       lines =
    %           26.0001
    %           28.0004
    
    if isempty(gcs)
        sels = [];
    else
        if verLessThan('simulink', '8.2') % IncludeCommented available in 2013b (8.2) and higher
            objs = find_system(gcs, 'SearchDepth', 1, 'LookUnderMasks', 'all', ...
                'Findall', 'on', 'FollowLinks', 'on', 'Type', 'line', 'Selected', 'on');
        else
            objs = find_system(gcs, 'SearchDepth', 1, 'LookUnderMasks', 'all', ...
                'Findall', 'on', 'FollowLinks', 'on', 'IncludeCommented', 'on', ...
                'Type', 'line', 'Selected', 'on');
        end
        
        % Flip order. find_system returns in descending order.
        sels = flipud(objs);
    end
end