function [numOutports, outports] = find_outports(sys)
    outports = find_system(sys, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'Outport');
   
    numOutports = length(outports);
end