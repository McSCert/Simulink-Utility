function bounds = annotationBounds(note)
    ob = get_param(note,'object');
    bounds = ob.getBounds;
end