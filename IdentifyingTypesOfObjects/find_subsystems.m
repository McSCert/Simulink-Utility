function [numSubsystems, subsystems] = find_subsystems(sys)
    subsystems = find_system(sys, 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
        'BlockType', 'SubSystem', 'SFBlockType', 'NONE');
        
    numSubsystems = length(subsystems);
end