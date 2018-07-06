function bounds = bounds_of_sim_objects(objects)
    % BOUNDS_OF_SIM_OBJECTS Finds the left, top, right, and bottom bounds
    % among blocks, lines, and annotations in a list of objects. Does not
    % account for showing names.
    %
    % Inputs:
    %   objects     Cell array of Simulink objects.
    %
    % Outputs:
    %   bounds      Gives the bounds of the object as:
    %               [left, top, right, bottom]
    
    [B, L, A, P] = separate_objects_by_type(objects); % Get Blocks, Lines, Annotations, Ports
    assert(isempty(P))
    
    % Find the bounds for blocks, lines, and annotations separately
    boundsB = netBounds(B, @blockBounds);
    boundsA = netBounds(A, @annotationBounds);
    boundsL = netBounds(L, @lineBounds);
    
    % Find the most extreme bounds
    b1 = min([boundsB(1) boundsA(1) boundsL(1)]);
    b2 = min([boundsB(2) boundsA(2) boundsL(2)]);
    b3 = max([boundsB(3) boundsA(3) boundsL(3)]);
    b4 = max([boundsB(4) boundsA(4) boundsL(4)]);
    bounds = [b1, b2, b3, b4];
end

function bounds = netBounds(objects, bound_function)
    % NETBOUNDS Finds the 'net' bounds of a list of objects. I.e The min/max
    %   x/y coordinates.
    %
    %   Inputs:
    %       objects         A vector or cell array of objects that are each
    %                       either block, line, or annotation given as
    %                       handle or fullname.
    %       bound_function  A function handle that can be used on the given
    %                       objects to get their bounding box position.
    %
    %   Outputs:
    %       bounds      Gives the bounds of the object as:
    %                   [left, top, right, bottom]
    
    objects = inputToNumeric(objects);
    
    % Set default bounds
    % Initiate with the bound furthest away from its 'greatest' possible bounds
    % I.e. The left bound is given the right-most coordinate
    bounds = [32767, 32767, -32767, -32767];
    
    % Loop through objects to find the most extreme points of each
    for i = 1:length(objects)
        objectBounds = bound_function(objects(i));
        
        % objectBounds is a vector of coordinates: [left top right bottom]
        
        if objectBounds(3) > bounds(3)
            % The object has the new right-most position
            bounds(3) = objectBounds(3);
        end
        if objectBounds(1) < bounds(1)
            % The object has the new left-most position
            bounds(1) = objectBounds(1);
        end
        
        if objectBounds(4) > bounds(4)
            % The object has the new bottom-most position
            bounds(4) = objectBounds(4);
        end
        if objectBounds(2) < bounds(2)
            % The object has the new top-most position
            bounds(2) = objectBounds(2);
        end
    end
end