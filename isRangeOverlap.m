function bool = isRangeOverlap(range1,range2)
    % ISRANGEOVERLAP Detect if there is any common value between 2 ranges of
    % values.
    %
    % Input:
    %   range1  1x2 vector given with the lower value first.
    %   range2  1x2 vector given with the lower value first.
    %
    % Output:
    %   bool    Logical true if the two ranges contain any common value
    %           (including at the bounds).
    assert(range1(1)<=range1(2))
    assert(range2(1)<=range2(2))
    
    bool = range1(1)<=range2(2) && range2(1)<=range1(2);
end