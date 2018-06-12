function [success, newPosition] = adjustWidth(block, varargin)
    % ADJUSTWIDTH
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
    PerformOperation = 'on';
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('Buffer')
                Buffer = value;
            case lower('ExpandDirection')
                assert(any(strcmpi(value,{'right','left','equal'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                ExpandDirection = value;
            case lower('PerformOperation')
                assert(any(strcmpi(value,{'on','off'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                PerformOperation = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    oldPosition = get_param(block, 'Position');
    keepPos = [0, oldPosition(2), 0, oldPosition(4)]; % Portion of the old position to keep
    
    newWidth = getDesiredBlockWidth(block, Buffer);
    
    switch ExpandDirection
        case 'right'
            newPosition = keepPos + [oldPosition(1), 0, oldPosition(1)+newWidth, 0];
        case 'left'
            newPosition = keepPos + [oldPosition(3)-newWidth, 0, oldPosition(3), 0];
        case 'equal'
            midX = (oldPosition(1)+oldPosition(3))/2; % Middle of the block on the x-axis
            newPosition = keepPos + [midX-ceil(newWidth/2), 0, midX+floor(newWidth/2), 0]; % Using ceil and floor to have integers
        otherwise
            error('Something went wrong.')
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

function desiredWidth = getDesiredBlockWidth(block, Buffer)
    
    bType = get_param(block, 'BlockType');
    switch bType
        case {'Inport', 'Outport'}
            desiredWidth = 30;
        case {'BusCreator', 'BusSelector', 'Mux', 'Demux'}
            desiredWidth = 5;
        otherwise
            [textWidth, ~] = getBlockTextWidth(block);
            desiredWidth = textWidth + 2*Buffer;
    end
end