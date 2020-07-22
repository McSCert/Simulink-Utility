function visibility = getFcnScope(blocks)
% GETFCNSCOPE Get a Simulink Function's scope, considering its Visibility Parameter
%   and placement in the model. This parameter does not exist prior to
%   2017b. 
%
%   Inputs:
%       blocks      Block path names or handles.
%
%   Outputs:
%       visibility  Scope.Global(0), Scope.Scoped(1), or Scope.Local(2).

    % Handle input
    blocks = inputToCell(blocks); % Convert to cell array of path names
    if isempty(blocks)
        visibility = {};
        return
    end
    
    visibility = cell(1, length(blocks));
    for i = 1:length(blocks)
        % 1) Get Function Visibility parameter
        triggerPort = find_system(blocks{i}, 'SearchDepth', 1, 'FollowLinks', 'on', ...
            'BlockType', 'TriggerPort', ...
            'TriggerType', 'function-call');
        try
            visibilityOfPort = get_param(triggerPort{1}, 'FunctionVisibility');
        catch
            % Either not a Simulink Function, or earlier versions of
            % Simulink Functions (previous to 2017b) do not have this parameter
            visibility{i} = '';
            continue
        end
        
        % 2) Get Placement
        atRoot = strcmp(bdroot(blocks{i}), get_param(blocks{i}, 'Parent'));
        
        % Determine visibility based on 1) and 2)
        if strcmpi(visibilityOfPort, 'global')
            visibility{i} = char(Scope.Global);
        elseif (atRoot && strcmpi(visibilityOfPort, 'scoped'))
            visibility{i} = char(Scope.Scoped);
        else
            visibility{i} = char(Scope.Local);
        end
    end   
end