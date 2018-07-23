function dgNew = addImplicitEdgesBetweenBlocks(blocks, dg)
    % ADDIMPLICITEDGESBETWEENBLOCKS Add edges to a digraph representing the
    % implicit connections between goto/froms.
    %
    % Inputs:
    %   blocks  Vector of block handles in which each block is at the
    %           top level of the same system.
    %   dg      Digraph representation of the system sys.
    %
    % Outputs:
    %   dgNew   Updated digraph.
    
    %%
    % Check first input
    assert(isa(blocks, 'double'), 'Blocks must be given as a vector of handles.')
    
    if ~isempty(blocks)
        sys = getCommonParent(blocks);
        assert(bdIsLoaded(getfullname(bdroot(sys))), 'Simulink system provided is invalid or not loaded.')
    end
    
    % Check second input
    assert(isdigraph(dg), 'Digraph argument provided is not a digraph');
    
    %%
    % Duplicate dg
    dgNew = dg;
    
    %%
    % Add Goto/Froms as edges
    gotos = zeros(1,length(blocks));
    froms = zeros(1,length(blocks));
    for i = 1:length(blocks)
        switch get_param(blocks(i), 'BlockType')
            case 'Goto'
                gotos(i) = blocks(i);
            case 'From'
                froms(i) = blocks(i);
        end
    end
    gotos = inputToCell(gotos(find(gotos)));
    froms = inputToCell(froms(find(froms)));
    
    % For each Goto tags, find the corresponding From tags
    for i = 1:length(gotos)
        subFroms = findFromsInScope(gotos{i});
        for j = 1:length(subFroms)
            snk = getRootInSys(subFroms{j});
            if ~isempty(snk) && any(strcmp(snk, inputToCell(blocks)))
                srcName = applyNamingConvention(gotos{i});
                snkName = applyNamingConvention(snk);
                % If the implicit edge does not exist in the graph, add it to the
                % graph
                if ~edgeExists(dgNew, srcName, snkName)
                    dgNew = addedge(dgNew, srcName, snkName, 1);
                end
            end
        end
    end
    % For each From tags, find the corresponding Goto tags
    for i = 1:length(froms)
        subGotos = findGotosInScope(froms{i});
        for j = 1:length(subGotos)
            src = getRootInSys(subGotos{j});
            if ~isempty(src) && any(strcmp(src, inputToCell(blocks)))
                srcName = applyNamingConvention(src);
                snkName = applyNamingConvention(froms{i});
                % If the implicit edge does not exist in the graph, add it to the
                % graph
                if ~edgeExists(dgNew, srcName, snkName)
                    dgNew = addedge(dgNew, srcName, snkName, 1);
                end
            end
        end
    end
    
    %%
    % Add Data Store Read/Writes as edges
    writes = zeros(1,length(blocks));
    reads = zeros(1,length(blocks));
    for i = 1:length(blocks)
        switch get_param(blocks(i), 'BlockType')
            case 'DataStoreWrite'
                writes(i) = blocks(i);
            case 'DataStoreRead'
                reads(i) = blocks(i);
        end
    end
    writes = inputToCell(writes(find(writes)));
    reads = inputToCell(reads(find(reads)));
    
    % For each DataStoreWrite, find the corresponding DataStoreRead
    for i = 1:length(writes)
        subReads = findReadsInScope(writes{i});
        for j = 1:length(subReads)
            snk = getRootInSys(subReads{j});
            if ~isempty(snk) && any(strcmp(snk, inputToCell(blocks)))
                srcName = applyNamingConvention(writes{i});
                snkName = applyNamingConvention(snk);
                % If the implicit edge does not exist in the graph, add it to the
                % graph
                if ~edgeExists(dgNew, srcName, snkName)
                    dgNew = addedge(dgNew, srcName, snkName, 1);
                end
            end
        end
    end
    % For each DataStoreReads
    for i = 1:length(reads)
        subWrites = findWritesInScope(reads{i});
        for j = 1:length(subWrites)
            src = getRootInSys(subWrites{j});
            if ~isempty(src) && any(strcmp(src, inputToCell(blocks)))
                srcName = applyNamingConvention(src);
                snkName = applyNamingConvention(reads{i});
                % If the implicit edge does not exist in the graph, add it to the
                % graph
                if ~edgeExists(dgNew, srcName, snkName)
                    dgNew = addedge(dgNew, srcName, snkName, 1);
                end
            end
        end
    end
    
    function root = getRootInSys(blk)
        % Recursively get parent system of the block until reaching sys.
        % If blk is directly within sys, then it is "root",
        % otherwise "root" is a subsystem directly within sys that contains
        % blk at any depth (if it exists).
        %
        % The point is to find which block to create an edge with when the
        % data flow implicitly goes into a subsystem.
        p = get_param(blk, 'Parent');
        if strcmp(p, sys)
            root = blk;
        elseif(isempty(p))
            root = '';
        else
            root = getRootInSys(p);
        end
    end
    
    % Check if the edge exists in the current graph
    function exists = edgeExists(dg, source, sink)
        exists = false;
        for z = 1:size(dg.Edges, 1)
            edgeFound = strcmp(source, dg.Edges{z,1}{1}) && strcmp(sink, dg.Edges{z,1}{2});
            if edgeFound
                exists = true;
            end
        end
    end
end