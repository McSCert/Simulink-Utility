function busSelectors = findBusSelectors(address, block)
% BUSSELECTORS Find Bus Selectors corresponding to an initial Bus Creator.

    busSelectors = [];
    tmpBlocks = getDstBlocks(address, block);
    if isempty(tmpBlocks)
        busSelectors = [];
    else
        for i = 1:length(tmpBlocks)
            if iscell(tmpBlocks)
                if strcmp(get_param(tmpBlocks{i}, 'BlockType'), 'BusSelector')
                    busSelectors = [busSelectors; tmpBlocks{i}];
                else
                    tmpSelectors = findBusSelectors(address, tmpBlocks{i});
                    if ischar(tmpSelectors)
                        tmpSelectors = cellstr(tmpSelectors);
                    end
                    busSelectors = [busSelectors; tmpSelectors];
                end
            else
                if strcmp(get_param(tmpBlocks(i), 'BlockType'), 'BusSelector')
                    busSelectors = [busSelectors;tmpBlocks(i)];
                else
                    tmpMap(getfullname(tmpBlocks(i))) = true;
                    tmpSelectors = findBusSelectors(address, tmpBlocks(i), tmpMap);
                    if ischar(tmpSelectors)
                        tmpSelectors = cellstr(tmpSelectors);
                    end
                    busSelectors = [busSelectors; tmpSelectors];
                end
            end
        end
    end
end