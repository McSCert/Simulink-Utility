function dsts = getDsts(object, varargin)
    % GETDSTS
    %
    % Input:
    %   object      Simulink object handle or full block name.
    %   varargin	Parameter-Value pairs as detailed below.
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
    %   Parameter: 'Method'
    %   Value:  'NextObject' - Gets the immediate proceding
    %               Simulink objects.
    %           'OldGetDsts' - (Default) - Gets Dsts using an old approach
    %               which essentially sought the first handle found on the
    %               next block. NextObject will be default in later
    %               versions.
    %           'ReturnSameType' - Gets the proceding objects of the same
    %               type as the input object.
    %           'RecurseUntilTypes' - 
    %   Parameter: 'RecurseUntilTypes'
    %   Value:
    %
    % Output:
    %       dsts    Vector of destination objects.
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
    
    % Get immediate destinations
    type = get_param(object, 'Type');
    switch type
        case 'block'
            bType = get_param(object, 'BlockType');
            block = get_param(object, 'Handle');
            switch bType
                case 'Outport'
                    switch ExitSubsystems
                        case 'off'
                            dsts = [];
                        case 'on'
                            % Destination is the corresponding outport port
                            % of the parent SubSystem if it exists.
                            outportBlock = block;
                            dsts = outBlock2outPort(outportBlock);
                        otherwise
                            error('Something went wrong.')
                    end
                case {'Goto', 'DataStoreWrite', 'SubSystem'}
                    switch IncludeImplicit
                        case 'off'
                            dsts = getPorts(block, 'Out');
                        case 'on'
                            switch bType
                                case 'Goto'
                                    % Get corresponding From blocks
                                    goto = block;
                                    dsts = goto2from(goto);
                                case 'DataStoreWrite'
                                    % Get corresponding Data Store Read blocks
                                    dsw = block;
                                    dsts = dsw2dsrs(dsw);
                                case 'SubSystem'
                                    
                                    % Get explicit destinations from the block's output ports
                                    dstsOut = getPorts(block, 'Out');
                                    
                                    %
                                    sys = block;
                                    
                                    % Get implicit destinations from Gotos
                                    gotos = find_system(sys, 'BlockType', 'Goto');
                                    dstsGoto = [];
                                    for i = 1:length(gotos)
                                        froms = goto2from(gotos{i});
                                        dstsGoto(end+1) = [dstsGoto, froms];
                                    end
                                    
                                    % Get implicit sources from Data Store Reads
                                    dsws = find_system(sys, 'BlockType', 'DataStoreWrite');
                                    srcsDsw = [];
                                    for i = 1:length(dsws)
                                        dsrs = dsw2dsrs(dsws{i});
                                        srcsDsw(end+1) = [srcsDsw, dsrs];
                                    end
                                    srcsDsw = unique(srcsDsw); % No need for duplicates

                                    dsts = [dstsOut, dstsGoto, srcsDsw];
                                otherwise
                                    error('Something went wrong.')
                            end
                        otherwise
                            error('Something went wrong.')
                    end
                otherwise
                    dsts = getPorts(block, 'Out');
            end
        case 'port'
            pType = get_param(object, 'PortType');
            switch pType
                case 'outport'
                    outpport = object;
                    line = get_param(outpport, 'Line');
                    if line == -1
                        % No line connected at port
                        dsts = [];
                    else
                        dsts = line;
                    end
                otherwise
                    inputPort = object;
                    parentBlock = get_param(inputPort, 'Parent');
                    bType = get_param(parentBlock, 'BlockType');
                    switch bType
                        case 'SubSystem'
                            switch EnterSubsystems
                                case 'off'
                                    dsts = parentBlock;
                                case 'on'
                                    if strcmp(get_param(inputPort, 'PortType'), 'inport')
                                    % Source is the corresponding inport
                                    % block of the SubSystem.
                                    dsts = inport2inBlock(inputPort);
                                    else
                                        error('This function does not handle ports other than in/outport yet.')
                                    end
                                otherwise
                                    error('Something went wrong.')
                            end
                        otherwise
                            dsts = parentBlock;
                    end
            end
        case 'line'
            line = object;
            inputPort = get_param(line, 'DstPortHandle');
            if inputPort == -1
                % No connection to destination port
                dsts = [];
            else
                dsts = inputPort;
            end
        case 'annotation'
            % Annotations don't pass signals
            dsts = [];
        otherwise
            error('Unexpected object type.')
    end
    
    switch Method
        case lower('NextObject')
            % Done
        case lower('OldGetDsts')
            tmpdsts = [];
            for i = 1:length(dsts)
                dst_type = get_param(dsts(i), 'Type');
                switch dst_type
                    case 'block'
                        tmpdsts = [tmpdsts, dsts(i)];
                    case 'port'
                        src_pType = get_param(dsts(i), 'PortType');
                        switch src_pType
                            case 'outport'
                                tmpdsts = [tmpdsts, getDsts(dsts(i), 'Method', Method)];
                            otherwise
                                tmpdsts = [tmpdsts, dsts(i)];
                        end
                    case 'line'
                        tmpdsts = [tmpdsts, getSrcs(dsts(i), 'Method', Method)];
                    case 'annotation'
                        % Done
                    otherwise
                        error('Unexpected object type.')
                end
            end
            dsts = unique(tmpdsts);
            dsts = inputToCell(dsts);
        case lower('RecurseUntilTypes')
            tmpdsts = [];
            for i = 1:length(dsts)
                dst_type = get_param(dsts(i), 'Type');
                switch dst_type
                    case {'block', 'line', 'annotation'}
                        dst_RecurseUntilType = dst_type;
                    case 'port'
                        if any(strcmp(dst_type, RecurseUntilTypes))
                            dst_RecurseUntilType = dst_type;
                        else
                            src_pType = get_param(dsts(i), 'PortType');
                            dst_RecurseUntilType = src_pType;
                        end
                    otherwise
                        error('Unexpected object type.')
                end
                
                if any(strcmp(dst_RecurseUntilType, RecurseUntilTypes))
                    tmpdsts = [tmpdsts, dsts(i)];
                else
                    tmpdsts = [tmpdsts, getDsts(dsts(i), 'Method', Method, 'RecurseUntilTypes', RecurseUntilTypes)];
                end
            end
            dsts = unique(tmpdsts);
        case lower('ReturnSameType')
            tmpdsts = [];
            cont = true;
            while cont
                cont = false;
                for i = length(dsts):-1:1
                    dst_type = get_param(dsts(i), 'Type');
                    if strcmp(type,dst_type)
                        tmpdsts = [tmpdsts, dsts(i)];
                        dsts(i) = [];
                    else
                        dsts = [dsts, getSrcs(dsts(i), 'Method', 'NextObject')];
                        dsts(i) = [];
                        cont = true;
                    end
                end
            end
            dsts = unique(tmpdsts);
        otherwise
            error('Something went wrong.')
    end
end

function outPort = outBlock2outPort(outBlock)
    outPort = inoutblock2subport(outBlock);
    assert(length(outPort) <= 1)
end

function inBlock = inport2inBlock(inport)
    inBlock = subport2inoutblock(inport);
    assert(length(inBlock) == 1)
end

function dsr = dsw2dsrs(dsw)
    % Finds Data Store Read blocks that correspond to a given Data Store
    % Write
    
    dsr = inputToNumeric(findReadsInScope(dsw));
end

function from = goto2from(goto)
    % Finds From blocks that correspond to a given Goto
    
    from = inputToNumeric(findFromsInScope(goto));
end