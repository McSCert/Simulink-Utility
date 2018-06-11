function dsts = getDsts(object, varargin)
    % GETDSTS Gets the next destination(s) of a port or block.
    % For Data Store Writes, the destinations are the corresponding Read
    % blocks.
    % For Gotos, the destinations are the corresponding From blocks.
    % For all other blocks, b, the destinations are the destinations of the
    % outport ports of b.
    % TODO: SubSystems should be treated differently (implicit interface
    % and they can be entered or not).
    % For outport ports, o, the destinations are the input ports (inports,
    % triggers, ifaction ports, etc.) connected to via signal line from o.
    % For input ports, i, the destination is the block to which it belongs.
    %
    % Input:
    %   object      Can be either the name or the handle of a block or a
    %               port handle.
    %   varargin    Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'IncludeImplicit'
    %   Value:  'on' - (Default) Implicit dataflow connections (through Data
    %               Store Writes and Gotos) will be used to determine
    %               destinations.
    %           'off' - Implicit dataflow connections will not have
    %               destinations.
    %	Parameter: 'ExitSubsystems'
    %   Value:  'on' - The destination of an Outport block is the corresponding
    %               outport port of the Subsystem block that it belongs to
    %               if any.
    %           'off' - (Default) Outport blocks will not have destinations.
    %	Parameter: 'EnterSubsystems'
    %   Value:  'on' - The destination of a Subsystem block's inport port
    %               is the corresponding Outport block inside the
    %               Subsystem.
    %           'off' - (Default) The destination of Subsystem block inport
    %               ports will be determined in the same way as other
    %               inport ports (i.e. the Subsystem block will be the
    %               destination).
    %
    %   Output:
    %       dsts    Cell array of destinations.
    
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
        if any(strcmp(get_param(object, 'BlockType'), {'DataStoreWrite', 'Goto'}))
            if strcmp(IncludeImplicit, 'on')
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
            if strcmp(ExitSubsystems, 'on')
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
            if strcmp(EnterSubsystems, 'on') ...
                    && strcmp(get_param(object, 'BlockType'), 'SubSystem') ...
                    && strcmp(get_param(object, 'PortType'), 'inport')
                dst = subport2inoutblock(object);
                dsts = {get_param(dst, 'Handle')};
            else
                dsts = get_param(object, 'Parent');
            end
        end
    else
        error(['Error: ' mfilename ' expected object type to be ''block'' or ''port''.'])
    end
end