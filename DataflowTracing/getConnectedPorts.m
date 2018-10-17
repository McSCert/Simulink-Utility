function [srcPorts, dstPorts] = getConnectedPorts(block)
% GETCONNECTEDPORT Get the ports that the block is connected to.
%
%   Note: Trigger Ports are not yet supported.
%
%   Inputs:
%       block       Block handle.
%
%   Outputs:
%       srcPorts    Port handles to source ports.
%       dstPorts    Port handles to destination ports.

    if isempty(block)
        srcPorts = [];
        dstPorts = [];
        return
    end

    connections = get_param(block, 'PortConnectivity');
    srcBlocks    = [connections.SrcBlock];
    srcPortNums  = [connections.SrcPort];

    dstBlocks    = [connections.DstBlock];
    dstPortNums  = [connections.DstPort];

    if ~isempty(srcBlocks) && ~all(srcBlocks == -1)
        allSrcBlockPorts = get_param(srcBlocks, 'PortHandles');
        if iscell(allSrcBlockPorts)
            allSrcBlockPorts = cell2mat(allSrcBlockPorts);
        end

        srcPorts = zeros(size(allSrcBlockPorts));
        for i = 1:length(allSrcBlockPorts)
            srcBlockOutports = allSrcBlockPorts(i).Outport;
            srcPorts(i) = srcBlockOutports(srcPortNums(i)+1); % Port indexes start at 0
        end
    else
        srcPorts = [];
    end

    if ~isempty(dstBlocks) && ~all(dstBlocks == -1)
        allDstBlockPorts = get_param(dstBlocks, 'PortHandles');
        if iscell(allDstBlockPorts)
            allDstBlockPorts = cell2mat(allDstBlockPorts);
        end

        dstPorts = zeros(size(allDstBlockPorts));
        for i = 1:length(allDstBlockPorts)
            dstBlockInports = allDstBlockPorts(i).Inport;
            dstPorts(i) = dstBlockInports(dstPortNums(i)+1); % Port indexes start at 0
        end
    else
        dstPorts = [];
    end
end