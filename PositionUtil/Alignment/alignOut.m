function alignOut(blocks)
    % Reposition each block to align its first outport with a port it
    % connects to.
    % Aligns from the first block to the last block in blocks.
    %
    
    % TODO: add support for round sum blocks
    % TODO: choose inport for output-input pairs more smartly
    %   e.g. don't choose one if it's not facing
    %   e.g. if multiple are facing, then which is closer
    
    inoutpairs = cell(1,length(blocks));
    for j = 1:length(blocks)
        b = blocks{j};
        outs = getPorts(b,'Outport');
        if ~isempty(outs)
            o = outs(1);
            ins = getDstPorts(o);
            if ~isempty(ins)
                % block has an outport and connects to an inport
                i = ins(1);
                inoutpairs{j} = struct('out', o, 'in', i);
            end
        end
    end
    
    % output refers to an output port
    % input refers to an input port
    % inBlk refers to a block we want to align with another
    % outBlk refers to a block we use to align another
    inBlk2output = containers.Map();
    output2input = containers.Map('KeyType','double','ValueType','double');
    inBlk2outBlk = containers.Map();
    outBlk2inBlk = containers.Map();
    
    inoutpairs(cellfun('isempty',inoutpairs)) = []; % Remove elements with no pair
    for j = length(inoutpairs):-1:1
        % Remove pairs where the output doesn't face the input.
        % This addresses loops, rotated blocks, and non in/outport port
        % types.
        
        if ~facingPorts(inoutpairs{j}.out,inoutpairs{j}.in)
            % output does not face input
            inoutpairs(j) = [];
        else
            inBlk = get_param(inoutpairs{j}.out, 'Parent');
            outBlk = get_param(inoutpairs{j}.in, 'Parent');
            
            inBlk2output(inBlk) = inoutpairs{j}.out;
            output2input(inBlk2output(inBlk)) = inoutpairs{j}.in;
            
            if inBlk2outBlk.isKey(inBlk)
                error('Something went wrong.')
            else
                inBlk2outBlk(inBlk) = {outBlk};
            end
            if outBlk2inBlk.isKey(outBlk)
                outBlk2inBlk(outBlk) = [outBlk2inBlk(outBlk), {inBlk}];
            else
                outBlk2inBlk(outBlk) = {inBlk};
            end
        end
    end
    
    independentAlignments = findIndependentAlignments(inBlk2outBlk);
    for key = independentAlignments
        key = key{1}{1};
        for val = outBlk2inBlk(key)
            val = val{1};
            alignPortsAndTriggerDependencies(inBlk2outBlk, outBlk2inBlk, inBlk2output, output2input, val);
        end
    end
end

function independentAlignments = findIndependentAlignments(inBlk2outBlk)
    independentAlignments = {};
    key2indAlign = containers.Map();
    recurseLimit = length(inBlk2outBlk.keys);
    for key = inBlk2outBlk.keys
        key = key{1};
        [indAlign, alreadyAdded] = findIndependentAlignments_Aux( ...
            inBlk2outBlk, key, recurseLimit, key2indAlign);
        if ~alreadyAdded
            independentAlignments{end+1} = indAlign;
        end
    end
end

function [independentAlignment, alreadyAdded] = ...
        findIndependentAlignments_Aux(inBlk2outBlk,key,countDown,key2indAlign)
    % countDown avoids an infinite loop
    % updates key2indAlign
    
    if 0 <= countDown
        if ~key2indAlign.isKey(key)
            alreadyAdded = false;
            
            if inBlk2outBlk.isKey(inBlk2outBlk(key))
                nextKey = inBlk2outBlk(key);
                nextKey = nextKey{1};
                [independentAlignment, alreadyAdded] = findIndependentAlignments_Aux( ...
                    inBlk2outBlk, nextKey, countDown-1, key2indAlign);
            else
                independentAlignment = inBlk2outBlk(key);
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

function alignPortsAndTriggerDependencies(inBlk2outBlk, outBlk2inBlk, inBlk2output, output2input, key)
    output = inBlk2output(key);
    input = output2input(output);
    alignPorts(output, input);
    
    if outBlk2inBlk.isKey(key)
        for val = outBlk2inBlk(key)
            val = val{1};
            alignPortsAndTriggerDependencies(inBlk2outBlk, outBlk2inBlk, inBlk2output, output2input, val);
        end
    end
end

function alignPorts(p1,p2)
    % Aligns p1 with p2
    
    % Ensure the ports are facing otherwise alignment won't look good
    [bool, direction] = facingPorts(p1,p2);
    assert(bool)
    
    % Get the block being moved
    blk = get_param(p1,'Parent');
    
    pos1 = get_param(p1,'Position');
    pos2 = get_param(p2,'Position');
    
    if any(strcmp(direction,{'right','left'}))
        shift = (pos2(2) - pos1(2))*[0 1 0 1]; % shift on y axis
    elseif any(strcmp(direction,{'down','up'}))
        shift = (pos2(1) - pos1(1))*[1 0 1 0]; % shift on x axis
    end
    
    bpos = get_param(blk,'Position');
    set_param(blk,'Position',bpos+shift)
end