function lineHandles = connectBlocks(address, block1, block2, varargin)
% CONNECTBLOCKS Connects the unconnected ports between two blocks in a top-down
%   fashion. The outport(s) of block1 are connected to the inport(s) of block2.
%
%   Inputs:
%       address     System name.
%       block1      Source block that will have its outport(s) connected.
%       block2      Destination block that will have its inport(s) connected.
%       varargin      Options for add_line (e.g. 'autorouting', 'on).
%
%   Outputs:
%       lineHandles Vector of new line handles.

    % Get handles of the ports
    outHandles = get_param(block1, 'PortHandles');
    outHandles = outHandles.Outport;

    inHandles = get_param(block2, 'PortHandles');
    inHandles = inHandles.Inport;

    % Remove any ports that are already connected
    deleteOutPorts = false(length(outHandles),1);
    for i = 1:length(outHandles)
        if isPortConnected(outHandles(i))
            deleteOutPorts(i) = true;
        end
    end
    outHandles(deleteOutPorts) = [];
    
    deleteInPorts = false(length(inHandles),1);
    for i = 1:length(inHandles)
        if isPortConnected(inHandles(i))
            deleteInPorts(i) = true;
        end
    end
    inHandles(deleteInPorts) = [];
    
    % Connect the unconnected ports from top to bottom
    numConnections = min(length(outHandles), length(inHandles));
    lineHandles = zeros(0, numConnections);
    for i = 1:numConnections
        lineHandles(i) = add_line(address, outHandles(i), inHandles(i), 'autorouting', 'on');
    end
end

function connected = isPortConnected(port)
    connected = (get_param(port, 'Line') ~= -1);
end