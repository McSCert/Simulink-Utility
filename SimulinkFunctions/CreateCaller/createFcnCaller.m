function caller = createFcnCaller(sys, blockPath, varargin)
% CREATEFCNCALLER Create a function caller block for a Simulink function, 
%   anywhere in the model or parent hierarchy, with the prototype and the input/output  
%   argument specifications populated.
%
%   Inputs:
%       sys         Subsystem in which to place the new caller.
%       blockPath   Simulink Function block path name.
%       prototype   Simulink Function prototype. [Optional]
%       position    [x,y] coordinate where to insert the block. [Optional]
%
%   Outputs:
%       caller      Handle of Function Caller block.
%
%   Example:
%       createFcnCaller(gcs, 'model1/Simulink Function')
        
    callerNum = 1;
    loadedSys = false;

    % Get the model
    try
        blockSys = bdroot(blockPath);
    catch % not loaded
            i = regexp(blockPath, '/', 'once');
            blockSys = blockPath(1:i-1);
            load_system(blockSys);
            loadedSys = true;
    end
    
    % Determine Simulink Function block parameters
    % 1) Prototype
    prototype = getInput('prototype', varargin);
    if isempty(prototype)
        prototype = createPrototype(sys, blockPath);
    end
    
    % 3) Position
    position = getInput('position', varargin);
    
    % 2) InputArgumentSpecifications, OutputArgumentSpecifications
    argsIn = find_system(blockPath, 'SearchDepth', 1, 'BlockType', 'ArgIn');
    argsOut = find_system(blockPath, 'SearchDepth', 1, 'BlockType', 'ArgOut');

    argsInSpec = '';
    for a = 1:length(argsIn)
        type = get_param(argsIn{a}, 'OutDataTypeStr');
        dim = get_param(argsIn{a}, 'PortDimensions');
        if isempty(argsInSpec)
            argsInSpec = [type '(' dim ')'];
        else
            argsInSpec = [argsInSpec ', ' type '(' dim ')'];
        end
    end
    argsOutSpec = '';
    for b = 1:length(argsOut)
        type = get_param(argsOut{b}, 'OutDataTypeStr');
        dim = get_param(argsOut{b}, 'PortDimensions');
        if isempty(argsOutSpec)
            argsOutSpec = [type '(' dim ')'];
        else
            argsOutSpec = [argsOutSpec ', ' type '(' dim ')'];
        end
    end
    
    % Create caller block (with a unique name)
    blockCreated = false;
    while ~blockCreated
        try
            caller = add_block('simulink/User-Defined Functions/Function Caller', ...
                [sys '/Function Caller' num2str(callerNum)], ...
                'FunctionPrototype', prototype);
            callerNum = callerNum + 1;
            blockCreated = true;
        catch ME
           if strcmp(ME.identifier, 'Simulink:Commands:AddBlockCantAdd')
                callerNum = callerNum + 1;
            else
                rethrow(ME)
            end
        end
    end
    % Try setting the input and output arguments
    triggerPort = find_system(blockPath, 'SearchDepth', 1,'FollowLinks', 'on', ...
        'BlockType', 'TriggerPort', ...
        'TriggerType', 'function-call');
    fcnName = get_param(triggerPort, 'FunctionName');
    fcnName = fcnName{:};
    try
        set_param(caller, 'InputArgumentSpecifications', argsInSpec)
    catch
        warning(['Error creating Function Caller for ''' fcnName ''' because an input argument is a user defined data type. ', ...
            'Argument data type must be built-in data types. ', ...
            'User-defined data types, including Bus, Fixed-point, Enumerations, and Alias types, may be provided with a Simulink.Parameter object.']);
    end
    try
        set_param(caller, 'OutputArgumentSpecifications', argsOutSpec)
    catch
        warning(['Error creating Function Caller for ''' fcnName ''' because an output argument is a user defined data type. ', ...
            'Argument data type must be built-in data types. ', ...
            'User-defined data types, including Bus, Fixed-point, Enumerations, and Alias types, may be provided with a Simulink.Parameter object.']);
    end 
    
    % Position the block 
    if ~isempty(position)
        oldPosition = get_param(caller, 'Position');
        height = oldPosition(4) - oldPosition(2);
        width  = oldPosition(3) - oldPosition(1);
        
        heightOffset = height/2;
        widthOffset = width/2;
        newPosition = [position(1)-widthOffset, position(2)-heightOffset, position(1)+widthOffset, position(2)+heightOffset];
        set_param(caller, 'Position', newPosition);
    end    
        
    % Resize block width    
    oldSize = get_param(caller, 'Position');
    [~, newSize] = adjustWidth(caller, 'PerformOperation', 'off', 'Buffer', 12);
    if (newSize(3) - newSize(1)) > (oldSize(3) - oldSize(1)) % Only resize if it's getting bigger
        set_param(caller, 'Position', newSize);
    end
    % Resize block height
    ports = get_param(caller, 'Ports');
    if ports(1) > 1 || ports(2) > 1
        adjustHeight(caller, 'PortParams', {'ConnectionType', {'Inport','Outport'}, 'Method', 'Compact', 'HeightPerPort', 30});
    end

    % Close system
    if loadedSys
        close_system(blockSys);
    end
end