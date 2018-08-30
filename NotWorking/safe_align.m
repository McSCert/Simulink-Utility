function safe_align(block, objects)
    % SAFE_ALIGN Align a block with another block in the given set of objects
    % (all within a common parent system). Only perform alignment in cases that
    % should rarely (if ever) make the layout of the system worse. Lines are not
    % redrawn in any particular way.
    %
    % Inputs:
    %   block   Simulink block (full name or handle).
    %   objects List (cell array or vector) of Simulink objects (fullnames, or
    %           handles).
    %
    % Outputs:
    %   N/A
    %
    % Result:
    %   A port of block is aligned with a port of another block.
    %
    
    % TODO - this function is only partially implemented
    % If no port of the block is "aligned" and for at least one of its ports the
    % block can be "safely" moved to align that port, then align that port.
    % 2 ports are "aligned" if they are "facing" according to facingPorts.m.
    % A block can be "safely" moved to another location if:
    %   -Pushing the block to the new location does not cross another block,
    %   line, or annotation along the way and there is no block, line, or
    %   annotation crossing the path of a straight line between the 2 aligned
    %   ports.
    %   -TODO: add other safe conditions
    
    objects = inputToNumeric(objects);
    
    iports = getPorts(block, 'Ins');
    for i = 1:length(iports)
        in = iports(i);
        ports = getSrcs(in, 'IncludeImplicit', 'off', ...
            'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
            'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'outport'});
        
        do_cool_stuff(in, ports);
    end
    
    oports = getPorts(block, 'Out');
    for i = 1:length(oports)
        out = oports(i);
        ports = getDsts(out, 'IncludeImplicit', 'off', ...
            'ExitSubsystems', 'off', 'EnterSubsystems', 'off', ...
            'Method', 'RecurseUntilTypes', 'RecurseUntilTypes', {'inport'});
        do_cool_stuff(out, ports);
    end

end

function do_cool_stuff(p2, ports)
    for j = 1:length(ports)
        p1 = ports(j);
        
        posPre = get_param(get_param(p2, 'Parent'), 'Position');
        posPost = alignPorts(p1,p2,false); % position required of block with p2 for the alignment
        
        bounds = [min(posPre(1:2),posPost(1:2)), max(posPre(3:4),posPost(3:4))];
        
        foo(bounds)
    end
end

function foo(bounds)
    for i = 1:length(objects)
        objBounds = bounds_of_sim_objects({objects(i)});
        
        % if object is a block
        if isRangeOverlap(bounds(2,4),objBounds(2,4)) && ...
            isRangeOverlap(bounds(1,3),objBounds(1,3))
        end
    end
end