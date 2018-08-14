classdef BiMap
    % A simple one to one mapping. Uses two containers.Map objects to be able to
    %   map back and forth. See example below to understand the mapping.
    %
    % Example:
    %   bm = BiMap('double','char');
    %   bm.add(12,'twelve');
    %   bm.add(3,'three');
    %   bm.lookup.keys, bm.lookdown.values % 3, 12
    %   bm.lookdown.keys, bm.lookup.values % 'three', 'twelve'
    %   bm.lookdown('twelve') % 12
    %   bm.lookup(3) % 'three'
    %
    % So lookup maps the 1st input of BiMap to the 2nd
    % And lookdown maps the 2nd input of BiMap to the 1st
    
    properties
        lookup % Map from lookup(down) keys(values) to the lookdown(up) keys(values)
        lookdown % Map from lookdown(up) keys(values) to the lookup(down) keys(values)
    end
    
    methods
        function bm = BiMap(lookupType, lookdownType)
            bm.lookup = containers.Map('KeyType', lookupType, 'ValueType', lookdownType);
            bm.lookdown = containers.Map('KeyType', lookdownType, 'ValueType', lookupType);
        end
        
        function add(bm, upkey, downkey)
            bm.lookup(upkey) = downkey;
            bm.lookdown(downkey) = upkey;
        end
    end
    
end

