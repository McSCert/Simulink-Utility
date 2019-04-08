function [numInports, inports] = find_inports(sys)
    inports = find_system(sys, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'Inport');
   
    numInports = length(inports);
end