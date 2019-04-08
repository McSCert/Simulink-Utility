function [numLines, lines] = find_lines(sys)
    lines = find_system(sys, 'FindAll', 'on', 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'line');
   
    numLines = length(lines);
end