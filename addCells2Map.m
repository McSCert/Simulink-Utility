function addCells2Map(map, keysCell, valuesCell)
    % ADDCELL2MAP Adds a set of keys to a map with corresponding values.
    %
    %   Inputs:
    %       map         A containers.Map().
    %       keysCell    A cell array of keys. Keys already existing in the
    %                   map will be overwritten.
    %       valuesCell  A cell array of values. Indices of valuesCell
    %                   should correspond with the indices of keysCell.
    %
    %   Updates:
    %       map         The map argument is automatically updated and thus
    %                   not returned as an explicit output.
    %
    %   Notes: The user is expected to make sure the types of values in
    %   keysCell and valuesCell are of appropriate type for map. It is
    %   assumed that valuesCell is at least as long as keysCell and if it
    %   is longer, the excess will be ignored.
    
    len = length(keysCell);
    
    assert(len == length(valuesCell), 'Expected 2nd and 3rd argument to have the same length.')
    
    for i = 1:len
        map(keysCell{i}) = valuesCell{i};
    end
end