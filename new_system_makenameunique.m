function h = new_system_makenameunique(baseName, varargin)
    % NEW_SYSTEM_MAKENAMEUNIQUE new_system command except that it appends a
    %   number to the name to ensure a file with the name does not exist.
    %
    %   For more information about new_system, type: "help new_system" at the
    %   command line.
    
    name = baseName;
    if exist(name, 'file') == 4 || bdIsLoaded(name)
        n = 1;
        while exist(strcat(name, num2str(n)), 'file') == 4 ...
                || bdIsLoaded(strcat(name, num2str(n)))
            n = n + 1;
        end
        name = strcat(name, num2str(n));
    end
    
    try
        h = new_system(name,varargin{:});
    catch ME
        if bdIsLoaded(name)
            warning(['Error occurred in ' 'new_system' '. ' ...
                'Block diagram ' name ' was created. ' ...
                'The error message follows:' char(10) getReport(ME)])
            h = get_param(name, 'Handle');
        else
            rethrow(ME)
        end
    end
end