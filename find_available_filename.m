function filename = find_available_filename(baseFilename)
    % FIND_AVAILABLE_FILENAME Find an available filename by appending an integer
    % > 0 to the end of a base filename.
    %
    % Input:
    %   baseFilename    A char array of a filename.
    %
    % Output:
    %   filename        A char array of a currently unused filename.
    %
    
    if exist(baseFilename, 'file') == 4
        n = 1;
        [path,name,extension] = fileparts(baseFilename);
        while exist([path, '/', name, num2str(n), extension], 'file') == 4
            n = n + 1;
        end
        filename = [path, '/', name, num2str(n), extension];
    else
        % Return the base filename since it is available.
        filename = baseFilename;
    end
end