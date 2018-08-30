function [success, newPosition] = adjustWidth(block, varargin)
    % ADJUSTWIDTH Resizes given block horizontally.
    %
    % Input:
    %   block       Simulink block
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'Buffer'
    %   Value: Number of pixels to adjust final left and right position
    %       values by. Default: 5.
    %   Parameter: 'ExpandDirection' - Direction(s) in which the block will
    %       be expanded (or shrunk).
    %   Value:  'right' - (Default) Block will expand to the right (left
    %               fixed).
    %           'left' - Block will expand to the left (right fixed).
    %           'equal' - Block will expand equally to the right and left.
    %   Parameter: 'BlockTypeDefaults' - Indicate block types for which
    %       to use hardcoded default block widths.
    %   Value: Cell array of block types. (Default) {'Inport', 'Outport',
    %       'Logic', 'RelationalOperator', 'Delay', 'UnitDelay', 'Product',
    %       'Integrator', 'BusCreator', 'BusSelector', 'Mux', 'Demux',
    %       'Sum'}, this is the cell array of block types that have
    %       hardcoded defaults.
    %   Parameter: 'PerformOperation'
    %   Value:  'on' - (Default) Moves the block if it can.
    %           'off' - Does not move block (just returns the position it
    %                   would be given).
    %
    % Output:
    %	success		Logical true if width changed successfully. Logical
    %               false if width not changed, for example if the block
    %               doesn't connect to any ports to base the width off of.
    %   newPosition New position value that was given or that would be
    %               given.
    %
    % Effect:
    %   Block horizontal position adjusted based on input and output blocks.
    %
    
    Buffer = 5;
    ExpandDirection = 'right';
    BlockTypeDefaults = lower({'Inport', 'Outport', 'Logic', ...
        'RelationalOperator', 'Delay', 'UnitDelay', 'Product', ...
        'Integrator', 'BusCreator', 'BusSelector', 'Mux', 'Demux', 'Sum'});
    PerformOperation = 'on';
    assert(mod(length(varargin),2) == 0, 'Even number of varargin arguments expected.')
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = varargin{i+1};
        if ischar(value) || (iscell(value) && all(cellfun(@(a) ischar(a), value)))
            value = lower(value);
        end
        
        switch param
            case lower('Buffer')
                Buffer = value;
            case lower('ExpandDirection')
                assert(any(strcmpi(value,{'right','left','equal'})), ...
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
            otherwise
                error(['Invalid parameter: ' param '.'])
        end
    end
    
    oldPosition = get_param(block, 'Position');
    keepPos = [0, oldPosition(2), 0, oldPosition(4)]; % Portion of the old position to keep
    
    newWidth = getDesiredBlockWidth(block, Buffer, BlockTypeDefaults);
    
    switch ExpandDirection
        case 'right'
            newPosition = keepPos + [oldPosition(1), 0, oldPosition(1)+newWidth, 0];
        case 'left'
            newPosition = keepPos + [oldPosition(3)-newWidth, 0, oldPosition(3), 0];
        case 'equal'
            midX = (oldPosition(1)+oldPosition(3))/2; % Middle of the block on the x-axis
            newPosition = keepPos + [midX-ceil(newWidth/2), 0, midX+floor(newWidth/2), 0]; % Using ceil and floor to have integers
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

function desiredWidth = getDesiredBlockWidth(block, Buffer, BlockTypeDefaults)
    % Gets width of Simulink defaults for given block types and otherwise
    % uses width of text in the block (not always accurate).
    
    bType = lower(get_param(block, 'BlockType'));
    switch bType
        case BlockTypeDefaults
            switch bType
                case lower({'Inport', 'Outport', 'Logic', 'RelationalOperator', 'Product', 'Integrator'})
                    desiredWidth = 30;
                case lower({'Delay', 'UnitDelay'})
                    desiredWidth = 35;
                case lower({'BusCreator', 'BusSelector', 'Mux', 'Demux'})
                    desiredWidth = 5;
                case lower('Sum')
                    switch get_param(block, 'IconShape')
                        case 'round'
                            desiredWidth = 20;
                        case 'rectangular'
                            desiredWidth = 30;
                        otherwise
                            error(['Unexpected block ' 'IconShape' 'parameter value.'])
                    end
                otherwise
                    error('Unexpected value in BlockTypeDefaults.')
            end
        otherwise
            [textWidth, ~] = getBlockTextWidth(block);
            desiredWidth = textWidth + 2*Buffer;
    end
end

function desiredWidth = getDesiredBlockWidth2(block, Buffer, BlockTypeDefaults)
    % find_system('simulink', 'BlockType', bType) worked one day and not the
    % next
    %
    %   Parameter: 'BlockTypeDefaults' - Indicate block types for which
    %       to use default block widths. Uses the first element of
    %       find_system('simulink', 'BlockType', <block type>) as the
    %       default.
    
    % Gets width of Simulink defaults for given block types and otherwise
    % uses width of text in the block (not always accurate).
    
    bType = get_param(block, 'BlockType');
    switch bType
        case BlockTypeDefaults
            default_block = find_system('simulink', 'BlockType', bType);
            default_pos = get_param(default_block{1}, 'Position');
            desiredWidth = default_pos(3) - default_pos(1);
        otherwise
            [textWidth, ~] = getBlockTextWidth(block);
            desiredWidth = textWidth + 2*Buffer;
    end
end