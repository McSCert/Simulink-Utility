function handleMap = fullname_map2handle_map(fullnameMap)
    % FULLNAME_MAP2HANDLE_MAP Convert a map with keys as Simulink block
    % fullnames to a map with keys as Simulink block handles.
    %
    % Input:
    %   fullnameMap     Map from Simulink block fullnames to anything.
    %
    % Output:
    %   handleMap       Map from Simulink block handles to the same
    %                   corresponding values of fullnameMap.
    %
    
    handleMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
    keys = fullnameMap.keys;
    for i = 1:length(keys)
        handleMap(get_param(keys{i}, 'Handle')) = fullnameMap(keys{i});
    end
end