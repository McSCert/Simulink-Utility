function bool = cmp_objs(obj1, obj2)
% CMP_OBJS Compares if two given objects have the same handle.
%
%   Inputs:
%       obj1    A Simulink object handle or fullname.
%       obj2    A Simulink object handle or fullname.
%
%   Outputs:
%       bool    Logical true if the given objects are the same.

    bool = get_param(obj1, 'Handle') == get_param(obj2, 'Handle');
end