function [fcns, prototype] = getCallableFunctions(sys)
% GETCALLABLEFUNCTIONS For some system, find which functions are availble to
%   call and how to call them (e.g., if a qualifier is necessary).
%
%   How is this different than the Prototype drop-down list in the Function Caller block?
%   The list provided by the Function Caller block does not consider restrictions 
%   due to atomic systems, which may result in a simulation error.
%
%   Inputs:
%       sys             Subsystem path name or handle.
%
%   Outputs:
%       fcns            Cell array of path names.
%       prototype       Prototye for calling simFcns from sys.

    [f1, p1] = getFcns(sys);
    [f2, p2] =  getExportFcns(sys);
    fcns = [f1; f2];
    prototype = [p1; p2];
end

function [fcns, prototype] = getFcns(sys)
% GETFCNS Find Simulink Functions in this model that can be called from a subsystem.
%   Inputs:
%       sys             Subsystem path name or handle.
%
%   Outputs:
%       fcns            Cell array of path names.
%       prototype       Prototye for calling simFcns from sys.

    fcns = {};
    prototype = {};
    
    fcnsAll = find_system(bdroot(sys), 'BlockType', 'SubSystem', 'IsSimulinkFunction', 'on');
    prototypeAll = getPrototype(fcnsAll); 
    if ~iscell(prototypeAll)
        prototypeAll = {prototypeAll};
    end
    
    vis = getFcnScope(fcnsAll);
    
    for j = 1:length(fcnsAll)
        % CASE 1: fcn is global -- note global fcn cannot be placed in atomic
        if (vis{j} == Scope.Global)                             
            fcns{end+1,1} = fcnsAll{j};
            prototype{end+1,1} =  prototypeAll{j};
            
        % CASE 2: fcn is in sys
        elseif strcmp(sys, get_param(fcnsAll{j}, 'Parent'))
            fcns{end+1,1} = fcnsAll{j};
            prototype{end+1,1} =  prototypeAll{j};
            
        % CASE 3: fcn is in any ancestor of sys
        elseif startsWith(sys, get_param(fcnsAll{j}, 'Parent')) 
            fcns{end+1,1} = fcnsAll{j};
            prototype{end+1,1} =  prototypeAll{j};
            
        % CASE 4: fcn is in child subsystem (except if atomic)
        elseif strcmp(get_param(get_param(fcnsAll{j}, 'Parent'), 'Parent'), sys) && ...
                strcmp(get_param(get_param(fcnsAll{j}, 'Parent'), 'TreatAsAtomicUnit'), 'off')
            
            fcns{end+1,1} = fcnsAll{j};
            
            % Add qualifier: subsystem name
            qualifier = get_param(get_param(fcnsAll{j}, 'Parent'), 'Name');
            if strfind(prototypeAll{j}, '=') % has an output
                prototype{end+1,1} = insertAfter(prototypeAll{j}, '= ', [qualifier '.']);
            else
                prototype{end+1,1} = [qualifier '.' prototypeAll{j}];
            end
            
        % CASE 5: fcn is in any parent's descendants (except if atomic)
        elseif inParentDescendants(sys, fcnsAll{j}) && ...
                strcmp(get_param(get_param(fcnsAll{j}, 'Parent'), 'TreatAsAtomicUnit'), 'off')
 
            fcns{end+1,1} = fcnsAll{j};
            
            % Add qualifier: subsystem name
            qualifier = get_param(get_param(fcnsAll{j}, 'Parent'), 'Name');
            if strfind(prototypeAll{j}, '=') % has an output
                prototype{end+1,1} = insertAfter(prototypeAll{j}, '= ', [qualifier '.']);
            else
                prototype{end+1,1} = [qualifier '.' prototypeAll{j}];
            end
        end
    end
end

function [fcns, prototype] = getExportFcns(sys)
% GETEXPORTFCNS Find functions exported from other models that can be called 
%   from a subsystem.
%
%   Inputs:
%       sys             Subsystem path name or handle.
%
%   Outputs:
%       fcns            Cell array of path names.
%       prototype       Prototye for calling simFcns from sys.

    fcns = {};
    prototype = {}; 

    % Find functions in the model hierarchy which were exported
    openedMdlsBefore = find_system('SearchDepth', 0); % Track which models are already opened
    searchedMdls = {sys};                              % Track which models were searched already
    mdlRefs = find_system(sys, 'LookUnderMasks', 'on', 'BlockType', 'ModelReference');
    mdls = get_param(mdlRefs, 'ModelName'); % Get actual model names (instead of the path to the model ref block)
   
    if ~isempty(mdls)
        for i = 1:numel(mdls)
            if ~ismember(mdls{i}, searchedMdls) % Check if already searched
                if ~bdIsLoaded(mdls{i}) % Load if necessary
                   load_system(mdls{i});
                   openedMdlsBefore{end+1} = mdls{i}; % Store so we can close later
                end
                % Get all the Simulink Function blocks
                fcnsAll = find_system(mdls{i}, 'BlockType', 'SubSystem', 'IsSimulinkFunction', 'on');

                for k = 1:numel(fcnsAll)
                    % Check what kind of visibility it has
                    vis = getFcnScope(fcnsAll{k});
                    if (vis{:} == Scope.Global) || (vis{:}  == Scope.Scoped)
                        fcns{end+1,1} = fcnsAll{k};
                        
                        % Add qualifier: Model Reference block name
                        qualifier = get_param(mdlRefs{i}, 'Name');
                        p = char(getPrototype(fcnsAll{k}));
                        if contains(p, '=') % has an output
                            prototype{end+1,1} = insertAfter(p, '= ', [qualifier '.']);
                        else
                            prototype{end+1,1} = [qualifier '.' p];
                        end
                    end
                end
            end
       end
    end
   
    % Close any models we opened
    openedMdlsAfter = find_system('SearchDepth', 0);
    for l = 1:numel(openedMdlsAfter)
        if ~ismember(openedMdlsAfter{l}, openedMdlsBefore) % if it was opened by us
            close_system(openedNowMdls{l}, 0);
        end
    end  
end