function alignIn(blocks)
    % Reposition each block to align its first inport with a port it
    % connects to.
    % Aligns from the first block to the last block in blocks.
    %
    
    % TODO: add support for round sum blocks
    % TODO: choose inport for output-input pairs more smartly
    %   e.g. don't choose one if it's not facing
    %   e.g. if multiple are facing, then which is closer
    
    % Second version
    for o = 1:length(blocks)
        in = getPorts(blocks{o}, 'Inport');
        if ~isempty(in)
            in = in(1);
            out = getSrcs(in);
            out = out{1};
            
            alignPorts(out,in)
        end
    end
end