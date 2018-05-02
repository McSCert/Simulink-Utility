function handle = move_block(block, sys)
    %   MOVE_BLOCK Moves a given Simulink block to a given Simulink system.
    %       Lines that were connected to the original block will be
    %       disconnected and the ports of the final block will have no
    %       signals connected to it.
    %
    %   Inputs:
    %       block   Full path or handle of a block.
    %       sys     Target system for the block to move to.
    %
    %   Outputs:
    %       handle  The handle of the resulting block.
    %
    %   Example:
    %       h = move_block(gcbh, get_param(bdroot(gcbh), 'Name'));

    % Future work:
    % - allow user to pass additional arguments to change the
    % parameters of the block being moved. -- Pass varargin, and include
    % varargin in the call to add_block, if 'Name' is given then use the
    % corresponding value in the call to set_name_unique.
    % - allow user to pass an additional argument indicating
    % where/how to position the block (e.g. just to the right of all other
    % blocks in the system, in the center of all of the blocks in the
    % system, etc.
    
    % Choose arbitrary start name for the block after moving it.
    % If the original block name is used in add_block, then there may
    % (will?) be undesired behaviour if the block's name parameter has a
    % '/' character in it.
    tmpDst = [sys '/temp_name'];
    
    % Add the block to the desired system.
    % MakeNameUnique is on to avoid errors for a block named temp_name
    % already existing.
    handle = add_block(block, tmpDst, 'MakeNameUnique', 'On');
    
    % Set the name to the same as the original block (or with an appended
    % integer to be a unique name in the system).
    set_name_unique(handle, get_param(block, 'Name'));
    
    % Delete block to finish the "move"
    delete_block(block)
end

function set_name_unique(h, baseName, varargin)
    % Set the name of h to baseName. If baseName is in use in the parent
    % system of h, then an integer is appended and incremented via
    % recursive calls until an available name is found.
    
    if isempty(varargin)
        suffix = '';
        n = 1; % Used in next suffix
    else
        suffix = num2str(varargin{1});
        n = varargin{1} + 1; % Used in next suffix
    end
    name = [baseName, suffix];
    
    try
        set_param(h, 'Name', name);
    catch ME
        if strcmp(ME.identifier, 'Simulink:blocks:DupBlockName')
            % Another block is already using name
            set_name_unique(h, baseName, n);
        else
            rethrow(ME)
        end
    end
end