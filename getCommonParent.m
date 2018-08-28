function system = getCommonParent(objects)
    % GETCOMMONPARENT Find the parent system of the given of the given objects.
    % If noot all given objects have the same parent, then throws an error.
    %
    % Inputs:
    %   objects     Vector of Simulink object handles. If given a cell
    %               array objects it will be converted to vector.
    %
    % Output:
    %   system      Simulink system.
    
    objects = inputToNumeric(objects);
    
    system = get_param(getParentSystem(objects(1)), 'Handle');
    for i = 2:length(objects)
        assert(system == get_param(getParentSystem(objects(i)), 'Handle'), ...
            'Each block must be directly within the same subsystem. I.e. blocks must share a parent.')
    end
end