function prototype = getPrototype(fcn)
% GETPROTOTYPE Find the prototype for a Simulink Function.
%
%   Inputs:
%       fcn        Simulink Function pathnames or handles.
%
%   Outputs:
%       prototype  Simulink Functions prototypes.

    triggerPort = find_system(fcn, 'SearchDepth', 1, 'FollowLinks', 'on', ...
        'BlockType', 'TriggerPort', ...
        'TriggerType', 'function-call');
    prototype = get_param(triggerPort, 'FunctionPrototype');
    
    if isscalar(prototype)
        prototype = char(prototype);
    end        
end