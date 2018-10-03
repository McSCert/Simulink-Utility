function maxWidth = getMaxWidth(blocks)
	% GETMAXWIDTH Find the greatest with among given blocks.
	%
	% Inputs:
	%	blocks 		Cell array of Simulink block fullnames and/or handles.
    %
    % Outputs:
    % 	maxWidth 	The value of the greatest width found among the blocks.
    %

    maxWidth = 0;
    for i = 1:length(blocks)
        bwidth = getBlockWidth(blocks{i});
        if bwidth > maxWidth
            maxWidth = bwidth;
        end
    end
end