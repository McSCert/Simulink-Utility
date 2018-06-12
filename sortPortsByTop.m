function [sortedPorts, order] = sortPortsByTop(ports)
    % SORTPORTSBYTOP Sorts ports from the port with the least y-axis
    % position to the block with the greatest y-axis position (this is from
    % high to low when looking at block diagrams).
    %
    % Inputs:
    %   ports       Vector of Simulink ports.
    %
    % Outputs:
    %   sortedPorts Vector of ports sorted by their y-axis positions.
    %   order
    %
    
    tops = zeros(1,length(ports));
    for i = 1:length(ports)
        b = ports(i);
        pos = get_param(b, 'Position');
        tops(i) = pos(2);
    end
    [~, order] = sort(tops);
    sortedPorts = ports(order);
end