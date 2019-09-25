function row = vector2row(vector)
    % VECTOR2ROW Converts a vector to a (1 x n) row vector.
    %
    % Input:
    %   vector  (1 x n) or (n x 1) numeric array or cell array.
    %
    % Output:
    %   row     (1 x n) row vector with the same values for the same indices as
    %           the input vector.
    %
    
    if isrow(vector)
        row = vector;
    else
        row = vector';
    end
end