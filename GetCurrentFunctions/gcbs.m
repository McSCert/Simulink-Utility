function sels = gcbs
% GCBS Returns a cell array of all currently selected blocks limited to the 
%   subsystem established by GCB.
%   C. Hecker/11Dec06
%
%   Inputs:
%       N/A
%
%   Outputs:
%       >> gcbs
%
%       ans =
%           2×1 cell array
%           {'Line2GotoFromDemo/In1'  }
%           {'Line2GotoFromDemo/From1'}

    if isempty(gcb)
        sels = {};
    else
        sys = get_param(gcb, 'parent');
        nBlks = find_system(sys, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'FollowLinks', 'on');
        nBlks = nBlks(2:end); % Strip off parent system name
        idx = strcmp(get_param(nBlks, 'selected'), 'on');
        sels = nBlks(idx);
    end
end