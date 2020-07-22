function setFcnScope(blocks, scope, subsystem)
% SETFCNSCOPE Change a Simulink Function's scope. This means adjusting a block's
%   Function Visibility Parameter and/or placement in the model.
%
%   Inputs:
%       blocks      Block path names or handles.
%       scope       Scope.Global, Scope.Scoped, or Scope.Local.
%       subsystem   For a Local function, the path of the existing subsystem to
%                   move it to. [Optional]
%
%   Outputs:
%       N/A

    % Handle input: Convert to cell array of path names
    blocks = inputToCell(blocks);
        
    % 1) Set Function Visibility parameter
    for j = 1:length(blocks)
        triggerPort = find_system(blocks{j}, 'SearchDepth', 1, 'FollowLinks', 'on', ... 
            'BlockType', 'TriggerPort', ...
            'TriggerType', 'function-call');
        
        if (scope == Scope.Global)
            set_param(triggerPort{1}, 'FunctionVisibility', 'global'); % Should only be one
        else
            set_param(triggerPort{1}, 'FunctionVisibility', 'scoped');
        end
    end
    
    % 2) Move to proper location in the model
    if (nargin < 3) && ~exist('subsystem', 'var')
       moveToAdjustScope(blocks, scope, '');
    end
    moveToAdjustScope(blocks, scope, subsystem);
end

function moveToAdjustScope(blocks, visibility, subsystem)
% MOVETOADJUSTSCOPE Move to proper location according to exporting rules.
%   1) Global functoins can be placed anywhere in a model.
%   2) Scoped functions are placed at the top level so that they are exported. 
%   3) Local functiosn are placed in a subsystem so that they are not exported.
% This function moves blocks in cases 2) and 3).
%
%   Inputs:
%       blocks      Block path names or handles.
%       visibility  Global(0), Scoped(1), or Local(2).
%       subsystem   For a Local function, the path of the existing subsystem to
%                   move it to. [Optional]
%
%   Outputs:
%       N/A

    % If fcn blocks are moved, function callers may become inaccurate
    if (visibility == Scope.Scoped) || (visibility == Scope.Local)
        %warnings = cell(length(blocks), 1);
        %existingCallers = cell(length(blocks), 1);
        for i = 1:length(blocks)
            callers = findCallers(blocks{i});
            if ~isempty(callers)
                warning([blocks{i} ' has changed scope, but has existing Function ' ...
                    'Callers which may need updating.']);
                disp(callers);
            end
        end
    end
    
    % Case 2: scoped function
    if (visibility == Scope.Scoped)
        % Move to root system
        for k = 1:length(blocks)
            if ~inRoot(blocks{k})
                b = blocks(k);
                move_block(b{:}, bdroot);
            end
        end
    % Case 3: local function
    elseif (visibility == Scope.Local)
        % Determine which blocks to move
        blocksToMove = inputToNumeric(blocks);

         % If a subsystem is provided, move it there
         % Otherwise, create a new one
         if (nargin > 2) && exist('subsystem', 'var') && ~isempty(subsystem)
             if strcmp(get_param(subsystem, 'SFBlockType'), 'Chart')
                 % TODO: Convert Sim Fcn to Stateflow Sim Fcn?
             else
                 for m = 1:length(blocksToMove)
                    move_block(blocksToMove(m), subsystem);
                 end 
             end
         else
            Simulink.BlockDiagram.createSubsystem(blocksToMove);
         end
    end    
end