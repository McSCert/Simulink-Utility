function [bool, direction] = cmpDataflowDirection(p1,p2)
    % CMPDATAFLOWDIRECTION determines if port p1 and port p2 send/receive
    % data in the same direction.
    %
    %   Inputs:
    %       p1  Port handle.
    %       p2  Port handle.
    %
    %   Outputs:
    %       bool        Logical true when dataflow is the same for each.
    %       direction   Direction of flow from p1.
    
    flowDirection1 = getPortOrientation(p1);
    flowDirection2 = getPortOrientation(p2);
    
    bool = strcmp(flowDirection1, flowDirection2); % same direction of dataflow
    direction = flowDirection1;
end