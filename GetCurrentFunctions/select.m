function select(objects, varargin)
    % SELECT Sets the 'Selected' parameter to 'on' for given Simulink objects.
    %
    % Inputs:
    %   objects     Cell array of block names or vector of Simulink handles.
    %   varargin    [Optional] Sets 'Selected' to the given value ('on' or
    %               'off').
    %
    
    if isempty(varargin) || strcmpi(varargin{1}, 'on')
        sel = 'on';
    elseif strcmpi(varargin{1}, 'off')
        sel = 'off';
    else
        error([mfilename ' expects 2nd argument to be ''on'' or ''off''.'])
    end
    
    objects = inputToNumeric(objects);
    for i = 1:length(objects)
        o = objects(i);
        set_param(o, 'Selected', sel);
    end
end