function [in, out] = getFcnArgsDim(fcn)
% GETFCNARGSDIM Get the dimensions of Simulink Function input/output arguments, 
%   i.e., any ArgIn or ArgOut blocks.
%
%   Inputs:
%       fcn    Simulink Function path name or handle.
%
%   Outputs:
%       in     Dimensions of ArgIn blocks.
%       out    Dimensions of ArgOut blocks.

    fcn = inputToCell(fcn);
    
    argsIn = find_system(fcn, 'SearchDepth', 1, 'BlockType', 'ArgIn');
    argsOut = find_system(fcn, 'SearchDepth', 1, 'BlockType', 'ArgOut');

    in = cell(size(argsIn));
    out = cell(size(argsOut));
    
    for i = 1:length(argsIn)
        in{i} = str2num(get_param(argsIn{i}, 'PortDimensions'));
    end

    for j = 1:length(argsOut)
        out{j} = str2num(get_param(argsOut{j}, 'PortDimensions'));
    end 
end