function parent = getParentSystem(object)
    % GETPARENTSYSTEM Gets the parent system of a Simulink object.
    %
    % Input:
    %   object  A simulink object.
    %
    % Output:
    %   parent  The Simulink system in which the object is found.
    
    type = get_param(object, 'Type');
    switch type
        case 'port'
            tmp_object = get_param(object, 'Parent');
        otherwise
            tmp_object = object;
    end
    parent = get_param(tmp_object, 'Parent');
end