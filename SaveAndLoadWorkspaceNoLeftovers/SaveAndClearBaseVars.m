function base_vars_path = SaveAndClearBaseVars(default_filename)
    % SAVEANDCLEARBASEVARS
    %
    % Input:
    %
    % Output:
    %
    
    base_vars_path = getAvailableFileName(default_filename, '.mat');
    evalin('base', ['save(''', base_vars_path, ''')'])
    evalin('base', 'clear')
    function filepath = getAvailableFileName(default_filename, filetype)
        filename = [default_filename, filetype];
        filepath = [pwd, '/', filename];
        count = 0;
        while exist(filepath, 'file') == 2
            count = count + 1;
            filename = [default_filename, num2str(count), filetype];
            filepath = [pwd, '/', filename];
        end
    end
end