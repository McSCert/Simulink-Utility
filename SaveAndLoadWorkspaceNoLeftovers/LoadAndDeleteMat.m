function LoadAndDeleteMat(mat_filepath)
    % LOADANDDELETMAT Return the workspace to what a mat file shows and
    % delete the mat file.
    % This is intended to be used in conjunction with SaveAndClearBaseVars
    % which creates a mat file.
    %
    % Input:
    %
    % Output:
    %
    
    evalin('base', 'clear')
    evalin('base', ['load(''', mat_filepath, ''')'])
    delete(mat_filepath)
end