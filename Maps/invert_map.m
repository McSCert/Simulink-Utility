function inverted_map = invert_map(map)
    % INVERT_MAP - Get new map swapping values with keys and keys with values.
    % If a value is a vector or a 1xn or nx1 cell array, then each will be made
    % a key in the inverted map with the old key being a value for each (the
    % value will be in a nx1 cell array because multiple keys may have the same
    % value).
    %
    % Input:
    %    map - a container.Map(), value must be a valid key or a cell array or
    %       vector of valid keys. Note we cannot have some char values and
    %       some double values because then the keys would need to be of
    %       different types in the inversion.
    %
    % Output:
    %   inverted_map - copy
    %
    
    keys = map.keys;
    values = map.values;
    
    if isempty(keys)
        inverted_map = containers.Map();
    else
        if ischar(values{1})
            inverted_map = containers.Map('KeyType', 'char');
        else
            i = 1;
            while isempty(values{i}) || i > length(values)
                i = i + 1;
            end
            if i > length(values)
                inverted_map = containers.Map();
            elseif iscell(values{i})
                inverted_map = containers.Map('KeyType', class(values{i}{1}), 'ValueType', 'any');
            else
                inverted_map = containers.Map('KeyType', class(values{i}(1)), 'ValueType', 'any');
            end
        end
        
        for i = 1:length(keys)
            old_key = keys{i};
            old_value = values{i};
            if ischar(old_value)
                new_key = old_value;
                addKeyValue(inverted_map,new_key,old_key);
            else
                for j = 1:length(old_value)
                    if iscell(old_value)
                        new_key = old_value{j};
                    else
                        new_key = old_value(j);
                    end
                    addKeyValue(inverted_map,new_key,old_key);
                end
            end
        end
    end
end

function addKeyValue(map,key,value)
    if map.isKey(key)
        if iscell(map(key))
            map(key) = [map(key); {value}];
        else
            map(key) = {map(key); value};
        end
    else
        map(key) = {value};
    end
end