function out = inputToNumeric(in)
% INPUTTONUMERIC Convert a cell array of paths to numeric handles.
%   Many of the built-in Simulink functions will take as input an array 
%   of handles (which are numeric), cell array of path names (character arrays), 
%   or a character array. This function takes any of the aforementioned types
%   and outputs a numeric array of handles. This gives the user many options
%   when providing input.
%
%   Inputs:
%       in  Path names or handles.
%
%   Outputs:
%       out Numeric array of handles.
%
%   Examples:
%       inputToNumeric({gcb})

    m = size(in,1);
    n = size(in,2);
    out = zeros(m,n);

    if isempty(in) % empty -> []
        out = [];
    elseif ~iscell(in) && ~isnumeric(in) % char array of name -> numeric handle
        out = get_param(in, 'Handle');
    elseif iscell(in) % cell of numeric handles or paths -> numeric array of handles
        for i = 1:m
            for j = 1:n
                c = in(i,j);
                try
                    out(i,j) = get_param(c{:}, 'Handle');
                catch
                    % Not a real block path name or handle
                end
            end
        end        
    elseif isnumeric(in) % numeric array -> numeric array of handles
        for k = 1:m
            for l = 1:n
                try
                    out(k,l) = get_param(in(k,l), 'Handle');
                catch
                    % Number is not actually a handle
                end
            end
        end
    end
end