function TEMPAutoLayout(objects)
    % Takes a set of objects at the same level of a system and lays them
    % out. Other objects in the system are shifted about the laid out
    % objects to keep them from overlapping.
    %
    % objects may contain blocks, lines, and/or annotations as handles or
    % fullnames (blocks only) in a cell array
    
    %%
    % Convert to cell array of handles
    for i = 1:length(objects)
        objects{i} = get_param(objects{i}, 'Handle');
    end
    
    %%
    % Determine the system in which the layout is taking place and assert
    % that all objects are in that system
    if isempty(objects)
        disp('Nothing to simplify.')
    else
        system = get_param(get_param(objects{1}, 'Parent'), 'Handle');
        for i = 2:length(objects)
            assert(system == get_param(get_param(objects{i}, 'Parent'), 'Handle'))
        end
    end
    
    %%
    % Separate objects into the different types
    [blocks, lines, annotations, ports] = separate_objects_by_type(objects);
    assert(isempty(ports))
    
    %%
    % TODO use input parameter to constrain acceptable objects
    % TODO use input parameter to automatically add certain lines to the
    % set of objects depending on the blocks in objects
    % Update set of objects as needed
    
    %%
    % Get bounds of objects
    orig_bounds = bounds_of_sim_objects(objects);
    
    %%
    % Layout selected objects ignoring others
    IsoLayout(blocks, annotations); % Automatic Isolated Layout
    
    %%
    % Get new bounds of objects
    new_bounds = bounds_of_sim_objects(objects);
    
    %%
    % Shift objects so that the center of their bounds is in the same spot
    % the center of the bounds was in to begin with
    
    % Get center of orginal bounds
    orig_center = position_center(orig_bounds);
    % Get center of new bounds
    new_center = position_center(new_bounds);
    % Get offset between new and original center
    center_offset = orig_center - new_center;
    % Shift objects by the offset
    shift_sim_objects(blocks, lines, annotations, center_offset);
    
    %%
    % Push remaining blocks and annotations in the system away from the new
    % bounds (if the bounds have expanded) or pull them toward the new
    % bounds (otherwise)
    
    % Get the objects that need to be shifted
    system_blocks = find_blocks_in_system(system);
    system_annotations = find_annotations_in_system(system);
    system_lines = find_lines_in_system(system);
    non_layout_blocks = vectorToCell(setdiff(system_blocks, cellToVector(blocks)'));
    non_layout_annotations = vectorToCell(setdiff(system_annotations, cellToVector(annotations)'));
    non_layout_lines = vectorToCell(setdiff(system_lines, cellToVector(lines)'));
    
    % Figure out how to shift blocks and annotations
    bound_shift = new_bounds - orig_bounds;
    adjustObjectsAroundLayout(non_layout_blocks, orig_bounds, bound_shift, 'block');
    adjustObjectsAroundLayout(non_layout_annotations, orig_bounds, bound_shift, 'annotation');
    
    % TODO - depending on input parameters redraw lines affected by
    % previous shifting
    redraw_lines(system, 'autorouting', 'on')
end

function shift_sim_objects(blocks, lines, annotations, offset)
    %
    
    shiftBlocks(blocks, [offset, offset]); % Takes 1x4 vector
    shiftAnnotations(annotations, [offset, offset]); % Takes 1x4 vector
    shiftLines(lines, offset); % Takes 1x2 vector
end

function adjustObjectsAroundLayout(objects, orig_bounds, bound_shift, type)
    % objects are all of the given type
    %
    % Move objects with the shift in bounds between original and new
    % layout. The approach taken aims to keep objects in the same position
    % relative to the original layout. This approach will not handle
    % objects that were within the original bounds well, however, this is
    % not considered a big problem because of the degree of difficulty in
    % appropriately handling these cases even manually and further it's
    % also a bizarre case that should generally be avoidable. If it turns
    % out to need to be handled, a simple approach is to pick some
    % direction to shift the objects that were within the original bounds
    % and to do so as well as potentially increase the overall shift amount
    % in that direction accordingly.
    
    switch type
        case 'block'
            getBounds = @blockBounds;
            shiftObjects = @shiftBlocks;
        case 'line'
            getBounds = @lineBounds;
            shiftObjects = @shiftLines;
        case 'annotation'
            getBounds = @annotationBounds;
            shiftObjects = @shiftAnnotations;
        otherwise
            error('Unexpected object type.')
    end
    
    for i = 1:length(objects)
        object = objects{i};
        
        % Get bounds of the block
        my_bounds = getBounds(object);
        
        my_shift = [0 0 0 0];
        
        idx = 1; % Left
        if my_bounds(idx) < orig_bounds(idx)
            my_shift = my_shift + [bound_shift(idx) 0 bound_shift(idx) 0];
        end
        idx = 2; % Top
        if my_bounds(idx) < orig_bounds(idx)
            my_shift = my_shift + [0 bound_shift(idx) 0 bound_shift(idx)];
        end
        idx = 3; % Right
        if my_bounds(idx) < orig_bounds(idx)
            my_shift = my_shift + [bound_shift(idx) 0 bound_shift(idx) 0];
        end
        idx = 4; % Bottom
        if my_bounds(idx) < orig_bounds(idx)
            my_shift = my_shift + [0 bound_shift(idx) 0 bound_shift(idx)];
        end
        
        shiftObjects({object}, my_shift);
    end
end

function blocks = find_blocks_in_system(system)
    blocks = find_system(system, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'block');
end
function annotations = find_annotations_in_system(system)
    annotations = find_system(system, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'annotation');
end
function lines = find_lines_in_system(system)
    lines = find_system(system, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'line');
end

function IsoLayout(blocks, annotations)
    % Isolated layout of only the blocks and annotations given (relevant
    % lines will also be laid out, but otherwise nothing else in the system
    % is touched)

    % TODO consider other possible automatic layout approaches
    columnBasedLayout(blocks, 'WidthMode', 'MaxColBlock', 'MethodForDesiredHeight', 'Sum', 'AlignmentType', 'Dest')
end