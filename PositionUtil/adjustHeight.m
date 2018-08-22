function [success, newPosition] = adjustHeight(block, varargin)
    % ADJUSTHEIGHT Modifies the top and bottom positions of
    % a block to make it an appropriate height. The primary method of
    % determining an appropriate height is based on
    % adjustHeightForConnectedBlocks.m.
    %
    % Input:
    %   block       Simulink block
    %   varargin	Parameter-Value pairs as detailed below and additional
    %               options in adjustHeightForConnectedBlocks.m may also be
    %               used.
    %
    % Parameter-Value pairs:
    %   Parameter: 'ExpandDirection' - Direction(s) in which the block will
    %       be expanded (or shrunk). Used when Method is not 'MinMax'.
    %   Value:  'bottom' - (Default) Block will expand downward (top
    %               fixed).
    %           'top' - Block will expand upward (bottom fixed).
    %           'equal' - Block will expand equally up and down.
    %   Parameter: 'PerformOperation'
    %   Value:  'on' - (Default) Moves the block if it can.
    %           'off' - Does not move block (just returns the position it
    %                   would be given).
    %   Parameter: 'BlockTypeDefaults' - Indicate block types for which
    %       to use default block heights. Uses the first element of
    %       find_system('simulink', 'BlockType', <block type>) as the
    %       default.
    %   Value: Cell array of block types. (Default) {'Inport', 'Outport'},
    %       this is the cell array of block types that have been tested to
    %       confirm they have reasonable defaults.
    %
    %   Parameter: 'PortParams'
    %   Value:  Cell array of optional arguments to pass to
    %       adjustHeightForConnectedBlocks.m, 'PerformOperation', 'off' is
    %       passed automatically. (Default) Empty cell array (pass no
    %       optional arguments except 'PerformOperation').
    %
    % Output:
    %	success		Logical true if height changed successfully. Logical
    %               false if height not changed, for example if the block
    %               doesn't connect to any ports to base the height off of.
    %   newPosition New position value that was given or that would be
    %               given.
    %
    % Effect:
    %   Block vertical position adjusted based on input and output blocks.
    %
    
    % Handle inputs
    AccountForText = 'off'; % Default will be 'on' once implemented
    ExpandDirection = 'bottom';
    BlockTypeDefaults = {'Inport', 'Outport'};
    PerformOperation = 'on';
    PortParams = {};
    assert(mod(length(varargin),2) == 0, 'Even number of varargin arguments expected.')
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('AccountForText')
                assert(any(strcmpi(value,{'on','off'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                AccountForText = value;
            case lower('ExpandDirection')
                assert(any(strcmpi(value,{'bottom','top','equal'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                ExpandDirection = value;
            case lower('BlockTypeDefaults')
                assert(iscell(value), ...
                    ['Unexpected value for ' param ' parameter.'])
                BlockTypeDefaults = value;
            case lower('PerformOperation')
                assert(any(strcmpi(value,{'on','off'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                PerformOperation = value;
            case lower('PortParams')
                assert(iscell(value), ...
                    ['Unexpected value for ' param ' parameter.'])
                PortParams = value;
        end
    end
    
    oldPosition = get_param(block, 'Position');
    keepPos = [oldPosition(1), 0, oldPosition(3), 0]; % Portion of the old position to keep
    
    newHeight = getDesiredBlockHeight(block, BlockTypeDefaults, AccountForText, PortParams);
    
    switch ExpandDirection
        case 'bottom'
            newPosition = keepPos + [0, oldPosition(2), 0, oldPosition(2)+newHeight, 0];
        case 'top'
            newPosition = keepPos + [0, oldPosition(4)-newHeight, 0, oldPosition(4), 0];
        case 'equal'
            midY = (oldPosition(2)+oldPosition(4))/2; % Middle of the block on the y-axis
            newPosition = keepPos + [0, midY-ceil(newHeight/2), 0, midY+floor(newHeight/2)]; % Using ceil and floor to have integers
        otherwise
            error('Something went wrong.');
    end
    
    if strcmp(PerformOperation, 'on')
        set_param(block, 'Position', newPosition)
    end
    if all(newPosition == oldPosition)
        success = false;
    else
        success = true;
    end
end

function desiredHeight = getDesiredBlockHeight(block, BlockTypeDefaults, AccountForText, PortParams)
    % Gets height of Simulink defaults for given block types and otherwise
    % uses height of text in the block (not always accurate).
    
    bType = get_param(block, 'BlockType');
    switch bType
        case BlockTypeDefaults
            default_block = find_system('simulink', 'BlockType', bType);
            default_pos = get_param(default_block{1}, 'Position');
            desiredHeight = default_pos(4) - default_pos(2);
        otherwise
            switch AccountForText
                case 'off'
                    [~, newPosition] = adjustHeightForConnectedBlocks(block, 'PerformOperation', 'off', PortParams{:});
                case 'on'
                    error('Nothing has been implemented here yet.')
                otherwise
                    error('Something went wrong.')
            end
    end
end