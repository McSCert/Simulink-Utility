function srcs = getSrcs(object, varargin)
    % GETSRCS Gets the last source(s) of a port or block.
    % For Data Store Reads, the sources are the corresponding Write blocks.
    % For Froms, the source is the corresponding Goto block.
    % For all other blocks, b, the sources are the sources of the inport
    % ports of b.
    % TODO: SubSystems should be treated differently (implicit interface
    % and they can be entered or not).
    % For input ports (includes trigger ports and the like), i, the source
    % is the outport port connected to via signal line to i.
    % For outport ports, o, the source is the block to which it belongs.
    %
    % Input:
    %   object      Can be either the name or the handle of a block or a
    %               port handle.
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'IncludeImplicit'
    %   Value:  'on' - (Default) Implicit dataflow connections (through Data
    %               Store Reads and Froms) will be used to determine
    %               sources.
    %           'off' - Implicit dataflow connections will not have sources.
    %	Parameter: 'ExitSubsystems'
    %   Value:  'on' - The source of an Inport block is the corresponding
    %               inport port of the Subsystem block that it belongs to
    %               if any.
    %           'off' - (Default) Inport blocks will not have sources.
    %	Parameter: 'EnterSubsystems'
    %   Value:  'on' - The source of a Subsystem block's outport port is the
    %               corresponding Outport block inside the Subsystem.
    %           'off' - (Default) The source of Subsystem block outport
    %               ports will be determined in the same way as other
    %               outport ports (i.e. the Subsystem block will be the
    %               source).
    %
    % Output:
    %       srcs    Cell array of sources.
    
    % Handle parameter-value pair inputs
    IncludeImplicit = 'on';
    ExitSubsystems = 'off';
    EnterSubsystems = 'off';
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('IncludeImplicit')
                assert(any(strcmp(value,{'on','off'})))
                IncludeImplicit = value;
            case lower('ExitSubsystems')
                assert(any(strcmp(value,{'on','off'})))
                ExitSubsystems = value;
            case lower('EnterSubsystems')
                assert(any(strcmp(value,{'on','off'})))
                EnterSubsystems = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    %
    if strcmp(get_param(object, 'Type'), 'block')
        if any(strcmp(get_param(object, 'BlockType'), {'DataStoreRead', 'From'}))
            if strcmp(IncludeImplicit, 'on')
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
            if strcmp(ExitSubsystems, 'on')
                srcs = inoutblock2subport(object);
            else
                srcs = {};
            end
        else
            srcs = num2cell(getSrcPorts(object));
        end
    elseif strcmp(get_param(object, 'Type'), 'port')
        if strcmp(get_param(object, 'PortType'), 'outport')
            if strcmp(EnterSubsystems, 'on') ...
                    && strcmp(get_param(object, 'BlockType'), 'SubSystem')
                src = subport2inoutblock(object);
                srcs = {get_param(src, 'Handle')};
            else
                srcs = get_param(object, 'Parent');
            end
        else
            srcs = num2cell(getSrcPorts(object));
        end
    else
        error(['Error: ' mfilename ' expected object type to be ''block'' or ''port''.'])
    end
end