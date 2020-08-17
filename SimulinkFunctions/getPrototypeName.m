function name = getPrototypeName(prototype)
% GETPROTOTYPENAME Get the name of the Simulink Function from the prototype string.
%
%   Inputs:
%       prototype   Char array or cell array of prototypes, as given by the 
%                   Prototype block parameter.
%
%   Outputs:
%       name        Char array or cell array of function names.

    if ~iscell(prototype)
        prototype = {prototype};
    end
    
    name = cell(size(prototype));
    
    for i = 1:length(prototype)

        endOfOutArgs = strfind(prototype{i}, '=') + 2; % Once space to omit the  =, and one to omit the space
        if isempty(endOfOutArgs)
            endOfOutArgs = 1;
        end

        endOfInArgs = strfind(prototype{i}, '(') - 1; % One space to omit the (
        if isempty(endOfInArgs)
            endOfInArgs = length(prototype{i});
        end

        name{i} = prototype{i}(endOfOutArgs : endOfInArgs);
    end
    
    if length(name) == 1
        name = name{1};
    end
end