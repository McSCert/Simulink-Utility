function srcs = getSrcs(object)
    % GETSRCS Gets the last source(s) of a port or block. 
    % For Data Store Reads, the sources are the corresponding Write blocks.
    % For Froms, the sources are the corresponding Goto blocks.
    % For all other blocks, b, the sources are the sources of the input
    % ports of b.
    % TODO: SubSystems should be treated differently (implicit interface).
    % For input ports (includes trigger ports and the like), i, the sources
    % are the output ports connected to via signal line to i.
    % For output ports, o, the source is the block to which it belongs.
    %
    %   Input:
    %       object      Can be either the name or the handle of a block or a
    %                   port handle.
    %
    %   Output:
    %       srcs        Cell array of sources.
    
    if strcmp(get_param(object, 'Type'), 'block')
        if strcmp(get_param(object, 'BlockType'), 'DataStoreRead')
            block = getfullname(object);
            srcs = findWritesInScope(block);
        elseif strcmp(get_param(object, 'BlockType'), 'From')
            block = getfullname(object);
            srcs = findGotosInScope(block);
            assert(length(srcs) == 1, 'Error: Froms should have only one source.')
        else
            srcs = num2cell(getSrcPorts(object));
        end
    elseif strcmp(get_param(object, 'Type'), 'port')
        if strcmp(get_param(object, 'PortType'), 'outport')
            srcs = get_param(object, 'Parent');
        else
            srcs = num2cell(getSrcPorts(object));
        end
    else
        error(['Error: ' mfilename 'expected object type to be ''block'' or ''port'''])
    end
end