function blockName = get_block_name(block)
% Use when the model containing the block is not open, otherwise use
% get_param(block, 'Name').

pattern = '.*[^/]/([^/])'; % Largest pattern ending with a lone '/' not at the beginning or end of char array.
tmpBlockName = regexprep(block, pattern, '$1');
blockName = regexprep(tmpBlockName, '//', '/'); % Replace pairs of '/' with just one

% endIdx = regexprep(block, '[^/]/[^/]', 'end');
% blockName = block(endIdx:end);
end