classdef StaticLineId
    % Object that uniquely identifies a line. Can be used to find the handle of
    % a line across different sessions with a model.
    %
    % Example:
    %   Save persistent line identifiers as follows:
    %   >> lineIds = StaticLineId.lines2lineIds(gcls);
    %   Now you may close the model containing selected lines and reopen it
    %   later. Restore the line handles with:
    %   >> newLines = StaticLineId.lineIds2lines(lineIds)
    %
    
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
                
                desiredDstPorts = zeros(length(staticId.StaticDstPortIds), 1);
                for i = 1:length(staticId.StaticDstPortIds)
                    desiredDstPorts(i) = staticId.StaticDstPortIds{i}.getHandle;
                end
                
                isSameLine = (srcPort == desiredSrcPort) && all(sort(dstPorts) == sort(desiredDstPorts));
            end
        end
    end
    methods(Static)
        function lineIds = lines2lineIds(lines)
            % LINES2LINEIDS Convert vector of lines to cell array of
            % StaticLineId objects.
            
            lineIds = cell(1, length(lines));
            for i = 1:length(lines)
                lineIds{i} = StaticLineId(lines(i));
            end
        end
        
        function lines = lineIds2lines(lineIds)
            % LINEIDS2LINES Convert cell array of StaticLineId objects to vector
            % of lines.

            lines = zeros(length(lineIds), 1);
            for i = 1:length(lineIds)
                lines(i) = lineIds{i}.getHandle;
            end
        end
    end
end