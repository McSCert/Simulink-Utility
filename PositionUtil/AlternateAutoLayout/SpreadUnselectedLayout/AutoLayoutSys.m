function AutoLayoutSys(systems)
    % Takes a set of systems and lays them out.
    %
    % systems may be a cell array of 0 to n systems or just a system where
    % a system is a handle or fullname of a Simulink system.
    
    if iscell(systems)
        for i = 1:length(systems)
            system = systems{i};
            objects = find_objects_in_system(system);
            TEMPAutoLayout(objects);
        end
    else
        system = systems;
        objects = find_objects_in_system(system);
        TEMPAutoLayout(objects);
    end
end
function objects = find_objects_in_system(system)
    objects = find_system(system, 'SearchDepth', 1, 'FindAll', 'on');
end