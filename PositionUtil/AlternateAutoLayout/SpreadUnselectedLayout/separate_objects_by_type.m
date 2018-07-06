function [blocks, lines, annotations, ports] = separate_objects_by_type(objects)
    blocks = {};
    lines = {};
    annotations = {};
    ports = {};
    for i = 1:length(objects)
        object = objects{i};
        type = get_param(object, 'Type');
        switch type
            case 'block'
                blocks{end+1} = object;
            case 'line'
                lines{end+1} = object;
            case 'annotation'
                annotations{end+1} = object;
            case 'port'
                ports{end+1} = object;
            otherwise
                error('Unexpected object type.')
        end
    end
end