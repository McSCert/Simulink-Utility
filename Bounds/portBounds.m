function bounds = portBounds(port)
    point = get_param(port, 'Position');
    bounds = [point(1) point(2) point(1) point(2)];
end