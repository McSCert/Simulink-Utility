function finalLineParent = get_final_line_parent(line)
    % Recursively finds a Simulink signal line's LineParent until one is
    % found with no parent.
    
    if get_param(line, 'LineParent') == -1
        finalLineParent = line;
    else
        finalLineParent = get_final_line_parent(get_param(line, 'LineParent'));
    end
end