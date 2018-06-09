function srcs = getSrcs(object, varargin)
    % GETSRCS Gets the last source(s) of a port or block.
    % For Data Store Reads, the sources are the corresponding Write blocks.
    % For Froms, the source is the corresponding Goto block.
    % For all other blocks, b, the sources are the sources of the input
    % ports of b.
    % TODO: SubSystems should be treated differently (implicit interface
    % and they can be entered or not).
    % For input ports (includes trigger ports and the like), i, the source
    % is the output port connected to via signal line to i.
    % For output ports, o, the source is the block to which it belongs.
    %
    % Input:
    %   object      Can be either the name or the handle of a block or a
    %               port handle.
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'IncludeImplicit' - When on, this indicates that
    %       implicit dataflow connections will be used to determine
    %       sources. When off, data store reads and froms will not have
    %       sources.
    %   Value: 'on' - (Default)
    %          'off'
    %	Parameter: 'exitSubsystems' - When on, this indicates that the
    %       source of an inport block is the corresponding inport port of
    %       the subsystem block that it belongs to if any. When off,
    %       inports will not have sources.
    %   Value: 'on'
    %          'off' - (Default)
    %
    % Output:
    %       srcs    Cell array of sources.
    
    includeImplicit = 'on';
    exitSubsystems = 'off';
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case 'includeimplicit'
                assert(any(strcmp(value,{'on','off'})))
                includeImplicit = value;
            case 'exitsubsystems'
                assert(any(strcmp(value,{'on','off'})))
                exitSubsystems = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    if strcmp(get_param(object, 'Type'), 'block')
        if any(strcmp(get_param(object, 'BlockType'), {'DataStoreRead', 'From'}))
            if strcmp(includeImplicit, 'on')
                if strcmp(get_param(object, 'BlockType'), 'DataStoreRead')
                    block = getfullname(object);
                    srcs = findWritesInScope(block);
                elseif strcmp(get_param(object, 'BlockType'), 'From')
                    block = getfullname(object);
                    srcs = findGotosInScope(block);
                else
                    error('Something went wrong.')
                end
            else
                srcs = {};
            end
        elseif strcmp(get_param(object, 'BlockType'), 'Inport')
            if strcmp(exitSubsystems, 'on')
                srcs = inoutblock2subport(object);
            else
                srcs = {};
            end
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