function bool = isequalSets(set1, set2)
    % ISEQUALSETS checks if two sets are equal. Note sets are unordered, but
    % MATLAB does not have a structure for unordered lists, so the given sets
    % are expected to be 1xn or nx1 cell arrays.
    %
    %   Inputs:
    %       set1    1xn or nx1 cell array representing a set.
    %       set2    1xn or nx1 cell array representing a set.
    %
    %   Outputs:
    %       bool    Logical true if all elements in set1 are in set2 and all
    %               elements in set2 are in set1.
    %
    %   Note: While sets don't contain duplicates, they are allowed for this
    %   function. If either set has a duplicate, the other set will be expected
    %   to have 2 copies as well.
    %
    
    if isempty(set1)
        % Base Case: set1 is empty.
        if isempty(set2)
            bool = true;
        else
            bool = false;
        end
    else
        % Recursive Case: set1 is not empty.
        indices = indicesInCell(set1{1}, set2);
        if isempty(indices)
            % Element exists in set1, but not in set2.
            bool = false;
        else
            % Remove element from both sets, the resulting sets will be equal if
            % the initial sets were equal.
            set1(1) = [];
            set2(indices(1)) = [];
            bool = isequalSets(set1, set2); % Check if the resulting sets are equal
        end
    end
end

function indices = indicesInCell(element, cellArray)
    % Find indices in given cellArray where given element appears.
    indices = find(cellfun(@(c) isequal(element, c), cellArray));
end