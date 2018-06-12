function delete_block_lines(block)
    
    phs = getPorts(block,'All');
    for i = 1:length(phs)
        lh = get_param(phs(i), 'Line');
        if lh ~= -1
            delete_line(lh)
        end
    end
end