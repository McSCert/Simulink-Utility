function dsts = getDsts(object)
    % GETDSTS Gets the next destination(s) of a port or block. 
    % For Data Store Writes, the destinations are the corresponding Read
    % blocks.
    % For Gotos, the destinations are the corresponding From blocks.
    % For all other blocks, b, the destinations are the destinations of the 
    % output ports of b.
    % TODO: SubSystems should be treated differently (implicit interface).
    % For output ports, o, the destinations are the input ports connected to
    % via signal line from o.
    % For input ports (includes trigger ports and the like), i, the destination 
    % is the block to which it belongs.
    %
    %   Input:
    %       object      Can be either the name or the handle of a block or a
    %                   port handle.
    %
    %   Output:
    %       dsts    Cell array of destinations.
    
    if strcmp(get_param(object, 'Type'), 'block')
        if strcmp(get_param(object, 'BlockType'), 'DataStoreWrite')
            block = getfullname(object);
            dsts = findReadsInScope(block);
        elseif strcmp(get_param(object, 'BlockType'), 'Goto')
            block = getfullname(object);
            dsts = findFromsInScope(block);
        else
            dsts = num2cell(getDstPorts(object));
        end
    elseif strcmp(get_param(object, 'Type'), 'port')
        if strcmp(get_param(object, 'PortType'), 'outport')
            dsts = num2cell(getDstPorts(object));
        else
            dsts = get_param(object, 'Parent');
        end
    else
        error(['Error: ' mfilename 'expected object type to be ''block'' or ''port'''])
    end
end