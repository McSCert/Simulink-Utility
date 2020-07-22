function b = isSimulinkFcn(blocks)
% ISSIMULINKFUNCTION Determine if the block is a Simulink Function.
%
%   Inputs:
%       block   Pathname or handle of a block.
%
%   Outputs:
%       b       Whether the block is a Simulink Function(1) or not(0).
    
    % Convert whatever input to handles
    blocks = inputToNumeric(blocks);
    
    b = zeros(1, length(blocks));
    
    % Check if block is a Simulink Function
    for i = 1:length(blocks)
        try
            % Need to check the BlockType param because the TriggerPort inside the
            % Simulink Function also has the IsSimulinkFunction parameter 'on'
            b(i) = strcmpi(get_param(blocks(i), 'IsSimulinkFunction'), 'on') && ...
                strcmpi(get_param(blocks(i), 'BlockType'), 'SubSystem');
        catch % block does not have this parameter
        end
    end
end