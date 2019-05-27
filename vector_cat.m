function vector = vector_cat(v1, v2, varargin)
    % VECTOR_CAT Concatenate any vectors into the structure of the first. I.e.
    % if v1 is (1 x n) and v2 is (m x 1), they are concatenated into a (1 x
    % n+m).
    %
    %   Inputs:
    %       v1          (1 x n) or (n x 1) numeric array or cell array.
    %       v2          (1 x m) or (m x 1) numeric array or cell array.
    %       varargin    Used to pass additional vectors.
    %
    %   Output:
    %       vector      Concatenation of v1 with v2 into a new vector with the
    %                   same dimensions as the first vector with a dimension
    %                   greater than 1, if no vector meets this criteria, then
    %                   they are concatenated into a column vector.
    %
    
    vectorCell = [{v1}, {v2}, varargin];
    
    % Determine dimension to concatenate vectors along.
    sizeCell = cell(1, length(vectorCell));
    dimCell = cell(1, length(vectorCell));
    dim = 0; % Init dimension to concatenate along.
    for i = 1:length(vectorCell)
        assert(isvector(vectorCell{i}), ['Argument ' num2str(i) ', is not a vector.'])

        sizeCell{i} = size(vectorCell{i});
        if sizeCell{i}(1) == 1 && sizeCell{i}(2) == 1
            dimCell{i} = 1; % Don't care
        else
            assert(sizeCell{i}(1) == 1 || sizeCell{i}(2) == 1, ...
                'Something went wrong. Unexpected vector dimensions.')
            if sizeCell{i}(1) == 1
                dimCell{i} = 2;
            else % sizeCell{i}(2) == 1
                dimCell{i} = 1;
            end
            
            % Set dimension to concatenate along.
            if dim == 0
                dim = dimCell{i};
            end
        end
    end
    if dim == 0
        dim = 1; % Defaults to concatenate into a column vector.
    end
    
    % Concatenate vectors.
    if ~isempty(vectorCell)
        vector = vectorCell{1};
    end
    for i = 2:length(vectorCell)
        if dim == dimCell{i}
            vector = cat(dim, vector, vectorCell{i});
        elseif dim ~= dimCell{i}
            vector = cat(dim, vector, vectorCell{i}');
        end
    end
end
