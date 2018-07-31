function caller_name = current_function( inarg )
    %
    %   Code found at: https://www.mathworks.com/matlabcentral/answers/77577-getting-function-name-within-that-function-run-or-currently-running-function
    %   See also: mfilename
    dbk = dbstack( 1 );
    if isempty( dbk )
        str = 'base';
    else
        str = dbk(1).name;
    end
    ixf = find( str == '.', 1, 'first' );
    if isempty( ixf ) || ( nargin==1 && strcmp( inarg, '-full' ) )
        caller_name = str;
    else
        caller_name = str( ixf+1 : end );
    end
end