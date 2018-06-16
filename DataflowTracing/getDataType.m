function [dataType, typeSource] = getDataType(obj, varargin)
    % GETDATATYPE Gets the data type of a Simulink object.
    %
    % Input:
    %   obj         A Simulink object handle or block full name.
    %   varargin    Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %	Parameter: 'SystemDepth'
    %   Value:  The number of SubSystem layers above the current one that
    %       may be checked. Default: 0 - only information directly within
    %       the system containing the given output port may be used.
    %
    % Output:
    %   dataType    Char array indicating the data type being sent from the
    %               given outport.
    %   typeSource  Handles of sources to the dataType.
    
    % Handle parameter-value pair inputs
    SystemDepth = 0;
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case lower('SystemDepth')
                SystemDepth = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    type = get_param(obj, 'Type');
    switch type
        case 'port'
            pType = get_param(obj, 'PortType');
            switch pType
                case 'outport'
                    [dataType, typeSource] = getOutDataType(obj, varargin{:});
                otherwise
                    % Get data type of source (if it exists)
                    srcs = getSrcs(obj, ...
                        'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                        'EnterSubsystems', 'on', 'Method', 'ReturnSameType');
                    [dataType, typeSource] = getDT_len_src_leq_1(obj, srcs, SystemDepth);
            end
        case 'line'
            % Get data type of source (if it exists)
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                'EnterSubsystems', 'on', 'Method', 'NextObject');
            [dataType, typeSource] = getDT_len_src_leq_1(obj, srcs, SystemDepth);
        case 'block'
            bType = get_param(obj, 'BlockType');
            sys = get_param(obj, 'Parent');
            topsys = getTopSys(sys, SystemDepth);
            switch bType
                case {'Outport', 'Goto', 'DataStoreWrite'}
                    % Get data type of source
                    srcs = getSrcs(obj, ...
                        'IncludeImplicit', 'off', 'ExitSubsystems', 'off', ...
                        'EnterSubsystems', 'off', 'Method', 'NextObject');
                    assert(length(srcs) == 1)
                    [dataType, typeSource] = getDataType(srcs(1), 'SystemDepth', SystemDepth);
                case 'From'
                    % Get data type of source (if it exists)
                    srcs = getSrcs(obj, ...
                        'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                        'EnterSubsystems', 'on', 'Method', 'NextObject');
                    assert(length(srcs) <= 1)
                    if isempty(srcs)
                        [dataType, typeSource] = getDT_emp_src(obj);
                    else
                        newDepth = getDepthFromSys(topsys, get_param(srcs(1), 'Parent'));
                        if newDepth < 0
                            [dataType, typeSource] = getDT_emp_src(obj);
                        else
                            [dataType, typeSource] = getDataType(srcs(1), 'SystemDepth', newDepth);
                        end
                    end
                case 'DataStoreRead'
                    % Type is type of source, but read may have multiple
                    % writes
                    srcs = getSrcs(obj, ...
                        'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                        'EnterSubsystems', 'on', 'Method', 'NextObject');
                    srcWrite = pickSrc(srcs, topsys);
                    [dataType, typeSource] = getDT_len_src_leq_1(obj, srcWrite, SystemDepth);
                otherwise
                    % Get data types of outports (if they exist)
                    dsts = getDsts(obj, ...
                        'IncludeImplicit', 'off', 'ExitSubsystems', 'off', ...
                        'EnterSubsystems', 'off', 'Method', 'NextObject');
                    % All dsts should be outports
                    for i = 1:length(dsts)
                        assert(get_param(dsts(i), 'Type'), 'port')
                        assert(get_param(dsts(i), 'PortType'), 'outport')
                    end
                    [dataType, typeSource] = getSetOutDataType(dsts, SystemDepth);
            end
        case 'annotation'
            [dataType, typeSource] = getDT_emp_src(obj, 'N/A');
        otherwise
            error('Unexpected object type.')
    end
end
function [dataType, typeSource] = getSetOutDataType(out_set, SystemDepth)
    % out_set is a vector of outports
    
    dataType = {};
    typeSource = {};
    for i = 1:length(out_set)
        [dt, ts] = getOutDataType(out_set(i), 'SystemDepth', SystemDepth);
        dataType = [dataType, dt];
        typeSource = [typeSource, ts];
    end
end

function [dataType, typeSource] = getOutDataType(obj, SystemDepth)
    % Check block parameters for information about this
    % port.
    
    % To ensure no infinite loops, getOutDataType is not allowed to recurse
    % on the main function, getDataType, with a block because most block
    % types use their outports to determine data type (since a block itself
    % does not actually have a data type of its own).
    
    block = get_param(obj, 'Parent');
    
    bType = get_param(block, 'BlockType');
    sys = get_param(block, 'Parent');
    topsys = getTopSys(sys, SystemDepth);
    switch bType
        case 'SubSystem'
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'off', 'ExitSubsystems', 'off', ...
                'EnterSubsystems', 'on', 'Method', 'ReturnSameType');
            assert(length(srcs) == 1)
            [dataType, typeSource] = getDataType(srcs(1), 'SystemDepth', SystemDepth);
        case 'BusCreator'
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'off', 'ExitSubsystems', 'off', ...
                'EnterSubsystems', 'off', 'Method', 'ReturnSameType');
            [dataType, typeSource] = getDT_len_src_leq_1(obj, srcs, SystemDepth);
        case 'DataStoreRead'
            % Type is type of source, but read may have multiple
            % writes
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                'EnterSubsystems', 'on', 'Method', 'ReturnSameType');
            srcWrite = pickSrc(srcs, topsys);
            [dataType, typeSource] = getDT_len_src_leq_1(obj, srcWrite, SystemDepth);
        case 'From'
            % Get data type of source (if it exists)
            srcs = getSrcs(obj, ...
                'IncludeImplicit', 'on', 'ExitSubsystems', 'on', ...
                'EnterSubsystems', 'on', 'Method', 'ReturnSameType');
            assert(length(srcs) <= 1)
            if isempty(srcs)
                [dataType, typeSource] = getDT_emp_src(obj);
            else
                newDepth = getDepthFromSys(topsys, get_param(srcs(1), 'Parent'));
                if newDepth < 0
                    [dataType, typeSource] = getDT_emp_src(obj);
                else
                    [dataType, typeSource] = getDataType(srcs(1), 'SystemDepth', newDepth);
                end
            end
        case 'Inport'
            % Get data type of source (if it exists)
            outDataTypeStr = get_param(block, 'OutDataTypeStr');
            if strcmp(outDataTypeStr, 'Inherit: auto') && SearchDepth > 0
                srcs = getSrcs(obj, ...
                    'IncludeImplicit', 'off', 'ExitSubsystems', 'on', ...
                    'EnterSubsystems', 'off', 'Method', 'ReturnSameType');
                assert(length(srcs) <= 1)
                if isempty(srcs)
                    [dataType, typeSource] = getDT_emp_src(obj, outDataTypeStr);
                else
                    [dataType, typeSource] = getDataType(srcs(1), 'SystemDepth', SystemDepth-1); % Note decrement of SystemDepth
                end
            else
                [dataType, typeSource] = getDT_emp_src(obj, outDataTypeStr);
            end
        case 'BusSelector'
            % Assume that it can't be determined
            % TODO:
            % Unknown if corresponding Creator not found (because
            % it is like half of any signal we could refer to.
            % Else equivalent to the corresponding inport of the
            % corresponding bus creator (? is this true ?)
            
            [dataType, typeSource] = getDT_emp_src(obj);
        otherwise
            blockParams = get_param(block, 'ObjectParameters');
            if any(strcmp('OutDataTypeStr', fieldnames(blockParams))) % has OutDataTypeStr parameter
                dataType = {{get_param(block, 'OutDataTypeStr')}};
                if strcmp(dataType{1}{1}, 'Inherit: auto')
                    srcs = getSrcs(obj, ...
                        'IncludeImplicit', 'off', 'ExitSubsystems', 'on', ...
                        'EnterSubsystems', 'off', 'Method', 'ReturnSameType');
                    assert(length(srcs) == 1) % This may not be correct, but need to see an example that breaks this to figure out how to handle it
                    [dataType, typeSource] = getDataType(srcs(1), 'SystemDepth', SystemDepth);
                elseif strcmp(dataType{1}{1}, 'Inherit: Same as first input')
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
                    [dataType, typeSource] = getDataType(firstIn, 'SystemDepth', SystemDepth);
                else
                    typeSource = obj;
                end
            else
                % Unsupported / can't be determined
                [dataType, typeSource] = getDT_emp_src(obj);
            end
    end
end

function [dataType, typeSource] = getDT_len_src_leq_1(obj, srcs, SystemDepth)
    % Get data type for obj with srcs where length(srcs) <= 1
    
    assert(length(srcs) <= 1)
    if isempty(srcs)
        [dataType, typeSource] = getDT_emp_src(obj);
    else
        [dataType, typeSource] = getDataType(srcs(1), SystemDepth);
    end
end

function [dataType, typeSource] = getDT_emp_src(obj, varargin)
    % Get data type for obj where its srcs is empty
    
    if isempty(varargin)
        dataType = {{}};
    else
        dataType = {varargin(1)};
    end
    typeSource = {{obj}};
end

function src = pickSrc(srcs, topsys)
    % Choose a src within topsys
    % TODO: Find a way to represent results for each src instead of just
    % one so this function isn't needed
    src = [];
    for i = 1:length(srcs)
        srcDepth = getDepthFromSys(topsys, get_param(srcs(i), 'Parent'));
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

function depth = getDepthFromSys(sys, sys2)
    % Get depth of sys2 from sys
    % Return -1 if sys2 is not in sys
    
    if strcmp(sys,sys2)
        depth = 0;
    elseif strcmp(bdroot(sys2),sys2)
        depth = -1;
    else
        depth = getDepthFromSys(sys, get_param(sys2, 'Parent'));
    end
end