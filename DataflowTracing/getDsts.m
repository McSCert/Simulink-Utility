function dsts = getDsts(object, varargin)
    % GETDSTS Get destination object for given object.
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
    Method = lower('OldGetDsts');
    RecurseUntilTypes = {'Until', {'block','line','port','annotation'}}; % Can specify specific port types or 'ins' (for input port types) instead
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
                assert(any(strcmpi(value,{'NextObject', 'OldGetDsts', 'ReturnSameType', 'RecurseUntilTypes'})))
                Method = value;
            case lower('RecurseUntilTypes')
                % Value is a combinatoin of 'block', 'line', 'port',
                % 'annotation', any specific port types (which won't be
                % used if 'port' is also given), or 'ins' which refers to
                % any input port types (this also won't be used if 'port'
                % is also given).
                assert(iscell(value), '''RecurseUntilTypes'' parameter expects a cell array.')
                assert(~isempty(value), '''RecurseUntilTypes'' parameter expects a non-empty cell array (else there is no end condintion on the recursion).')
                RecurseUntilTypes = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    % Get immediate destinations
    type = get_param(object, 'Type');
    switch type
        case 'block'
            bType = getTypeOfBlock(object);
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
                                    
                                    if isRegularSubSystem(block)
                                        % Get explicit destinations from the block's output ports
                                        dstsOut = getPorts(block, 'Out');
                                        
                                        %
                                        sys = block;
                                        
                                        % Get implicit destinations from Gotos
                                        gotos = find_system(sys, ...
                                            'LookUnderMasks','All','IncludeCommented','on','Variants','AllVariants', ...
                                            'BlockType', 'Goto');
                                        dstsGoto = [];
                                        for i = 1:length(gotos)
                                            froms = goto2from(gotos(i));
                                            dstsGoto = [dstsGoto, froms];
                                        end
                                        
                                        % Get implicit sources from Data Store Reads
                                        dsws = find_system(sys, ...
                                            'LookUnderMasks','All','IncludeCommented','on','Variants','AllVariants', ...
                                            'BlockType', 'DataStoreWrite');
                                        srcsDsw = [];
                                        for i = 1:length(dsws)
                                            dsrs = dsw2dsrs(dsws(i));
                                            srcsDsw = [srcsDsw, dsrs];
                                        end
                                        srcsDsw = unique(srcsDsw); % No need for duplicates
                                        
                                        dsts = [dstsOut, dstsGoto, srcsDsw];
                                    else
                                        % Pretend it was an unrecognized block type
                                        dsts = getPorts(block, 'Out');
                                    end
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
                    parentBlock = get_param(get_param(inputPort, 'Parent'), 'Handle');
                    bType = get_param(parentBlock, 'BlockType');
                    switch bType
                        case 'SubSystem'
                            if isRegularSubSystem(parentBlock)
                                switch EnterSubsystems
                                    case 'off'
                                        dsts = parentBlock;
                                    case 'on'
                                        switch get_param(inputPort, 'PortType')
                                            case 'inport'
                                                % Source is the corresponding inport
                                                % block of the SubSystem.
                                                dsts = inport2inBlock(inputPort);
                                            case 'trigger'
                                                dsts = trigPort2trigBlock(inputPort);
                                            case 'ifaction'
                                                dsts = ifactionPort2actionBlock(inputPort);
                                            otherwise
                                                error(['This function does not handle ports of type ' get_param(inputPort, 'PortType') ' yet.'])
                                        end
                                    otherwise
                                        error('Something went wrong.')
                                end
                            else
                                % Pretend it was an unrecognized block type
                                dsts = parentBlock;
                            end
                        otherwise
                            dsts = parentBlock;
                    end
            end
        case 'line'
            line = object;
            inputPort = get_param(line, 'DstPortHandle')';
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
                        dst_pType = get_param(dsts(i), 'PortType');
                        switch dst_pType
                            case 'outport'
                                tmpdsts = [tmpdsts, getDsts(dsts(i), ...
                                    'IncludeImplicit', IncludeImplicit, ...
                                    'ExitSubsystems', ExitSubsystems, ...
                                    'EnterSubsystems', EnterSubsystems, ...
                                    'Method', Method)];
                            otherwise
                                tmpdsts = [tmpdsts, dsts(i)];
                        end
                    case 'line'
                        tmpdsts = [tmpdsts, getDsts(dsts(i), ...
                            'IncludeImplicit', IncludeImplicit, ...
                            'ExitSubsystems', ExitSubsystems, ...
                            'EnterSubsystems', EnterSubsystems, ...
                            'Method', Method)];
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
                            dst_pType = get_param(dsts(i), 'PortType');
                            if ~strcmp(dst_pType, 'outport') && any(strcmp('ins', RecurseUntilTypes))
                                dst_RecurseUntilType = 'ins';
                            else
                                dst_RecurseUntilType = dst_pType;
                            end
                        end
                    otherwise
                        error('Unexpected object type.')
                end
                
                if any(strcmp(dst_RecurseUntilType, RecurseUntilTypes))
                    tmpdsts = [tmpdsts, dsts(i)];
                else
                    tmpdsts = [tmpdsts, getDsts(dsts(i), ...
                        'IncludeImplicit', IncludeImplicit, ...
                        'ExitSubsystems', ExitSubsystems, ...
                        'EnterSubsystems', EnterSubsystems, ...
                        'Method', Method, 'RecurseUntilTypes', RecurseUntilTypes)];
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
                        dsts = [dsts, getDsts(dsts(i), ...
                            'IncludeImplicit', IncludeImplicit, ...
                            'ExitSubsystems', ExitSubsystems, ...
                            'EnterSubsystems', EnterSubsystems, ...
                            'Method', 'NextObject')];
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
    inBlock = inputToNumeric(subport2inoutblock(inport));
    assert(length(inBlock) == 1)
end

function dsts = trigPort2trigBlock(triggerPort)
    subsystem = get_param(triggerPort, 'Parent');
    dsts = find_system(subsystem, 'FindAll', 'on', 'Type', 'Block', 'BlockType', 'TriggerPort');
    
    assert(length(dsts) == 1)
end

function dsts = ifactionPort2actionBlock(ifactionPort)
    subsystem = get_param(ifactionPort, 'Parent');
    dsts = find_system(subsystem, 'FindAll', 'on', 'Type', 'Block', 'BlockType', 'ActionPort');
    
    assert(length(dsts) == 1)
end

function dsr = dsw2dsrs(dsw)
    % Finds Data Store Read blocks that correspond to a given Data Store
    % Write
    
    dsr = inputToNumeric(findReadsInScope({getfullname(dsw)}))';
end

function from = goto2from(goto)
    % Finds From blocks that correspond to a given Goto
    
    from = inputToNumeric(findFromsInScope(goto))';
end

function bType = getTypeOfBlock(block)
    % Gets block type
    bType = get_param(block, 'BlockType');
end
function bool = isRegularSubSystem(block)
    % Checks if there are objects inside the system
    
    % LookUnderMasks All will also enter MATLAB Function blocks without a mask
    blx = find_system(block,'LookUnderMasks','All','IncludeCommented','on','Variants','AllVariants');
    bool = length(blx) > 1;
end