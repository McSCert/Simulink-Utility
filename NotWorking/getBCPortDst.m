function dstBlocks = getBCPortDst(address, busCreator, bcPort)
% GETBCPORTDST Determine the next block for a signal going into a Bus
% Creator. Returns an empty array for an outport signal.

    portType = bcPort.PortType;
    switch portType
        case 'outport'
            dstBlocks = [];
        case 'inport'
            dstBlocks = [];
            busSelectors = findBusSelectors(address, busCreator);
            if ~isempty(busSelectors)
                busSelectors = cellstr(busSelectors);
            end
            for i = 1:length(busSelectors)
                bsOutports = getSrcPorts(address, busSelectors(i));
                if ~isempty(bsOutports)
                    for j = 1:length(bsOutports)
                        % Following should be true at most once for a Bus
                        % Selector's outports
                        tmpOutport = get(bsOutports(j));

                        inSigs = get_param(busSelectors(i), 'InputSignals');
                        inSigs = inSigs{1};
                        if isempty(inSigs)
                            isRightPort = 0;
                        else
                            inPortNum = inSigs(bcPort.PortNumber);
                            outSigs = strsplit(get_param(busSelectors{i}, 'OutputSignals'), ',');
                            outPortNum = outSigs(tmpOutport.PortNumber);
                            isRightPort = tmpOutport.PortNumber == bcPort.PortNumber;
                        end
                        if isRightPort
                            dstBlocks = [dstBlocks;getPortDst(address, bsOutports(j))];
                        end
                    end
                end
            end
        otherwise
            exceptionStr = 'PortType was expected to be "outport" or "inport".';
            error(exceptionStr);
    end
end