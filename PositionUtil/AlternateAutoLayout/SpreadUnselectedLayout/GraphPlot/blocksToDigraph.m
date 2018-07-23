function dg  = blocksToDigraph(blocks)
    % BLOCKSTODIGRAPH Create a digraph representing the given blocks.
    %
    % Inputs:
    %   blocks  Vector of block handles in which each block is at the
    %           top level of the same system.
    %
    % Outputs:
    %   dg      Digraph representing the connection of the blocks. The
    %           blocks are interpreted as nodes and their signal line
    %           connections are used as edges. Weights are the default 1.
    
    %%
    % Check first input
    assert(isa(blocks, 'double'), 'Blocks must be given as a vector of handles.')
    
    if ~isempty(blocks)
        sys = getCommonParent(blocks);
        assert(bdIsLoaded(getfullname(bdroot(sys))), 'Simulink system provided is invalid or not loaded.')
    end
    
    %%
    % Get nodes
    nodes = inputToCell(blocks);
    numNodes = length(nodes);
    nodes = nodes(length(nodes):-1:1); % Reversing the block order appears to help in practice
    
    % Get neighbour data
    param = cell(size(nodes));
    [param{:}] = deal('PortConnectivity');
    allPorts = cellfun(@get_param, nodes, param, 'un', 0);
    
    % Construct adjacency matrix
    % Each row and column pertains to a unique block
    % A value of '1' in an entry indicates that the two blocks (indicated by the
    % column and row) are adjacent to each other because the one of the row block's output
    % is connected to one of the column block's input
    A = zeros(numNodes);
    
    % Populate adjacency matrix
    % For each block, check which block it is connected to by checking the
    % block(s) it is connected to by filling the adjacency matrix
    for i = 1:numNodes
        data = allPorts{i};
        neighbours = [data.DstBlock];
        if ~isempty(neighbours)
            for j = 1:length(neighbours)
                n = getfullname(neighbours(j));
                [row,~] = find(strcmp(nodes, n));
                A(i,row) = true;
            end
        end
    end
    nodes = applyNamingConvention(nodes);
    dg = digraph(A, nodes);
end