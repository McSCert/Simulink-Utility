function AutoLayoutSys(systems)
    % AUTOLAYOUTSYS Takes a set of systems and lays them out.
    %
    % Input:
    %   systems     Vector of Simulink system handles. Also accepts a cell
    %               array of system handles and/or fullnames. Also accepts
    %               a char of a single system fullname.
    
    %%
    % Make input a vector of handles
    systems = inputToNumeric(systems);
    
    %%
    for i = 1:length(systems)
        system = systems(i);
        objects = find_objects_in_system(system);
        TEMPAutoLayout(objects);
    end
end
function objects = find_objects_in_system(system)
    objects = find_system(system, 'SearchDepth', 1, 'FindAll', 'on');
end