function prototype = createPrototype(sys, fcn)
% CREATEPROTOTYPE Create the prototype necessary for calling a Simulink Function
%   from a particular subsystem.
%
%   Inputs:
%       sys             Subsystem in which to place the new caller.
%       fcn             Simulink Function block path name.
%
%   Outputs:
%       prototype       Prototype for calling simFcns from sys.

    p = getPrototype(fcn); 
    vis = getFcnScope(fcn);

    % Get the model that fcn is in
    try
        sys_fcn = bdroot(fcn);
    catch % not loaded
        i = regexp(fcn, '/', 'once');
        sys_fcn = fcn(1:i-1);
    end
    
    % CASE 1a: fcn is global
    if (vis == Scope.Global)                             
        qualifier = '';
        
    % CASE 1b: fcn is scoped and not in same model (scoped)
    elseif (vis == Scope.Scoped) && ~strcmp(sys, sys_fcn)

        % Qualifier is model reference block name
        mdl = find_system(sys, 'LookUnderMasks', 'on', 'BlockType', 'ModelReference', 'ModelName', sys_fcn);
        qualifier = char(get_param(mdl, 'Name'));

    % CASE 2: fcn is in sys
    elseif strcmp(sys, get_param(fcn, 'Parent'))
        qualifier = '';

    % CASE 3: fcn is in any ancestor of sys
    elseif startsWith(sys, get_param(fcn, 'Parent')) 
        qualifier = '';
        
    % CASE 4: fcn is in child
    elseif strcmp(get_param(get_param(fcn, 'Parent'), 'Parent'), sys)

        % Qualifier is subsystem name
        qualifier = get_param(get_param(fcn, 'Parent'), 'Name');

    % CASE 5: fcn is in any parent's descendants
    elseif inParentDescendants(sys, fcn)

        % Qualifier is subsystem name
        qualifier = get_param(get_param(fcn, 'Parent'), 'Name');
    end
    
    if ~isempty(qualifier)
        % Subsystem and model block names can have spaces and other illegal
        % chars, so check if they are ok for qualification purposes
        qualifierOK = regexp(qualifier, '^[a-zA-Z_]+\w*$', 'match');
        if qualifierOK
            if contains(p, '=') % has an output
                prototype = insertAfter(p, '= ', [qualifier '.']);
            else
                prototype = [qualifier '.' p];
            end
        else
            msg = [qualifier ' is not a valid identifier required for being a scope name.' ...
                'Valid identifiers start with an alphabetic or ''_'' character, '...
                'followed by alphanumeric or ''_'' characters.'];
            error(msg);
        end
    else
        prototype = p;
    end   
end