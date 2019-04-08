function [numSubsystems, subsystems] = find_subsystems(sys)
    subsystems = find_system(sys, 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
        'BlockType', 'Subsystem', 'SFBlockType', 'NONE');
        
    numSubsystems = length(subsystems);
end