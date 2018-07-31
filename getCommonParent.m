function system = getCommonParent(objects)
    %
    % Inputs:
    %   objects     Vector of Simulink object handles. If given a cell
    %               array objects it will be converted to vector.
    %
    % error if the parent is not common
    
    objects = inputToNumeric(objects);
    
    system = get_param(getParentSystem(objects(1)), 'Handle');
    for i = 2:length(objects)
        assert(system == get_param(getParentSystem(objects(i)), 'Handle'), ...
            'Each block must be directly within the same subsystem. I.e. blocks must share a parent.')
    end
end