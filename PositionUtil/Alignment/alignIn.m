function alignIn(blocks)
    % First version
    for i = 1:length(blocks)
        in = getPorts(blocks{i}, 'Inport'); in = in(1);
        out = getSrcs(in); out = out{1};
        alignPorts(out,in)
    end
end