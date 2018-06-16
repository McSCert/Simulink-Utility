function srcs = getSrcs(object, varargin)
    % GETSRCS
    %
    % Input:
    %   object      Simulink object handle or full block name.
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
    %   Parameter: 'Method'
    %   Value:  'NextObject' - Gets the immediate preceding
    %               Simulink object.
    %           'OldGetSrcs' - (Default) - Gets Srcs using an old approach
    %               which essentially sought the first handle found on the
    %               next block. NextObject will be default in later
    %               versions.
    %           'ReturnSameType' - Gets the preceding objects of the same
    %               type as the input object.
    %           'RecurseUntilTypes' - 
    %   Parameter: 'RecurseUntilTypes'
    %   Value:
    %
    % Output:
    %       srcs    Vector of source objects.
    %
    
    % Handle parameter-value pair inputs
    IncludeImplicit = 'on';
    ExitSubsystems = 'on';
    EnterSubsystems = 'on';
    Method = 'OldGetSrcs';
    RecurseUntilTypes = {'block','line','port','annotation'}; % Can specify specific port types instead
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('IncludeImplicit')
                assert(any(strcmpi(value,{'on','off'})))
                IncludeImplicit = value;
            case lower('ExitSubsystems')
                assert(any(strcmpi(value,{'on','off'})))
                ExitSubsystems = value;
            case lower('EnterSubsystems')
                assert(any(strcmpi(value,{'on','off'})))
                EnterSubsystems = value;
            case lower('Method')
                assert(any(strcmpi(value,{'NextObject', 'OldGetSrcs', 'ReturnSameType', 'RecurseUntilTypes'})))
                Method = value;
            case lower('RecurseUntilTypes')
                % Value is a combinatoin of 'block', 'line', 'port',
                % 'annotation' and any specific port types (which won't be
                % used if 'port' is also given).
                RecurseUntilTypes = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    % Get immediate sources
    type = get_param(object, 'Type');
    switch type
        case 'block'
            bType = get_param(object, 'BlockType');
            block = get_param(object, 'Handle');
            switch bType
                case 'Inport'
                    switch ExitSubsystems
                        case 'off'
                            srcs = [];
                        case 'on'
                            % Source is the corresponding inport port of
                            % the parent SubSystem if it exists.
                            inportBlock = block;
                            srcs = inBlock2inPort(inportBlock);
                        otherwise
                            error('Something went wrong.')
                    end
                case {'From', 'DataStoreRead', 'SubSystem'}
                    switch IncludeImplicit
                        case 'off'
                            srcs = getPorts(block, 'In');
                        case 'on'
                            switch bType
                                case 'From'
                                    % Get corresponding Goto block
                                    from = block;
                                    srcs = from2goto(from);
                                case 'DataStoreRead'
                                    % Get corresponding Data Store Write blocks
                                    dsr = block;
                                    srcs = dsr2dsws(dsr);
                                case 'SubSystem'
                                    
                                    % Get explicit sources from the block's input ports
                                    srcsIn = getPorts(block, 'In');
                                    
                                    %
                                    sys = block;
                                    
                                    % Get implicit sources from Froms
                                    froms = find_system(sys, 'BlockType', 'From');
                                    srcsFrom = [];
                                    for i = 1:length(froms)
                                        gotos = from2goto(froms{i});
                                        srcsFrom(i) = [srcsFrom, gotos];
                                    end
                                    srcsFrom = unique(srcsFrom); % No need for duplicates
                                    
                                    % Get implicit sources from Data Store Reads
                                    dsrs = find_system(sys, 'BlockType', 'DataStoreRead');
                                    srcsDsr = [];
                                    for i = 1:length(dsrs)
                                        dsws = dsr2dsws(dsrs{i});
                                        srcsDsr(end+1) = [srcsDsr, dsws];
                                    end
                                    srcsDsr = unique(srcsDsr); % No need for duplicates
                                    
                                    srcs = [srcsIn, srcsFrom, srcsDsr];
                                otherwise
                                    error('Something went wrong.')
                            end
                        otherwise
                            error('Something went wrong.')
                    end
                otherwise
                    srcs = getPorts(block, 'In');
            end
        case 'port'
            pType = get_param(object, 'PortType');
            switch pType
                case 'outport'
                    outport = object;
                    parentBlock = get_param(outport, 'Parent');
                    bType = get_param(parentBlock, 'BlockType');
                    switch bType
                        case 'SubSystem'
                            switch EnterSubsystems
                                case 'off'
                                    srcs = parentBlock;
                                case 'on'
                                    % Source is the corresponding outport
                                    % block of the SubSystem.
                                    srcs = outport2outBlock(outport);
                                otherwise
                                    error('Something went wrong.')
                            end
                        otherwise
                            srcs = parentBlock;
                    end
                otherwise
                    inputPort = object;
                    line = get_param(inputPort, 'Line');
                    if line == -1
                        % No line connected at port
                        srcs = [];
                    else
                        srcs = line;
                    end
            end
        case 'line'
            line = object;
            outport = get_param(line, 'SrcPortHandle');
            if outport == -1
                % No connection to source port
                srcs = [];
            else
                srcs = outport;
            end
        case 'annotation'
            % Annotations don't pass signals
            srcs = [];
        otherwise
            error('Unexpected object type.')
    end
    
    switch Method
        case lower('NextObject')
            % Done
        case lower('OldGetSrcs')
            tmpsrcs = [];
            for i = 1:length(srcs)
                src_type = get_param(srcs(i), 'Type');
                switch src_type
                    case 'block'
                        if strcmp(get_param(srcs(i), 'BlockType'), 
                        tmpsrcs = [tmpsrcs, srcs(i)];
                    case 'port'
                        src_pType = get_param(srcs(i), 'PortType');
                        switch src_pType
                            case 'outport'
                                tmpsrcs = [tmpsrcs, srcs(i)];
                            otherwise
                                tmpsrcs = [tmpsrcs, getSrcs(srcs(i), 'Method', Method)];
                        end
                    case 'line'
                        tmpsrcs = [tmpsrcs, getSrcs(srcs(i), 'Method', Method)];
                    case 'annotation'
                        % Done
                    otherwise
                        error('Unexpected object type.')
                end
            end
            srcs = unique(tmpsrcs);
            srcs = inputToCell(srcs);
        case lower('RecurseUntilTypes')
            tmpsrcs = [];
            for i = 1:length(srcs)
                src_type = get_param(srcs(i), 'Type');
                switch src_type
                    case {'block', 'line', 'annotation'}
                        src_RecurseUntilType = src_type;
                    case 'port'
                        if any(strcmp(src_type, RecurseUntilTypes))
                            src_RecurseUntilType = src_type;
                        else
                            src_pType = get_param(srcs(i), 'PortType');
                            src_RecurseUntilType = src_pType;
                        end
                    otherwise
                        error('Unexpected object type.')
                end
                
                if any(strcmp(src_RecurseUntilType, RecurseUntilTypes))
                    tmpsrcs = [tmpsrcs, srcs(i)];
                else
                    tmpsrcs = [tmpsrcs, getSrcs(srcs(i), 'Method', Method, 'RecurseUntilTypes', RecurseUntilTypes)];
                end
            end
            srcs = unique(tmpsrcs);
        case lower('ReturnSameType')
            tmpsrcs = [];
            cont = true;
            while cont
                cont = false;
                for i = length(srcs):-1:1
                    src_type = get_param(srcs(i), 'Type');
                    if strcmp(type,src_type)
                        tmpsrcs = [tmpsrcs, srcs(i)];
                        srcs(i) = [];
                    else
                        srcs = [srcs, getSrcs(srcs(i), 'Method', 'NextObject')];
                        srcs(i) = [];
                        cont = true;
                    end
                end
            end
            srcs = unique(tmpsrcs);
        otherwise
            error('Something went wrong.')
    end
end

function inPort = inBlock2inPort(inBlock)
    inPort = inoutblock2subport(inBlock);
    assert(length(inPort) <= 1)
end

function outBlock = outport2outBlock(outport)
    outBlock = subport2inoutblock(outport);
    assert(length(outBlock) == 1)
end

function dsw = dsr2dsws(dsr)
    % Finds Data Store Write blocks that correspond to a given Data Store
    % Read
    
    dsw = inputToNumeric(findWritesInScope(dsr));
end

function goto = from2goto(from)
    gotoInfo = get_param(from, 'GotoBlock');
    goto = gotoInfo.handle;
    assert(length(gotoInfo) <= 1)
    assert(length(goto) <= 1)
end