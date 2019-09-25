function col = vector2col(vector)
    % VECTOR2COL Converts a vector to a (n x 1) column vector.
    %
    % Input:
    %   vector  (1 x n) or (n x 1) numeric array or cell array.
    %
    % Output:
    %   col     (n x 1) column vector with the same values for the same indices
    %           as the input vector.
    %
    
    if iscolumn(vector)
        col = vector;
    else
        col = vector';
    end
end