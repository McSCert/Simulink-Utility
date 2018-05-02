function handle = branchToPort(address, lineHandle, portHandle)
% BRANCHTOPORT Brach an existing line to connect to another port.
%
%   Inputs:
%       address     Model name.
%       lineHandle  Handle of the line to branch.
%       portHandle  Handle of port to connect the branch to.
%
%   Outputs:
%       handle      Handle of the new line.

    % Determine source point to start the line segment
    points = get_param(lineHandle, 'Points');
    srcPoint = points(1,:);
    dstPoint = points(end,:);
    
    segmentSrcX = round((dstPoint(1) - srcPoint(1))/2 + srcPoint(1));
    segmentSrcY = round(dstPoint(2));
    
    % Determine destination point
    % Note: If there are several blocks on top of antoher, this point may
    % cause issues
    segmentDst = get_param(portHandle, 'Position');
    
    handle = add_line(address, [segmentSrcX segmentSrcY; segmentDst]);    
end