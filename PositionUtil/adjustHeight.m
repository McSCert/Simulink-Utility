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
    %   Parameter: 'UseInOutportDefault'
    %   Value:  'on' - (Default) Instead of algorithmically setting inport
    %               and outport block height, the function simply sets it
    %               to 14.
    %           'off' - Applies the same algorithm as for all other blocks.
    %   Parameter: 'ExpandDirection' - Direction(s) in which the block will
    %       be expanded (or shrunk). Used when Method is not 'MinMax'.
    %   Value:  'bottom' - (Default) Block will expand downward (top
    %               fixed).
    %           'top' - Block will expand upward (bottom fixed).
    %           'equal' - Block will expand equally up and down.
    %   Parameter: 'PerformOperation' - (Supercedes option of the same name
    %       in adjustHeightForConnectedBlocks).
    %   Value:  'on' - (Default) Moves the block if it can.
    %           'off' - Does not move block (just returns the position it
    %                   would be given).
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
    removeIndices = zeros(1,length(varargin)); % Remove parameters that are found so just the remaining ones can be passed forward
    % TODO implement this parameter:
    AccountForText = 'off'; % Default will be 'on'
    UseInOutportDefault = 'on';
    ExpandDirection = 'bottom';
    PerformOperation = 'on';
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('AccountForText')
                assert(any(strcmpi(value,{'on','off'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                AccountForText = value;
                removeIndices(i) = 1;
                removeIndices(i+1) = 1;
            case lower('UseInOutportDefault')
                assert(any(strcmpi(value,{'on','off'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                UseInOutportDefault = value;
                removeIndices(i) = 1;
                removeIndices(i+1) = 1;
            case lower('ExpandDirection')
                assert(any(strcmpi(value,{'bottom','top','equal'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                ExpandDirection = value;
                % Don't remove this parameter, we want to pass it forward
                % still
            case lower('PerformOperation')
                assert(any(strcmpi(value,{'on','off'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                PerformOperation = value;
                removeIndices(i) = 1;
                removeIndices(i+1) = 1;
        end
    end
    varargin = varargin(~removeIndices);
    
    oldPosition = get_param(block, 'Position');
    
    bType = get_param(block, 'BlockType');
    if strcmpi(UseInOutportDefault, 'on') && any(strcmpi(bType, {'Inport', 'Outport'}))
        keepPos = [oldPosition(1), 0, oldPosition(3), 0]; % Portion of the old position to keep
        
        newHeight = 14;
        switch ExpandDirection
            case 'top'
                newPosition = keepPos + [0, oldPosition(4)-newHeight, 0, oldPosition(4)];
            case 'bottom'
                newPosition = keepPos + [0, oldPosition(2), 0, oldPosition(2)+newHeight];
            case 'equal'
                midY = (oldPosition(2)+oldPosition(4))/2; % Middle of the block on the y-axis
                newPosition = keepPos + [0, midY-ceil(newHeight/2), 0, midY+floor(newHeight/2)]; % Using ceil and floor to have integers
            otherwise
                error('Something went wrong.')
        end
    else
        switch AccountForText
            case 'off'
                [~, newPosition] = adjustHeightForConnectedBlocks(block, 'PerformOperation', 'off', varargin{:});
            case 'on'
                error('Nothing has been implemented here yet.')
            otherwise
                error('Something went wrong.')
        end
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