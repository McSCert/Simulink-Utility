function callers = findCallers(fcn)
% FINDCALLERS Find the Function Caller blocks that call the Simulink function.
%
%   Inputs:
%       fcn        Simulink Function path name.
%
%   Outputs:
%       callers    Cell array of Function Caller block path names.

    callers = {};
    
    % Check input
    assert(isSimulinkFcn(fcn) == true, [fcn ' is not a Simulink Function.']);
    
    % Get the model
    try
        blockSys = bdroot(fcn);
    catch % not loaded
        idx = regexp(fcn, '/', 'once');
        blockSys = fcn(1:idx-1);
        %load_system(blockSys);
        %loadedSys = true;
    end
    
    vis = getFcnScope(fcn);
    globalOrScoped = (vis == Scope.Global) || inRoot(fcn);
    proto_basic = getPrototype(fcn);
    
    % Get all callers that are applicable based on their location w.r.t. fcn
    %  I)   If fcn is global, callers can be in entire model
    %  II)  If fcn is at the root, callers can be in the entire model
    %  III) If fcn is local, callers can be in the parent or parent's descendants
    %  Exception exists for II and II when then fcn is in an atomic subsystem
    % TODO
    %  + If fcn is global or scoped, callers can also be in a parent model
    %  + Shadowing
    
    % CASE I & II: fcn is global, fcn is in root (includes scoped)
    if globalOrScoped
        % Get callers in the whole system
        calls = find_system(blockSys, 'BlockType', 'FunctionCaller');
        
        % Check that the prototype matches
        for i = 1:length(calls)
            if strcmp(proto_basic, get_param(calls(i), 'FunctionPrototype'))
                callers{end+1,1} = calls{i};
            end
        end
    % CASE II: fcn is local
    elseif (vis == Scope.Local)
        % Get callers in the function's parent and below
        calls = find_system(get_param(get_param(fcn, 'Parent'), 'Parent'), ...
            'BlockType', 'FunctionCaller');
        
        % Check that the prototype matches
        % Note: Scoped functions can be called with or without a qualifier
        parent = get_param(fcn, 'Parent');
        qualifier = get_param(parent, 'Name');
        qualifierOK = ~isempty(regexp(qualifier, '^[a-zA-Z_]+\w*$', 'match'));
        if qualifierOK
            if contains(proto_basic, '=') % has an output
                proto_qualified = insertAfter(proto_basic, '= ', [qualifier '.']);
            else
                proto_qualified = [qualifier '.' char(proto_basic)];
            end
        else
            % If the qualifier doesn't work, then they are not using it
            proto_qualified = '';
        end
        
        % Check that the prototype matches (when applicable)
        for j = 1:length(calls)
            % caller is in same subsystem, no qualifier needed
            if strcmp(parent, get_param(calls{j}, 'Parent'))
                if strcmp(proto_basic, get_param(calls{j}, 'FunctionPrototype'))
                    callers{end+1,1} = calls{j};
                end
            % caller is in a descendant subsystem (except if atomic), no qualifier needed
            elseif startsWith(get_param(calls{j}, 'Parent'), parent)
                if strcmp(proto_basic, get_param(calls{j}, 'FunctionPrototype'))
                    callers{end+1,1} = calls{j};
                end
            % caller is in the parent subsystem (except if atomic), qualifier needed
            elseif strcmp(get_param(calls{j}, 'Parent'), get_param(parent, 'Parent')) ...
                    && qualifierOK ...
                    && strcmp(get_param(parent, 'TreatAsAtomicUnit'), 'off')
                if strcmp(proto_qualified, get_param(calls{j}, 'FunctionPrototype'))
                    callers{end+1,1} = calls{j};
                end
            % caller is in parent's descendants (except if atomic), qualifier needed
            elseif inParentDescendants(get_param(calls{j}, 'Parent'), fcn) ...
                    && qualifierOK ...
                    && strcmp(get_param(parent, 'TreatAsAtomicUnit'), 'off')
                if strcmp(proto_qualified, get_param(calls{j}, 'FunctionPrototype'))
                    callers{end+1,1} = calls{j};
                end                
            end
        end
    end
end