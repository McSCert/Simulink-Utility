function h = add_line2(varargin)
% ADD_LINE2 Add a line to a Simulink system.

    autorouting = getInput('autorouting', varargin, 'off');
    
    % Smart autorouting was introduced in 2017b. If this version does not
    % support it, downgrade to regular autorouting.
    if strcmp(autorouting, 'smart') && verLessThan('simulink', '9.0')
        h = add_line(varargin{1}, varargin{2}, varargin{3}, 'autorouting', 'on');
    else
        h = add_line(varargin{:});
    end
end