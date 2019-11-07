classdef StaticLineId
    % Object that uniquely identifies a line. Can be used to find the handle of
    % a line across different sessions with a model.
    properties
        StaticSrcPortId     % Static port identifier for a port that acts as source for the line.
        StaticDstPortIds    % Cell array of static port identifiers for ports that act as destinations for the line.
    end
    methods
        function staticId = StaticLineId(handle)
            % Creates static line id given the current handle (dynamic id).
            
            srcPort = get_param(handle, 'SrcPortHandle');
            assert(length(srcPort) == 1)
            staticId.StaticSrcPortId = StaticPortId(srcPort);
            
            dstPorts = get_param(handle, 'DstPortHandle');
            staticId.StaticDstPortIds = cell(1, length(dstPorts));
            for i = 1:length(dstPorts)
                ph = dstPorts(i);
                staticId.StaticDstPortIds{i} = StaticPortId(ph);
            end
        end
        
        function handle = getHandle(staticId)
            srcPort = staticId.StaticSrcPortId.getHandle;
            
            lineFound = false; % Default.
            lines = get_param(srcPort, 'Line');
            while ~lineFound && ~isempty(lines)
                
                newLines = [];
                for i = 1:length(lines)
                    lh = lines(i);
                    isRightLine = checkLine(staticId, lh);
                    if isRightLine
                        handle = lh;
                        lineFound = true;
                        break
                    else
                        newLines = [newLines; get_param(lh, 'LineChildren')];
                    end
                end
                lines = newLines;
            end
            assert(lineFound)
        end
        
        function isSameLine = checkLine(staticId, line)
            srcPort = get_param(line, 'SrcPortHandle');
            dstPorts = get_param(line, 'DstPortHandle');
            
            if length(dstPorts) ~= length(staticId.StaticDstPortIds)
                isSameLine = false;
            else
                desiredSrcPort = staticId.StaticSrcPortId.getHandle;
                
                desiredDstPorts = zeros(1, length(staticId.StaticDstPortIds));
                for i = 1:length(staticId.StaticDstPortIds)
                    desiredDstPorts(i) = staticId.StaticDstPortIds{i}.getHandle;
                end
                
                isSameLine = srcPort == desiredSrcPort && all(sort(dstPorts) == sort(desiredDstPorts));
            end
        end
    end
end