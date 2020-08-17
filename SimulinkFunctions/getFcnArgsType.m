function [in, out] = getFcnArgsType(fcn)
% GETFCNARGSTYPE Get the data types of Simulink Function input/output arguments, 
%   i.e., any ArgIn or ArgOut blocks.
%
%   Inputs:
%       fcn    Simulink Function path name or handle.
%
%   Outputs:
%       in     Data types of ArgIn blocks.
%       out    Data types of ArgOut blocks.

    fcn = inputToCell(fcn);
    
    argsIn  = find_system(fcn, 'FollowLinks', 'on', 'SearchDepth', 1, 'BlockType', 'ArgIn');
    argsOut = find_system(fcn, 'FollowLinks', 'on', 'SearchDepth', 1, 'BlockType', 'ArgOut');

    in = cell(size(argsIn));
    out = cell(size(argsOut));
    
    for i = 1:length(argsIn)
        in{i} = get_param(argsIn{i}, 'OutDataTypeStr');
    end

    for j = 1:length(argsOut)
        out{j} = get_param(argsOut{j}, 'OutDataTypeStr');
    end 
end