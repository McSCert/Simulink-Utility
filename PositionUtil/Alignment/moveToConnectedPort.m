function moveToConnectedPort(block, varargin)
% MOVETOPORT Move a block to the right/left of the block it is connected to,
%   and align it with the port it is connected to. If it is connected to more
%   than one block, use the first port. If it is connected to both a source and
%   destination block, move to the source.
%
%   This function is best used for automatically moving blocks with a single
%   connection, such as a terminator or goto to its source.
%
%   Note: Trigger Ports are not yet supported.
%
%   Inputs:
%       block       Handle of the block to be moved.
%       varargin{1} Block offset in pixels.
%
%   Outputs:
%       N/A

    if nargin > 1
        blockOffset = varargin{1};
    else
        blockOffset = 70;
    end

    % Get block's current position
    blockPosition = get_param(block, 'Position');

    % Get the ports that it is connected to
    [srcPorts, dstPorts] = getConnectedPorts(block);

    if ~isempty(srcPorts)
        % Get port
        if length(srcPorts) > 1
            port = srcPorts(1);
        else
            port = srcPorts;
        end
        onLeft = false;
    elseif ~isempty(dstPorts)
        % Get port
        if length(dstPorts) > 1
            port = dstPorts(1);
        else
            port = dstPorts;
        end
        onLeft = true;
    else % Block is not connected to anything, so don't move
        return
    end

    % Get port position
    portPosition = get_param(port, 'Position');

    % Compute block dimensions which need to be maintained during the move
    blockHeight = blockPosition(4) - blockPosition(2);
    blockLength = blockPosition(3) - blockPosition(1);

    % Compute x dimensions
    if ~onLeft
        newBlockPosition(1) = portPosition(1) + blockOffset;     % Left
        newBlockPosition(3) = newBlockPosition(1) + blockLength; % Right
    else
        newBlockPosition(3) = portPosition(1) - blockOffset;     % Right
        newBlockPosition(1) = newBlockPosition(3) - blockLength; % Left
    end

    % Compute y dimensions
    newBlockPosition(2) = portPosition(2) - (blockHeight/2); % Top
    newBlockPosition(4) = portPosition(2) + (blockHeight/2); % Bottom

    set_param(block, 'Position', newBlockPosition);
end