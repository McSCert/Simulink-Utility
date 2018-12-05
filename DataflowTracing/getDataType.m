function [dataType, typeSource, dtStruct] = getDataType(obj, varargin)
    % GETDATATYPE Gets the data type of a Simulink object.
    %
    % Input:
    %   obj         A Simulink object handle or block full name or handle.
    %               Update: Function appears to handle all Simulink object
    %               types.
    %   varargin    Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %	Parameter: 'SystemDepth'
    %   Value:  The number of SubSystem layers above the current one that
    %       may be checked. Default: 0 - only information directly within
    %       the system containing the given output port may be used.
    %   Parameter: 'TraversalMap' - intended for recursive use to
    %       prevent infinite loops.
    %   Value:  containers.Map with keys as handles that have been
    %       traversed in attempt to find their datatype. Default:
    %       containers.Map().
    %
    % Output:
    %   dataType    Char array indicating the data type being sent from the
    %               given outport.
    %   typeSource  Handles of sources to the dataType.
    %   dtStruct    Cell array of structs with datatypes, sources, and
    %               corresponding object handles.
    %
    % Example:
    % % Display datatype(s) and source objects of those types
    % d = getDepthFromSys(bdroot,gcs);
    % [dt, ts] = getDataType(gcb, 'SystemDepth', d);
    % for i = 1:length(dt)
    %     dt{i}
    %     type = get_param(ts{i}, 'Type');
    %     if strcmp(type, 'port')
    %         get_param(ts{i}, 'Parent')
    %     else
    %         getfullname(ts{i})
    %     end
    % end
    
    % TODO:
    % - Look under model reference blocks
    % - Read Fcn blocks as Inherit: Auto (consider if this is correct first)
    % - Inherit: Inherit via internal rule of sum, product, switch blocks
    
    % Handle parameter-value pair inputs
    SystemDepth = 0;
    TraversalMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('SystemDepth')
                SystemDepth = value;
            case lower('TraversalMap')
                assert(isa(value, 'containers.Map'))
                TraversalMap = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    % Note: many of the functions in this file determine outputs dataType,
    % typeSource, and dtStruct, however whenever a new handle is being
    % checked for its datatype through the iterative approach of this file,
    % only getDataType or getSetOutDataType may be called.
    % This is to ensure that a handle is counted as being traversed only
    % once for each actual traversal.
    % In other words, other functions are called with a handle that is
    % already marked as traversed.
    % Thus only the two functions mentioned above actually implement checks
    % to do with traversal.
    % In the future, all traversal could be done in getDataType by
    % modifying the approach in getSetOutDataType somewhat.
    
    assert(~isempty(obj), 'First input must not be empty.')

    obj = get_param(obj, 'Handle');
    
    if isTraversed(obj, TraversalMap)
        [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
    else
        addTraversal(obj, TraversalMap);
        
        type = get_param(obj, 'Type');
        switch type
            case 'port'
                pType = get_param(obj, 'PortType');
                switch pType
                    case 'outport'
                        [dataType, typeSource, dtStruct] = getOutDataType(obj, SystemDepth, TraversalMap);
                    otherwise
                        % Get data type of source (if it exists)
                        srcs = getSrcs(obj, ...
                            'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                            'EnterSubsystems', 'on', 'Method', 'ReturnSameType');
                        [dataType, typeSource, dtStruct] = getDT_len_src_leq_1(obj, srcs, SystemDepth, TraversalMap);
                end
            case 'line'
                % Get data type of source (if it exists)
                srcs = getSrcs(obj, ...
                    'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                    'EnterSubsystems', 'on', 'Method', 'NextObject');
                [dataType, typeSource, dtStruct] = getDT_len_src_leq_1(obj, srcs, SystemDepth, TraversalMap);
            case 'block'
                bType = getTypeOfBlock(obj);
                sys = getObjSys(obj);
                topsys = getTopSys(sys, SystemDepth);
                switch bType
                    case 'Outport'
                        [dataType, typeSource, dtStruct] = getDataType_Aux(obj, SystemDepth, TraversalMap);
                    case {'Goto', 'DataStoreWrite'}
                        % Get data type of source
                        srcs = getSrcs(obj, ...
                            'IncludeImplicit', 'off', 'ExitSubsystems', 'off', ...
                            'EnterSubsystems', 'off', 'Method', 'NextObject');
                        assert(length(srcs) == 1)
                        [dataType, typeSource, dtStruct] = getDataType(srcs(1), 'SystemDepth', SystemDepth, 'TraversalMap', TraversalMap);
                        dtStruct = [{struct( ...
                            'handle', obj, ...
                            'datatype', dataType, ...
                            'typesource', typeSource)}, ...
                            dtStruct];
                    case 'From'
                        % Get data type of source (if it exists)
                        srcs = getSrcs(obj, ...
                            'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                            'EnterSubsystems', 'on', 'Method', 'NextObject');
                        assert(length(srcs) <= 1)
                        if isempty(srcs)
                            [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
                        else
                            newDepth = getDepthFromSys(topsys, getObjSys(srcs(1)));
                            if newDepth < 0
                                [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
                            else
                                [dataType, typeSource, dtStruct] = getDataType(srcs(1), 'SystemDepth', newDepth, 'TraversalMap', TraversalMap);
                                dtStruct = [{struct( ...
                                    'handle', obj, ...
                                    'datatype', dataType, ...
                                    'typesource', typeSource)}, ...
                                    dtStruct];
                            end
                        end
                    case 'DataStoreRead'
                        % Type is type of source, but read may have multiple
                        % writes
                        srcs = getSrcs(obj, ...
                            'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                            'EnterSubsystems', 'on', 'Method', 'NextObject');
                        srcWrite = pickSrc(srcs, topsys);
                        [dataType, typeSource, dtStruct] = getDT_len_src_leq_1(obj, srcWrite, SystemDepth, TraversalMap);
                    otherwise
                        % Get data types of outports (if they exist)
                        dsts = getDsts(obj, ...
                            'IncludeImplicit', 'off', 'ExitSubsystems', 'off', ...
                            'EnterSubsystems', 'off', 'Method', 'RecurseUntilTypes', ...
                            'RecurseUntilTypes', {'Outport'});
                        if isempty(dsts)
                            [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
                        else
                            % All dsts should be outports
                            for i = 1:length(dsts)
                                assert(strcmp(get_param(dsts(i), 'Type'), 'port'))
                                assert(strcmp(get_param(dsts(i), 'PortType'), 'outport'))
                            end
                            
                            [dataType, typeSource, dtStruct] = getSetOutDataType(dsts, SystemDepth, TraversalMap);
                            dtStruct = [{struct( ...
                                'handle', obj, ...
                                'datatype', dataType, ...
                                'typesource', typeSource)}, ...
                                dtStruct];
                        end
                end
            case 'annotation'
                [dataType, typeSource, dtStruct] = getDT_emp_src(obj, '');
            otherwise
                error('Unexpected object type.')
        end
    end
end
function [dataType, typeSource, dtStruct] = getSetOutDataType(out_set, SystemDepth, TraversalMap)
    % Get data types for a set of outports
    % out_set is a vector of outports
    
    assert(~isempty(out_set)) % Because there must always be a typeSource
    
    dataType = {};
    typeSource = {};
    dtStruct = {};
    for i = 1:length(out_set)
        if isTraversed(out_set(i), TraversalMap)
            [dataType, typeSource, dtStruct] = getDT_emp_src(out_set(i));
        else
            addTraversal(out_set(i), TraversalMap);
            
            [dt, ts, dts] = getOutDataType(out_set(i), SystemDepth, TraversalMap);
            dataType = [dataType, dt];
            typeSource = [typeSource, ts];
            dtStruct = [dtStruct, dts];
        end
    end
end
function [dataType, typeSource, dtStruct] = getDataType_Aux(outBlock, SystemDepth, TraversalMap)
    % Call this function for Outport blocks
    
    block = outBlock;
    obj = outBlock;
    
    blockParams = get_param(block, 'ObjectParameters');
    if any(strcmp('OutDataTypeStr', fieldnames(blockParams))) % has OutDataTypeStr parameter
        dataType = {get_param(block, 'OutDataTypeStr')};
        if strcmp(dataType{1}, 'Inherit: auto')
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'off', 'ExitSubsystems', 'on', ...
                'EnterSubsystems', 'off', 'Method', 'NextObject');
            assert(length(srcs) == 1) % This may not be correct, but need to see an example that breaks this to figure out how to handle it
            
            [dataType, typeSource, dtStruct] = getDataType(srcs(1), 'SystemDepth', SystemDepth, 'TraversalMap', TraversalMap);
            dtStruct = [{struct( ...
                'handle', obj, ...
                'datatype', dataType, ...
                'typesource', typeSource)}, ...
                dtStruct];
        elseif any(strcmp(dataType{1}, {'Inherit: Same as first input', 'Inherit: Same as input'}))
            % Get first input
            ins = getPorts(block, 'Inport');
            for i = 1:length(ins)
                if get_param(ins(i), 'PortNumber') == 1
                    firstIn = ins(i);
                    break
                end
            end
            assert(logical(exist('firstIn', 'var')))
            
            % Get data type of the first input
            [dataType, typeSource, dtStruct] = getDataType(firstIn, 'SystemDepth', SystemDepth, 'TraversalMap', TraversalMap);
            dtStruct = [{struct( ...
                'handle', obj, ...
                'datatype', dataType, ...
                'typesource', typeSource)}, ...
                dtStruct];
        else
            typeSource = {obj};
            dtStruct = {struct( ...
                'handle', obj, ...
                'datatype', dataType, ...
                'typesource', typeSource)};
        end
    elseif any(strcmp('OutputArgumentSpecifications', fieldnames(blockParams))) % has OutputArgumentSpecifications parameter
        outArgSpec = get_param(block, 'OutputArgumentSpecifications');
        tmpDataType = regexp(outArgSpec, '^(.*)\((.*)\)', 'tokens');
        dataType = tmpDataType{1}(1);
        typeSource = {obj};
        dtStruct = {struct( ...
            'handle', obj, ...
            'datatype', dataType, ...
            'typesource', typeSource)};
    else
        % Unsupported / can't be determined
        [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
    end
end

function [dataType, typeSource, dtStruct] = getOutDataType(obj, SystemDepth, TraversalMap)
    % Check block parameters for information about this
    % port.
    
    % To ensure no infinite loops, getOutDataType is not allowed to recurse
    % on the main function, getDataType, with a block because most block
    % types use their outports to determine data type (since a block itself
    % does not actually have a data type of its own).
    
    assert(isTraversed(obj, TraversalMap))
    
    block = get_param(obj, 'Parent');
    
    bType = getTypeOfBlock(block);
    sys = getObjSys(block);
    topsys = getTopSys(sys, SystemDepth);
    switch bType
        case 'SubSystem'
            if isRegularSubSystem(block)
                srcs = getSrcs(obj, ...
                    'IncludeImplicit', 'off', 'ExitSubsystems', 'off', ...
                    'EnterSubsystems', 'on', 'Method', 'NextObject');
                assert(length(srcs) == 1)
                assert(strcmp(get_param(srcs(1),'Type'), 'block'))
                assert(strcmp(get_param(srcs(1),'BlockType'), 'Outport'))
                newDepth = getDepthFromSys(topsys, getObjSys(srcs(1)));
                assert(SystemDepth+1 == newDepth)
                
                [dataType, typeSource, dtStruct] = getDataType(srcs(1), 'SystemDepth', SystemDepth+1, 'TraversalMap', TraversalMap);
                dtStruct = [{struct( ...
                    'handle', obj, ...
                    'datatype', dataType, ...
                    'typesource', typeSource)}, ...
                    dtStruct];
            else
                [dataType, typeSource, dtStruct] = getOutDataType_Aux(obj, SystemDepth, TraversalMap, block);
            end
        case 'BusCreator'
            % Assume that it can't be determined
            % TODO:
            % Represent an array of types.
            
            [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
        case 'DataStoreRead'
            % Type is type of source, but read may have multiple
            % writes
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                'EnterSubsystems', 'on', 'Method', 'ReturnSameType');
            srcWrite = pickSrc(srcs, topsys);
            [dataType, typeSource, dtStruct] = getDT_len_src_leq_1(obj, srcWrite, SystemDepth, TraversalMap);
        case 'From'
            % Get data type of source (if it exists)
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                'EnterSubsystems', 'on', 'Method', 'ReturnSameType');
            assert(length(srcs) <= 1)
            
            if isempty(srcs)
                [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
            else
                newDepth = getDepthFromSys(topsys, getObjSys(srcs(1)));

                if newDepth < 0
                    [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
                else
                    [dataType, typeSource, dtStruct] = getDataType(srcs(1), 'SystemDepth', newDepth, 'TraversalMap', TraversalMap);
                    dtStruct = [{struct( ...
                        'handle', obj, ...
                        'datatype', dataType, ...
                        'typesource', typeSource)}, ...
                        dtStruct];
                end
            end
        case 'Inport'
            % Get data type of source (if it exists)
            outDataTypeStr = get_param(block, 'OutDataTypeStr');
            if strcmp(outDataTypeStr, 'Inherit: auto') && SystemDepth > 0
                srcs = getSrcs(obj, ...
                    'IncludeImplicit', 'off', 'ExitSubsystems', 'on', ...
                    'EnterSubsystems', 'off', 'Method', 'ReturnSameType');
                assert(length(srcs) <= 1)
                if isempty(srcs)
                    [dataType, typeSource, dtStruct] = getDT_emp_src(obj, outDataTypeStr);
                else
                    [dataType, typeSource, dtStruct] = getDataType(srcs(1), 'SystemDepth', SystemDepth-1, 'TraversalMap', TraversalMap); % Note decrement of SystemDepth
                    dtStruct = [{struct( ...
                        'handle', obj, ...
                        'datatype', dataType, ...
                        'typesource', typeSource)}, ...
                        dtStruct];
                end
            else
                [dataType, typeSource, dtStruct] = getDT_emp_src(obj, outDataTypeStr);
            end
        case 'BusSelector'
            % Assume that it can't be determined
            % TODO:
            % Unknown if corresponding Creator not found (because
            % it is like half of any signal we could refer to).
            % Else equivalent to the corresponding inport of the
            % corresponding bus creator (? is this true ?)
            
            [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
        case {'Delay','UnitDelay'}
            % Get data type of inport (if it exists)
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'off', 'ExitSubsystems', 'off', ...
                'EnterSubsystems', 'off', 'Method', 'ReturnSameType');
            assert(length(srcs) == 1)
            [dataType, typeSource, dtStruct] = getDataType(srcs(1), 'SystemDepth', SystemDepth, 'TraversalMap', TraversalMap);
            dtStruct = [{struct( ...
                'handle', obj, ...
                'datatype', dataType, ...
                'typesource', typeSource)}, ...
                dtStruct];
        otherwise
            [dataType, typeSource, dtStruct] = getOutDataType_Aux(obj, SystemDepth, TraversalMap, block);
    end
end
function [dataType, typeSource, dtStruct] = getOutDataType_Aux(obj, SystemDepth, TraversalMap, block)
    % Call this function for blocks that aren't directly supported
    
    blockParams = get_param(block, 'ObjectParameters');
    if any(strcmp('OutDataTypeStr', fieldnames(blockParams))) % has OutDataTypeStr parameter
        dataType = {get_param(block, 'OutDataTypeStr')};
        if strcmp(dataType{1}, 'Inherit: auto')
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'off', 'ExitSubsystems', 'on', ...
                'EnterSubsystems', 'off', 'Method', 'ReturnSameType');
            assert(length(srcs) == 1) % This may not be correct, but need to see an example that breaks this to figure out how to handle it
            
            [dataType, typeSource, dtStruct] = getDataType(srcs(1), 'SystemDepth', SystemDepth, 'TraversalMap', TraversalMap);
            dtStruct = [{struct( ...
                'handle', obj, ...
                'datatype', dataType, ...
                'typesource', typeSource)}, ...
                dtStruct];
        elseif any(strcmp(dataType{1}, {'Inherit: Same as first input', 'Inherit: Same as input'}))
            % Get first input
            ins = getPorts(block, 'Inport');
            for i = 1:length(ins)
                if get_param(ins(i), 'PortNumber') == 1
                    firstIn = ins(i);
                    break
                end
            end
            assert(logical(exist('firstIn', 'var')))
            
            % Get data type of the first input
            [dataType, typeSource, dtStruct] = getDataType(firstIn, 'SystemDepth', SystemDepth, 'TraversalMap', TraversalMap);
            dtStruct = [{struct( ...
                'handle', obj, ...
                'datatype', dataType, ...
                'typesource', typeSource)}, ...
                dtStruct];
        else
            typeSource = {obj};
            dtStruct = {struct( ...
                'handle', obj, ...
                'datatype', dataType, ...
                'typesource', typeSource)};
        end
    elseif any(strcmp('OutputArgumentSpecifications', fieldnames(blockParams))) % has OutputArgumentSpecifications parameter
        outArgSpec = get_param(block, 'OutputArgumentSpecifications');
        tmpDataType = regexp(outArgSpec, '^(.*)\((.*)\)', 'tokens');
        dataType = tmpDataType{1}(1);
        typeSource = {obj};
        dtStruct = {struct( ...
            'handle', obj, ...
            'datatype', dataType, ...
            'typesource', typeSource)};
    else
        % Unsupported / can't be determined
        [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
    end
end

function [dataType, typeSource, dtStruct] = getDT_len_src_leq_1(obj, srcs, SystemDepth, TraversalMap)
    % Get data type for obj with srcs where length(srcs) <= 1
    
    assert(isTraversed(obj, TraversalMap))
    
    assert(length(srcs) <= 1)
    if isempty(srcs)
        [dataType, typeSource, dtStruct] = getDT_emp_src(obj);
    else
        [dataType, typeSource, dtStruct] = getDataType(srcs(1), 'SystemDepth', SystemDepth, 'TraversalMap', TraversalMap);
        dtStruct = [{struct( ...
            'handle', obj, ...
            'datatype', dataType, ...
            'typesource', typeSource)}, ...
            dtStruct];
    end
end

function [dataType, typeSource, dtStruct] = getDT_emp_src(obj, varargin)
    % Get data type for obj where its srcs is empty

    if isempty(varargin)
        dataType = {''};
    else
        dataType = {varargin{1}};
    end
    typeSource = {obj};
    
    dtStruct = {struct('handle', obj, 'datatype', dataType, 'typesource', typeSource)};
end

function src = pickSrc(srcs, topsys)
    % Choose a src within topsys
    % TODO: Find a way to represent results for each src instead of just
    % one so this function isn't needed
    src = [];
    for i = 1:length(srcs)
        srcDepth = getDepthFromSys(topsys, getObjSys(srcs(i)));
        if srcDepth >= 0
            src = srcs(i);
            break
        end
    end
end

function topsys = getTopSys(sys, depth)
    % Get highest system allowed to be searched through according to depth.
    % I.e. Get the system that is a given number (depth) of layers higher
    % than the current system.
    
    if depth <= 0 || strcmp(bdroot(sys),sys)
        topsys = sys;
    else
        topsys = getTopSys(get_param(sys, 'Parent'), depth-1);
    end
end

function bool = isTraversed(obj, TraversalMap)
    bool = TraversalMap.isKey(obj);
end
function addTraversal(obj, TraversalMap)
    % Update TraversalMap with obj
    assert(~TraversalMap.isKey(obj)) % Don't allow traversing twice
    TraversalMap(obj) = 1; % Value doesn't matter
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

function sys = getObjSys(obj)
    % Get the system containing object at the highest level
    parent = get_param(obj, 'Parent');
    
    type = get_param(obj, 'Type');
    switch type
        case 'port'
            assert(strcmp(get_param(parent, 'Type'), 'block'))
            sys = getObjSys(parent);
        case {'block', 'line', 'annotation'}
            sys = parent;
        otherwise
            error('Unexpected object type.')
    end
end