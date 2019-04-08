function [numBlocks, blocks] = find_blocks(sys)
    blocks = find_system(sys, 'LookUnderMasks', 'all', 'FollowLinks', 'on');
   
    numBlocks = length(blocks);
end