function dsts = getDsts(object, varargin)
    % GETDSTS Gets the next destination(s) of a port or block.
    % For Data Store Writes, the destinations are the corresponding Read
    % blocks.
    % For Gotos, the destinations are the corresponding From blocks.
    % For all other blocks, b, the destinations are the destinations of the
    % output ports of b.
    % TODO: SubSystems should be treated differently (implicit interface
    % and they can be entered or not).
    % For output ports, o, the destinations are the input ports connected to
    % via signal line from o.
    % For input ports (includes trigger ports and the like), i, the destination
    % is the block to which it belongs.
    %
    % Input:
    %   object      Can be either the name or the handle of a block or a
    %                   		port handle.
    %   varargin    Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'IncludeImplicit' - When on, this indicates that
    %       implicit dataflow connections will be used to determine
    %       destinations. When off, data store writes and gotos will not
    %       have destinations.
    %   Value: 'on' - (Default)
    %          'off'
    %	Parameter: 'exitSubsystems' - When on, this indicates that the
    %       destination of an outport block is the corresponding outport
    %       port of the subsystem block that it belongs to if any. When
    %       off, outports will not have destinations.
    %   Value: 'on'
    %          'off' - (Default)
    %
    %   Output:
    %       dsts    Cell array of destinations.
    
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
        if any(strcmp(get_param(object, 'BlockType'), {'DataStoreWrite', 'Goto'}))
            if strcmp(includeImplicit, 'on')
                if strcmp(get_param(object, 'BlockType'), 'DataStoreWrite')
                    block = getfullname(object);
                    dsts = findReadsInScope(block);
                elseif strcmp(get_param(object, 'BlockType'), 'Goto')
                    block = getfullname(object);
                    dsts = findFromsInScope(block);
                else
                    error('Something went wrong.')
                end
            else
                dsts = {};
            end
        elseif strcmp(get_param(object, 'BlockType'), 'Outport')
            if strcmp(exitSubsystems, 'on')
                dsts = inoutblock2subport(object);
            else
                dsts = {};
            end
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