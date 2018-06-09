function [success, newPosition] = vertAdjustForConnectedBlocks(block, varargin)
    % VERTADJUSTFORCONNECTEDBLOCKS Modifies the top and bottom positions of
    % a block to make it tall enough for the blocks it connects with
    % through signal line (the meaning of "tall enough" is determined
    % through input options.
    %
    % Input:
    %   block       Simulink block
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'Buffer'
    %   Value: Number of pixels to adjust final top and bottom position
    %       values by. Default: 20.
    %	Parameter: 'ConnectionType'
    %	Value:  {'Inport'} - Use inputs to determine desired size.
    %           {'Outport'} - Use outputs to determine desired size.
    %           {'Inport', 'Outport'} - (Default) Use inputs and outputs to
    %               determine desired size.
    %   Parameter: 'Method'
    %   Value:  'Sum' - (Default) Set height to the sum of heights of
    %               connected inputs/outputs (if ConnectionType is using
    %               both, then use the one which gives the greater sum).
    %           'SumMax' - Same as 'Sum', but all inputs are assumed to
    %               have the same height as the one with the max height
    %               among them and likewise for outputs. This method may
    %               help with alignment of blocks, but is likely to make
    %               blocks far larger than is visually appealing.
    %           'MinMax' - Set height to the min top position and the max
    %               bottom position.
    %   Parameter: 'HeightPerPort' - Used when Method is not 'MinMax'.
    %   Value:  Any double. Default: 10.
    %   Parameter: 'PerformOperation'
    %   Value:  'on' - (Default) Moves the block if it can.
    %           'off' - Does not move block (just returns the position it
    %                   would be given).
    %
    % Output:
    %	success		Logical true if height changed successfully. Logical
    %               false if height not changed, for example if the block
    %               doesn't connect to any ports to base the height off of.
    %
    % Effect:
    %   Block vertical position adjusted based on input and output blocks.
    %
    
    Buffer = 20;
    ConnectionType = lower({'Inport', 'Outport'});
    Method = lower('Sum');
    HeightPerPort = 10;
    PerformOperation = 'on';
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('Buffer')
                Buffer = value;
            case lower('ConnectionType')
                for j = 1:length(value)
                    assert(any(strcmpi(value{j},{'Inport','Outport'})), ...
                        ['Unexpected value for ' param ' parameter.'])
                end
                ConnectionType = value;
            case lower('Method')
                assert(any(strcmpi(value,{'Sum','SumMax','MinMax'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                Method = value;
            case lower('HeightPerPort')
                HeightPerPort = value;
            case lower('PerformOperation')
                assert(any(strcmpi(value,{'on','off'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                PerformOperation = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    connectedBlocksStruct = {};
    for i = ConnectionType
        pType = i{1};
        if strcmpi('Inport', pType)
            ports = getSrcs(block, 'IncludeImplicit', 'off');
        elseif strcmpi('Outport', pType)
            ports = getDsts(block, 'IncludeImplicit', 'off');
        else
            error('Unexpected port type.')
        end
        
        newConnectedBlocksStruct = cell(1,length(ports));
        for j = 1:length(ports)
            assert(strcmp('port', get_param(ports{j}, 'Type')))
            newConnectedBlocksStruct{j} = struct('block', get_param(ports{j}, 'Parent'), 'pType', pType);
        end
        connectedBlocksStruct = [connectedBlocksStruct, newConnectedBlocksStruct];
    end
    
    oldPosition = get_param(block, 'Position');
    connectedBlocks = cellfun(@(x) x.block, connectedBlocksStruct(:), 'UniformOutput', false);
    switch Method
        case lower({'Sum','SumMax'})
            % Get list of input and output blocks
            inIndexes = strcmp(cellfun(@(x) x.pType, connectedBlocksStruct(:), 'UniformOutput', false),'inport');
            outIndexes = not(inIndexes);
            inBlocks = connectedBlocks(inIndexes);
            outBlocks = connectedBlocks(outIndexes);
            switch Method
                case lower('Sum')
                    % Get sum of block heights
                    inSum = getSumOfBlockHeights(inBlocks);
                    outSum = getSumOfBlockHeights(inBlocks);
                    
                    newHeight = max([inSum + HeightPerPort*length(inBlocks), outSum + HeightPerPort*length(outBlocks)]);
                case lower('SumMax')
                    % Find max block height for inports and seperately for
                    % outports in connectedBlocksStruct
                    inMax = getMaxBlockHeight(inBlocks);
                    outMax = getMaxBlockHeight(outBlocks);
                    
                    newHeight = max([(inMax+HeightPerPort)*length(inBlocks),(outMax+HeightPerPort)*length(outBlocks)]);
                otherwise
                    error('Something went wrong.')
            end
            newHeight = newHeight + 2*Buffer;
            midY = (oldPosition(2)+oldPosition(4))/2; % Middle of the block on the y-axis
            newPosition = [oldPosition(1), midY-ceil(newHeight/2), oldPosition(3), midY+floor(newHeight/2)]; % Using ceil and floor to have integers
        case lower('MinMax')
            % Find most extreme top and bot position values
            
            if isempty(connectedBlocksStruct)
                newPosition = oldPosition;
            else
                [minimum, maximum] = getMinMaxVertPos(connectedBlocks);
                newPosition = [oldPosition(1), minimum - Buffer, oldPosition(3), maximum + Buffer];
            end
        otherwise
            error('Unexpected parameter value.')
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

function [minimum, maximum] = getMinMaxVertPos(blocks)
    assert(~isempty(blocks))
    pos = get_param(blocks{1}, 'Position');
    maximum = pos(4);
    minimum = pos(2);
    for i = 2:length(blocks)
        pos = get_param(blocks{i}, 'Position');
        
        if pos(4) > maximum % Recall pos(4) is bottom and bottom has higher value than top
            maximum = pos(4);
        end
        if pos(2) < minimum % Recall pos(2) is top
            minimum = pos(2);
        end
    end
end

function maximum = getMaxBlockHeight(blocks)
    maximum = 0;
    for i = 1:length(blocks)
        pos = get_param(blocks{i}, 'Position');
        
        height = pos(4) - pos(2);
        
        if height > maximum
            maximum = height;
        end
    end
end

function sum = getSumOfBlockHeights(blocks)
    sum = 0;
    for i = 1:length(blocks)
        pos = get_param(blocks{i}, 'Position');
        
        height = pos(4) - pos(2);
        
        sum = sum + height;
    end
end