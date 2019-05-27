function [numOutports, outports] = find_outports(sys)
    % (Top-level inports of sys)

    outports = find_system(sys, 'SearchDepth', '1', 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'Outport');
   
    numOutports = length(outports);
end