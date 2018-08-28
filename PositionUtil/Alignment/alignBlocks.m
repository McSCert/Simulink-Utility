function [align_ports, align_ports_idxs] = alignBlocks(blocks, varargin)
    % ALIGNBLOCKS Align blocks with each other. This is by no means perfect...
    %
    % Inputs:
    %   blocks      Cell array of Simulink blocks.
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %	Parameter: 'PortType' - Finds a port of the given type on each
    %       block (if it exists) and finds the port it connects to via
    %       signal line (if it exists) and moves the block so that the port
    %       lines up with the connected port.
    %   Value:  Options correspond with the case sensitive type argument in
    %           getPorts.m (the first port returned by it is the port used).
    %           Default: 'Inport'.
    %
    % Outputs:
    %   align_ports Vector of port handles that were used for alignment.
    %
    % Effect:
    %
    %
    
    % Handle parameter-value pairs
    PortType = 'Inport';
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = varargin{i+1};
        
        switch param
            case lower('PortType')
                PortType = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    portPairs = cell(1,length(blocks));
    for j = 1:length(blocks)
        b = blocks{j};
        bports = getPorts(b,PortType); % Ports on the block that we could use for alignment
        if ~isempty(bports)
            bph = bports(1); % Port handle that we will use for alignment
            
            % Find the ports that the port we're using for alignment
            % connects to
            if strcmp(get_param(bph, 'PortType'), 'outport')
                connPorts = getDstPorts(bph);
            else
                connPorts = getSrcPorts(bph);
            end
            if ~isempty(connPorts)
                % block has a port of the right type that connects to
                % another port
                cph = connPorts(1);
                portPairs{j} = struct('align_port', bph, 'reference_port', cph, 'idx', j);
            end
        end
    end
    
    % alignPort refers to a port the port being moved in the alignment
    % connPort refers to a port connected to an alignPort
    % alignBlk refers to a block we want to align with another
    % connBlk refers to a block we use to align another
    alignBlk2alignPort = containers.Map();
    alignPort2connPort = containers.Map('KeyType','double','ValueType','double');
    alignBlk2connBlk = containers.Map();
    connBlk2alignBlk = containers.Map();
    
    portPairs(cellfun('isempty',portPairs)) = []; % Remove elements with no pair
    for j = length(portPairs):-1:1
        % Remove pairs where the ports don't face each other.
        % This approach addresses loops, rotated blocks, and non in/outport
        % port types.
        
        if ~facingPorts(portPairs{j}.align_port,portPairs{j}.reference_port)
            % ports are not facing
            portPairs(j) = [];
        else
            alignBlk = get_param(portPairs{j}.align_port, 'Parent');
            connBlk = get_param(portPairs{j}.reference_port, 'Parent');
            
            alignBlk2alignPort(alignBlk) = portPairs{j}.align_port;
            alignPort2connPort(alignBlk2alignPort(alignBlk)) = portPairs{j}.reference_port;
            
            if alignBlk2connBlk.isKey(alignBlk)
                error('Something went wrong.')
            else
                alignBlk2connBlk(alignBlk) = {connBlk};
            end
            if connBlk2alignBlk.isKey(connBlk)
                connBlk2alignBlk(connBlk) = [connBlk2alignBlk(connBlk), {alignBlk}];
            else
                connBlk2alignBlk(connBlk) = {alignBlk};
            end
        end
    end
    align_ports = cellfun(@(x) x.align_port, portPairs);
    align_ports_idxs = cellfun(@(x) x.idx, portPairs);
    
    independentAlignments = findIndependentAlignments(alignBlk2connBlk);
    for keyCell = independentAlignments
        key = keyCell{1}{1};
        for valCell = connBlk2alignBlk(key)
            val = valCell{1};
            alignPortsAndTriggerDependencies(alignBlk2connBlk, connBlk2alignBlk, alignBlk2alignPort, alignPort2connPort, val);
        end
    end
end

function alignPortsAndTriggerDependencies(alignBlk2connBlk, connBlk2alignBlk, alignBlk2alignPort, alignPort2connPort, key)
    alignPort = alignBlk2alignPort(key);
    connPort = alignPort2connPort(alignPort);
    alignPorts(connPort, alignPort);
    
    if connBlk2alignBlk.isKey(key)
        for valCell = connBlk2alignBlk(key)
            val = valCell{1};
            alignPortsAndTriggerDependencies(alignBlk2connBlk, connBlk2alignBlk, alignBlk2alignPort, alignPort2connPort, val);
        end
    end
end

function independentAlignments = findIndependentAlignments(alignBlk2connBlk)
    % alignBlk2connBlk - map from blocks to be aligned to the blocks they
    % are to be aligned with
    
    independentAlignments = {};
    key2indAlign = containers.Map();
    recurseLimit = length(alignBlk2connBlk.keys);
    for keyCell = alignBlk2connBlk.keys
        key = keyCell{1};
        [indAlign, alreadyAdded] = findIndependentAlignments_Aux( ...
            alignBlk2connBlk, key, recurseLimit, key2indAlign);
        if ~alreadyAdded
            independentAlignments{end+1} = indAlign;
        end
    end
end

function [independentAlignment, alreadyAdded] = ...
        findIndependentAlignments_Aux(alignBlk2connBlk,key,countDown,key2indAlign)
    % countDown avoids an infinite loop
    % updates key2indAlign
    
    if 0 <= countDown
        if ~key2indAlign.isKey(key)
            alreadyAdded = false;
            
            if alignBlk2connBlk.isKey(alignBlk2connBlk(key))
                nextKey = alignBlk2connBlk(key);
                nextKey = nextKey{1};
                [independentAlignment, alreadyAdded] = findIndependentAlignments_Aux( ...
                    alignBlk2connBlk, nextKey, countDown-1, key2indAlign);
            else
                independentAlignment = alignBlk2connBlk(key);
            end
            key2indAlign(key) = independentAlignment;
        else
            % independentAlignment has already been added
            alreadyAdded = true;
            independentAlignment = '';
        end
    else
        error('Something went wrong. There appears to be a loop in the inBlk2outBlk internal variable.')
    end
end