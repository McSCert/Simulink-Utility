function success = vertAdjustForConnectedBlocks(block, varargin)
    % VERTADJUSTFORCONNECTEDBLOCKS Modifies the top and bottom positions of
    % a block to extend as far as any blocks (this can be adjusted through
    % input options) that have a signal leading into or coming from the
    % block.
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
    %
	% Output:
	%	success		Logical true if height changed successfully. Logical
	%               false if height not changed, for example if the block
	%               doesn't connect to any ports to base the height off of.
	%
    % Effect:
    %   Block vertical position adjusted to the max and min heights of
    %   input and output blocks plus a buffer.
    %	
    
    buffer = 20;
    connectionType = {'inport', 'outport'};
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case 'buffer'
                buffer = value;
            case 'connectiontype'
                connectionType = value;
            otherwise
                error('Invalid parameter.')
        end
    end
	
	connectedBlocks = {};
	for i = connectionType
		pType = i{1};
		if strcmp('inport', pType)
			ports = getSrcs(block, 'IncludeImplicit', 'off');
		elseif strcmp('outport', pType)
			ports = getDsts(block, 'IncludeImplicit', 'off');
		else
			error('Unexpected port type.')
		end
		for j = 1:length(ports)
			assert(strcmp('port', get_param(ports{j}, 'Type')))
			connectedBlocks{end+1} = get_param(ports{j}, 'Parent');
		end
	end
	
	oldPosition = get_param(block, 'Position');
	if isempty(connectedBlocks)
		success = false;
	else
		pos = get_param(connectedBlocks{1}, 'Position');
		max = pos(4);
		min = pos(2);
		for i = 2:length(connectedBlocks)
			pos = get_param(connectedBlocks{i}, 'Position');
			
			if pos(4) > max % Recall pos(4) is bottom and bottom has higher value than top
				max = pos(4);
			end
			if pos(2) < min % Recall pos(2) is top
				min = pos(2);
			end
		end
		
		newPosition = [oldPosition(1), min - buffer, oldPosition(3), max + buffer];
		set_param(block, 'Position', newPosition)
		success = true;
	end
end