function [numInports, inports] = find_inports(sys)
    inports = find_system(sys, 'SearchDepth', '1', 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'Inport');
   
    numInports = length(inports);
end