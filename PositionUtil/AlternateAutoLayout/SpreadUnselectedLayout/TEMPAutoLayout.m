function TEMPAutoLayout(objects)
    % Takes a set of objects at the same level of a system and lays them
    % out. Other objects in the system are shifted about the laid out
    % objects to keep them from overlapping.
    %
    % objects may contain blocks, lines, and/or annotations as handles or
    % fullnames (blocks only) in a cell array
    
    %%
    % Convert to cell array of handles
    for i = 1:length(objects)
        objects{i} = get_param(objects{i}, 'Handle');
    end
    
    %%
    % Determine the system in which the layout is taking place and assert
    % that all objects are in that system
    if isempty(objects)
        disp('Nothing to simplify.')
    else
        system = getCommonParent(objects);
        
        % Check that model is unlocked
        try
            assert(strcmp(get_param(bdroot(system), 'Lock'), 'off'));
        catch ME
            if strcmp(ME.identifier, 'MATLAB:assert:failed') || ...
                    strcmp(ME.identifier, 'MATLAB:assertion:failed')
                error('File is locked');
            end
        end
        
        % If address has a LinkStatus, then it is 'none' or 'inactive'
        try
            assert(any(strcmp(get_param(system, 'LinkStatus'), {'none','inactive'})), 'LinkStatus must be ''none'' or ''inactive''.')
        catch ME
            if ~strcmp(ME.identifier,'Simulink:Commands:ParamUnknown')
                rethrow(ME)
            end
        end
    end
    
    %%
    % Separate objects into the different types
    [blocks, lines, annotations, ports] = separate_objects_by_type(objects);
    assert(isempty(ports))
    
    %%
    % TODO use input parameter to constrain acceptable objects
    % TODO use input parameter to automatically add certain lines to the
    % set of objects depending on the blocks in objects
    % Update set of objects as needed
    
    %%
    % Get bounds of objects
    orig_bounds = bounds_of_sim_objects(objects);
    
    %%
    % Layout selected objects ignoring others
    IsoLayout(blocks, annotations, '3rdparty'); % Automatic Isolated Layout
    
    %%
    % Get new bounds of objects
    new_bounds = bounds_of_sim_objects(objects);
    
    %%
    % Shift objects so that the center of their bounds is in the same spot
    % the center of the bounds was in to begin with
    
    % Get center of orginal bounds
    orig_center = position_center(orig_bounds);
    % Get center of new bounds
    new_center = position_center(new_bounds);
    % Get offset between new and original center
    center_offset = orig_center - new_center;
    % Shift objects by the offset
    shift_sim_objects(blocks, lines, annotations, center_offset);
    new_bounds = bounds_of_sim_objects(objects); % Update new bounds. Can't simply add the offset since shifting isn't always precise
    
    %%
    % Push remaining blocks and annotations in the system away from the new
    % bounds (if the bounds have expanded) or pull them toward the new
    % bounds (otherwise)
    
    % Get the objects that need to be shifted
    system_blocks = find_blocks_in_system(system);
    system_annotations = find_annotations_in_system(system);
    system_lines = find_lines_in_system(system);
    non_layout_blocks = vectorToCell(setdiff(system_blocks, cellToVector(blocks)'));
    non_layout_annotations = vectorToCell(setdiff(system_annotations, cellToVector(annotations)'));
    non_layout_lines = vectorToCell(setdiff(system_lines, cellToVector(lines)'));
    
    % Figure out how to shift blocks and annotations
    bound_shift = new_bounds - orig_bounds;
    adjustObjectsAroundLayout(non_layout_blocks, orig_bounds, bound_shift, 'block');
    adjustObjectsAroundLayout(non_layout_annotations, orig_bounds, bound_shift, 'annotation');
    
    % TODO - depending on input parameters redraw lines affected by
    % previous shifting
    redraw_lines(getfullname(system), 'autorouting', 'on')
end

function shift_sim_objects(blocks, lines, annotations, offset)
    %
    
    shiftBlocks(blocks, [offset, offset]); % Takes 1x4 vector
    shiftAnnotations(annotations, [offset, offset]); % Takes 1x4 vector
    shiftLines(lines, offset); % Takes 1x2 vector
end

function adjustObjectsAroundLayout(objects, orig_bounds, bound_shift, type)
    % objects are all of the given type
    %
    % Move objects with the shift in bounds between original and new
    % layout. The approach taken aims to keep objects in the same position
    % relative to the original layout. This approach will not handle
    % objects that were within the original bounds well, however, this is
    % not considered a big problem because of the degree of difficulty in
    % appropriately handling these cases even manually and further it's
    % also a bizarre case that should generally be avoidable. If it turns
    % out to need to be handled, a simple approach is to pick some
    % direction to shift the objects that were within the original bounds
    % and to do so as well as potentially increase the overall shift amount
    % in that direction accordingly.
    
    switch type
        case 'block'
            getBounds = @blockBounds;
            shiftObjects = @shiftBlocks;
        case 'line'
            getBounds = @lineBounds;
            shiftObjects = @shiftLines;
        case 'annotation'
            getBounds = @annotationBounds;
            shiftObjects = @shiftAnnotations;
        otherwise
            error('Unexpected object type.')
    end
    
    for i = 1:length(objects)
        object = objects{i};
        
        % Get bounds of the block
        my_bounds = getBounds(object);
        
        my_shift = [0 0 0 0];
        
        idx = 1; % Left
        if my_bounds(idx) < orig_bounds(idx)
            my_shift = my_shift + [bound_shift(idx) 0 bound_shift(idx) 0];
        end
        idx = 2; % Top
        if my_bounds(idx) < orig_bounds(idx)
            my_shift = my_shift + [0 bound_shift(idx) 0 bound_shift(idx)];
        end
        idx = 3; % Right
        if my_bounds(idx) > orig_bounds(idx)
            my_shift = my_shift + [bound_shift(idx) 0 bound_shift(idx) 0];
        end
        idx = 4; % Bottom
        if my_bounds(idx) > orig_bounds(idx)
            my_shift = my_shift + [0 bound_shift(idx) 0 bound_shift(idx)];
        end
        
        shiftObjects({object}, my_shift);
    end
end

function blocks = find_blocks_in_system(system)
    blocks = find_system(system, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'block', 'Parent', getfullname(system));
end
function annotations = find_annotations_in_system(system)
    annotations = find_system(system, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'annotation');
end
function lines = find_lines_in_system(system)
    lines = find_system(system, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'line');
end

function IsoLayout(blocks, annotations, mode)
    % Isolated layout of only the blocks and annotations given (relevant
    % lines will also be laid out, but otherwise nothing else in the system
    % is touched)
    
    if strcmp(mode, 'columnbased')
        columnBasedLayout(blocks, 'WidthMode', 'MaxColBlock', 'MethodForDesiredHeight', 'Compact', 'AlignmentType', 'Dest');
    elseif strcmp(mode, '3rdparty')
        mainLayout(blocks, annotations);
    else
        error('Unexpected mode.')
    end
    
end

function mainLayout(blocks, annotations)
    blocks = inputToNumeric(blocks);
    
    %% Make sum blocks rectangular so that they will look better
    makeSumsRectangular(blocks);
    
    %%
    % Find which blocks have no ports
    portlessBlocks = inputToNumeric(getPortlessBlocks(blocks));
    
    % Find where to place portless blocks in the final layout
    [portlessInfo, smallOrLargeHalf] = getPortlessInfo(blocks, portlessBlocks);
    
    %%
    % 1) For each block, show or do not show its name depending on the SHOW_NAMES
    % parameter.
    % 2) Create a map that contains the info about whether the block should show its
    % name
    nameShowing = getShowNameParams(blocks);
    
    %%
    % Perform initial layout using some graphing method
    % Determine which external software to use:
    %   1) MATLAB's GraphPlot objects; or
    %   2) Graphviz (requires separate install)
    % based on the configuration parameters and current version of MATLAB
    
    GRAPHING_METHOD = getAutoLayoutConfig('graphing_method', 'auto'); %Indicates which graphing method to use
    
    if strcmp(GRAPHING_METHOD, 'auto')
        % Check if MATLAB version is R2015b or newer (i.e. greater-or-equal to 2015b)
        ver = version('-release');
        ge2015b = str2num(ver(1:4)) > 2015 || strcmp(ver(1:5),'2015b');
        if ge2015b
            % Graphplot
            GraphPlotLayout(blocks);
        else
            % Graphviz
            GraphvizLayout(blocks);
        end
    elseif strcmp(GRAPHING_METHOD, 'graphplot')
        % Graphplot
        GraphPlotLayout(blocks);
    elseif strcmp(GRAPHING_METHOD, 'graphviz')
        % Graphviz
        GraphvizLayout(blocks);
    else
        ErrorInvalidConfig('graphing_method')
    end
    
    %%
    % blocksInfo -  keeps track of where to move blocks so that they can all be
    %               moved at the end as opposed to throughout all of AutoLayout
    blocksInfo = getBlocksInfo(blocks);
    
    %% Show/hide block names (the initial layout may have inadvertently set it off)
    setShowNameParams(blocks, nameShowing)
    
    %%
    % Separate portless blocks out from other blocks (they will be handled separately)
    % Go backwards to remove elements without disrupting the indices that need to be
    % checked after
    for i = length(blocksInfo):-1:1
        for j = 1:length(portlessInfo)
            if strcmp(blocksInfo(i).fullname, portlessInfo{j}.fullname)
                portlessInfo{j}.position = blocksInfo(i).position;
                blocksInfo(i) = [];
                break
            end
        end
    end
    % Replace above with the following when to deal with blocks directly
    % instead of with blocksInfo
    %[orig_blocks, blocks] = remove_portless_from_blocks(blocks, portlessBlocks)
    
    %%
    % Find relative positioning of blocks in the layout from initLayout
    layout = getRelativeLayout(blocksInfo); %layout will also take over the role of blocksInfo
    updateLayout(layout); % Only included here for feedback purposes
    
    %%
    [layout, portlessInfo] = resizeBlocks(layout, portlessInfo);
    
    layout = fixSizeOfBlocks(layout);
    
    % Update block positions according to layout that was changed by resizeBlocks()
    % and fixSizeOfBlocks()
    updateLayout(layout);
    
    % Move blocks with single inport/outport so their port is in line with
    % the source/destination port
    layout = vertAlign(layout);
    % % layout = easyAlign(layout); %old method, still relevant since it attempts to cover more cases
    
    %layout = layout2(address, layout, systemBlocks); %call layout2 after
    
    %% 
    % Align inport/outport blocks if set to do so by inport/outport rules
    system = getCommonParent(inputToCell(blocks));
    INPORT_RULE = getAutoLayoutConfig('inport_rule', 'none'); %Indicates how to place inports
    if strcmp(INPORT_RULE, 'left_align')
        % Left align the inports
        inports = find_in_blocks(blocks, 'BlockType', 'Inport');
        layout = justifyBlocks(system, layout, inports, 1);
    elseif ~strcmp(INPORT_RULE, 'none')
        ErrorInvalidConfig('inport_rule')
    end
    
    OUTPORT_RULE = getAutoLayoutConfig('outport_rule', 'none'); %Indicates how to place outports
    if strcmp(OUTPORT_RULE, 'right_align')
        % Right align the outports
        outports = find_in_blocks(blocks, 'BlockType', 'Outport');
        layout = justifyBlocks(system, layout, outports, 3);
    elseif ~strcmp(OUTPORT_RULE, 'none')
        ErrorInvalidConfig('outport_rule')
    end
    
    % Update block positions according to layout
    updateLayout(layout);
    
    %%
    % Check that sort_portless is set properly
    SORT_PORTLESS = getAutoLayoutConfig('sort_portless', 'blocktype'); %Indicates how to group portless blocks
    if ~AinB(SORT_PORTLESS, {'blocktype', 'masktype_blocktype', 'none'})
        ErrorInvalidConfig('sort_portless')
    end
    
    % Place blocks that have no ports in a line along the top/bottom or left/right
    % horizontally, depending on where they were initially in the system and the
    % config file.
    portlessInfo = repositionPortlessBlocks(portlessInfo, layout, smallOrLargeHalf);
    
    % Update block positions according to portlessInfo
    updatePortless(portlessInfo);
    
    %%
    % Move all annotations to the right of the system, if necessary
    NOTE_RULE = getAutoLayoutConfig('note_rule', 'on-right'); %Indicates what to do with annotations
    if ~(strcmp(NOTE_RULE, 'none') || strcmp(NOTE_RULE, 'on-right'))
        ErrorInvalidConfig('note_rule')
    else
        handleAnnotations(layout, portlessInfo, annotations, NOTE_RULE);
    end
    
    %%
    % Orient blocks left-to-right and place name on bottom
    %setOrientations(systemBlocks);
    setNamePlacements(blocks);
    
    %%
    % Zoom on system (if it ends up zoomed out that means there is
    % something near the borders)
    system = getCommonParent(blocks);
    set_param(system, 'Zoomfactor', 'Fit to view');
end

function updatePortless(portlessInfo)
% UPDATEPORTLESS Move blocks to their new positions designated by portlessInfo.
%
%   Inputs:
%       portlessInfo    As returned by getPortlessInfo.
%
%   Outputs:
%       N/A

    % Get blocknames and desired positions
    fullnames = {}; positions = {};
    for i = 1:length(portlessInfo)
        fullnames{end+1} = portlessInfo{i}.fullname;
        positions{end+1} = portlessInfo{i}.position;
    end

    % Move blocks to the desired positions
    moveBlocks(fullnames, positions);
end

function updateLayout(layout)
    % UPDATELAYOUT Move blocks to their new positions designated by layout.
    %
    %   Inputs:
    %       blocks  Cell array of Simulink blocks.
    %       layout  As returned by getRelativeLayout.
    %
    %   Outputs:
    %       N/A

    % Get blocknames and desired positions
    fullnames = {}; positions = {};
    for j = 1:size(layout.grid,2)
        for i = 1:layout.colLengths(j)
            fullnames{end+1} = layout.grid{i,j}.fullname;
            positions{end+1} = layout.grid{i,j}.position;
        end
    end

    % Move blocks to the desired positions
    moveBlocks(fullnames, positions);
end

function moveBlocks(blocks, positions)
    % MOVEBLOCKS Move blocks in address to the given positions.
    %
    % Inputs:
    %   blocks      Cell array of full block names.
    %   positions   Cell array of positions corresponding with blocks (i.e.
    %               blocks{i} should be moved to positions{i}; blocks and
    %               positions are of the same length).
    %               Each value should be in a vector as returned by
    %               get_param(gcb, 'Position').
    %
    % Outputs:
    %   N/A
    %
    % Example:
    %   moveBlocks('AutoLayoutDemo',{'AutoLayoutDemo/In1', ...
    %       'AutoLayoutDemo/In2'}, {[-35,50,-15,70],[-35,185,-15,205]})
    
    % Check number of arguments
    try
        assert(nargin == 2)
    catch
        error('Wrong number of arguments.');
    end

    blockLength = length(blocks);
    for k = 1:blockLength
        set_param(blocks{k}, 'Position', positions{k});

        %TODO
        %get block pos at this point, if size is less than indicated by
        %blocksInfo(z).position then may need to increase pos(3) or pos(4)
        %by ~5 as appropriate
        %(main reason to adjust size would be to ensure sufficient space
        %for text)
        %(may make sense to include this outside this function to keep this
        %general)
    end
    redraw_block_lines(blocks, 'autorouting', 'on');
end

function redraw_block_lines(blocks, varargin)
    % REDRAW_LINES Redraw all lines connecting to any of the given blocks.
    %
    % Inputs:
    %   block       Cell array of Simulink blocks.
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'Autorouting' Chooses type of automatic line routing
    %       around other blocks.
    %   Value:  'smart' - may not work, presumably depends on MATLAB
    %               version.
    %           'on'
    %           'off' - (Default).
    %
    % Outputs:
    %   N/A
    %
    % Examples:
    %   redraw_block_lines(gcbs)
    %       Redraws lines with source or dest in any of the blocks with autorouting off.
    %
    %   redraw_block_lines(gcbs, 'autorouting', 'on')
    %       Redraws lines with source or dest in any of the blocks with autorouting on.
    
    % Handle parameter-value pairs
    autorouting = 'off';
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case 'autorouting'
                assert(any(strcmp(value,{'smart','on','off'})), ['Unexpected value for ' param ' parameter.'])
                autorouting = value;
            otherwise
                error('Invalid parameter.')
        end
    end
    
    for n = 1:length(blocks)
        sys = getParentSystem(blocks{n});
        lineHdls = get_param(blocks{n}, 'LineHandles');
        if ~isempty(lineHdls.Inport)
            for m = 1:length(lineHdls.Inport)
                if lineHdls.Inport(m) ~= -1
                    srcport = get_param(lineHdls.Inport(m), 'SrcPortHandle');
                    dstport = get_param(lineHdls.Inport(m), 'DstPortHandle');
                    % Delete and re-add
                    delete_line(lineHdls.Inport(m))
                    add_line(sys, srcport, dstport, 'autorouting', autorouting);
                end
            end
        end
    end
end

function [orig_blocks, blocks] = remove_portless_from_blocks(blocks, portlessBlocks)
    orig_blocks = blocks;
    for i = length(blocks):-1:1
        for j = 1:length(portlessBlocks)
            if strcmp(getfullname(blocks(i)), getfullname(portlessBlocks(j)))
                blocks(i) = [];
                break
            end
        end
    end
end

function X = getRelativePlacements(blocks)
    % GETRELATIVEPLACEMENTS Find the placement of blocks relative to
    % eachother in a grid based on their physical positions.
    %
    % Inputs:
    %   blocks  Cell array of block names
    %
    % Outputs:
    %   
    
    %% TODO: mimic getRelativeLayout but take blocks as input
end

function blocksInfo = getBlocksInfo(blocks)
    % GETBLOCKSINFO Get a struct with name and position information of all
    % blocks in a system.
    %
    % Input:
    %   blocks                  Vector of blocks for which to get blocksInfo.
    %
    % Outputs:
    %   blocksInfo              Struct of data representing current block data.
    %   blocksInfo(i).fullname  Fullname of a block.
    %   blocksInfo(i).position  Position of a block.
    
    for i = 1:length(blocks)
        % Add names to struct
        blocksInfo(i).fullname = blocks(i);
        
        % Add positions to struct
        pos = get_param(blocks(i), 'Position');
        blocksInfo(i).position = pos;
    end
end

function GraphPlotLayout(blocks)
    % GRAPHPLOTLAYOUT Creates a GraphPlot representing given blocks using
    % MATLAB functions and then lays out the blocks according to that
    % plot.
    %
    % Input:
    %   blocks  Vector of block handles in which each block is at the
    %           top level of the same system.
    %
    % Output:
    %   N/A
    
    dg = blocksToDigraph(blocks);
    dg2 = addImplicitEdgesBetweenBlocks(blocks, dg);
    
    defaultFigureVisible = get(0, 'DefaultFigureVisible');
    set(0, 'DefaultFigureVisible', 'off');    % Don't show the figure
    p = plotSimulinkDigraph(blocks, dg2);
    set(0,'DefaultFigureVisible', defaultFigureVisible);
    
    % blocks = p.NodeLabel';
    xs = p.XData;
    ys = p.YData;
    
    % keep = ~cellfun(@isempty,regexp(blocks,'(:b$)','once'));
    % toss = ~cellfun(@isempty,regexp(blocks,'(:[io][0-9]*$)','once')); % These aren't needed anymore
    % assert(all(xor(keep, toss)), 'Unexpected NodeLabel syntax.')
    % blocks = cellfun(@(x) x(1:end-2), blocks(keep), 'UniformOutput', false);
    % xs = xs(keep);
    % ys = ys(keep);
    % % blocks(toss) = [];
    % % xs(toss) = [];
    % % ys(toss) = [];
    
    % blocks = cellfun(@(x) x(1:end-2), blocks, 'UniformOutput', false);
    
    % Set semi-arbitrary scaling factors to determine starting positions
    scale = 90; % Pixels per unit increase in x or y in the plot
    scaleBack = 3; % Scale-back factor to determine block size
    
    for i = 1:length(blocks)
        blockwidth  = scale/scaleBack;
        blockheight = scale/scaleBack;
        blockx      = scale * xs(i);
        blocky      = scale * (max(ys) + min(ys) - ys(i)); % Accounting for different coordinate system between the plot and Simulink
        
        % Keep the block centered where the node was
        left    = round(blockx - blockwidth/2);
        right   = round(blockx + blockwidth/2);
        top     = round(blocky - blockheight/2);
        bottom  = round(blocky + blockheight/2);
        
        pos = [left top right bottom];
        setPositionAL(blocks(i), pos);
    end
    
    % Try to fix knots caused by the arbitrary ordering of out/inputs to a node
    for i = 1:length(blocks)
        ph = get_param(blocks(i), 'PortHandles');
        out = ph.Outport;
        if length(out) > 1
            [snks, snkPositions, ~] = arrangeSinks(blocks(i), false);
            for j = 1:length(snks)
                if any(get_param(snks{j}, 'Handle') == blocks)
                    set_param(snks{j}, 'Position', snkPositions(j, :))
                end
            end
        end
    end
    for i = 1:length(blocks)
        ph = get_param(blocks(i), 'PortHandles');
        in = ph.Inport;
        if length(in) > 1
            [srcs, srcPositions, ~] = arrangeSources(blocks(i), false);
            for j = 1:length(srcs)
                if any(get_param(srcs{j}, 'Handle') == blocks)
                    set_param(srcs{j}, 'Position', srcPositions(j, :))
                end
            end
        end
    end
end

function h = plotSimulinkDigraph(blocks, dg)
    % PLOTSIMULINKDIGRAPH Plot a digraph representing a Simulink (sub)system in the
    %   same fashion as a Simulink diagram, i.e., layered, left-to-right, etc.
    %
    % Inputs:
    %   blocks  Vector of block handles in which each block is at the
    %           top level of the same system.
    %   dg      Digraph representation of the system sys.
    %
    % Outputs:
    %   h       GraphPlot object (see
    %           www.mathworks.com/help/matlab/ref/graphplot.html).
    
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
    % Get sources and sinks
    srcs = zeros(1,length(blocks));
    snks = zeros(1,length(blocks));
    for i = 1:length(blocks)
        switch get_param(blocks(i), 'BlockType')
            case 'Inport'
                srcs(i) = blocks(i);
            case 'Outport'
                snks(i) = blocks(i);
        end
    end
    srcs = srcs(find(srcs));
    snks = snks(find(snks));
    srcs_cell = {};
    snks_cell = {};
    for i = 1:length(srcs)
        srcs_cell{end+1} = applyNamingConvention(srcs(i));
    end
    for i = 1:length(snks)
        snks_cell{end+1} = applyNamingConvention(snks(i));
    end
    
    %%
    % Use Simulink-like plot options
    % Info on options: https://www.mathworks.com/help/matlab/ref/graph.plot.html
    ops = {'Layout', 'layered', 'Direction', 'right', 'AssignLayers', 'alap'};
    if ~isempty(srcs_cell)
        ops = [ops 'Sources' {srcs_cell}];
    end
    if ~isempty(snks_cell)
        ops = [ops 'Sinks' {snks_cell}];
    end
    
    % Plot
    h = plot(dg, ops{:});
end

function GraphvizLayout(blocks)
    % GRAPHVIZLAYOUT Perform the layout analysis on the system with
    % Graphviz.
    %
    % Inputs:
    %   blocks  Vector of block handles in which each block is at the
    %           top level of the same system.
    %
    % Outputs:
    %   N/A
    
    %%
    % Check first input
    assert(isa(blocks, 'double'), 'Blocks must be given as a vector of handles.')
    
    if ~isempty(blocks)
        sys = get_param(blocks(1), 'Parent');
        for i = 2:length(blocks)
            assert(sys == get_param(blocks(i), 'Parent'), 'Each block must be directly within the same subsystem. I.e. blocks must share a parent.')
        end
        
        assert(bdIsLoaded(bdroot(sys)), 'Simulink system provided is invalid or not loaded.')
    end
    
    %   Implementation Approach:
    %   1) Create the dotfile from the system or subsystem using dotfile_creator.
    %   2) Use autoLayout.bat/.sh to automatically create the graphviz output files.
    %   3) Use Tplainparser class to use Graphviz output to reposition Simulink (sub)system.
    
    % Get current directory
    if ~isunix
        oldDir = pwd;
        batchDir = mfilename('fullpath');
        numChars = strfind(batchDir, '\');
        if ~isempty(numChars)
            numChars = numChars(end);
            batchDir = batchDir(1:numChars-1);
        end
    else
        oldDir = pwd;
        batchDir = mfilename('fullpath');
        numChars = strfind(batchDir, '/');
        if ~isempty(numChars)
            numChars = numChars(end);
            batchDir = batchDir(1:numChars-1);
        end
    end
    
    % Change directory to predetermined batch location
    cd(batchDir);
    
    % 1) Create the dotfile from the system or subsystem using dotfile_creator.
    [filename, map] = dotfile_creator(blocks);
    
    % 2) Use autoLayout.bat/.sh to automatically create the graphviz output files.
    if ~isunix
        [~, ~] = system('autoLayout.bat'); % Suppressed output with "[~, ~] ="
    else
        [~, ~] = system('sh autoLayout.sh'); % Suppressed output with "[~, ~] ="
    end
    
    % 3) Use Tplainparser class to use Graphviz output to reposition Simulink (sub)system.
    % Do the initial layout
    g = TplainParser(blocks, filename, map);
    g.plain_wrappers;
    
    % Delete unneeded files
    dotfilename = [filename '.dot'];
    delete(dotfilename);
    plainfilename = [filename '-plain.txt'];
    pdffilename = [filename '.pdf'];
    delete(plainfilename);
    delete(pdffilename);
    
    % Change directory back
    cd(oldDir);
end

function [fullname, replacementMap] = dotfile_creator(blocks)
    % DOTFILE_CREATOR Parses a system and creates a Graphviz dotfile.
    %
    % Inputs:
    %   blocks  Vector of block handles in which each block is at the
    %           top level of the same system.
    %
    % Outputs:
    %   fullname        Name of the dotfile, as well as the resulting
    %                   Graphviz output.
    %   replacementMap  A containers.Map. Characters in block names that
    %                   aren't supported in the dotfile (values in the map)
    %                   will be replaced by another string (keys in the
    %                   map), later block names will need to be restored by
    %                   replacing the keys with the values in block names.
    %
    % Example:
    %   filename = dotfile_creator('testModel');
    
    %%
    % Check first input
    assert(isa(blocks, 'double'), 'Blocks must be given as a vector of handles.')
    
    if ~isempty(blocks)
        sys = get_param(blocks(1), 'Parent');
        for i = 2:length(blocks)
            assert(sys == get_param(blocks(i), 'Parent'), 'Each block must be directly within the same subsystem. I.e. blocks must share a parent.')
        end
        
        assert(bdIsLoaded(bdroot(sys)), 'Simulink system provided is invalid or not loaded.')
    end
    
    function string = subwidth(number)
        % Get dimensions for a SubSystem for the dotfile graph
        if number > 3
            height = 60 + (number-3) * 20 ;
        else
            height = 60;
        end
        string = ['width="40.0", height="' num2str(height) '", fixedsize=true];\n'];
    end
    
    function string = blockwidth(number, blocktype)
        % Get dimensions for an arbitrary block for the dotfile graph
        if number > 2
            height = 31 + (number-2) * 15 ;
        else
            height = 31;
        end
        if strcmp(blocktype, 'Bus Creator') ...
                || strcmp(blocktype, 'Bus Selector') ...
                ||strcmp(blocktype, 'Mux') ...
                || strcmp(blocktype, 'Demux')
            width = 9.0;
        else
            width = 30.0;
        end
        string = ['width="' num2str(width) '", height="' num2str(height) '", fixedsize=true];\n'];
    end
    
    function [newblockname, replaceMap] = replaceItems(blockname, replaceMap)
        % Get new blocknames by replacing unsupported characters with other
        % strings and update the replaceMap which defines the replacements
        replacePattern = '[^\w]|^[0-9]';
        items2Replace = regexp(blockname, replacePattern, 'match');
        for i = 1:length(items2Replace)
            replaceStr = ['badcharacterreplacement' dec2bin(items2Replace{i}, 8)];
            blockname = strrep(blockname, items2Replace{i}, replaceStr);
            replaceMap(replaceStr) = items2Replace{i};
        end
        newblockname = blockname;
    end
    
    portwidth = 'width="30.0", height="14.0", fixedsize=true];\n';
    dotfile = 'digraph {\n\tgraph [rankdir=LR, ranksep="100.0", nodesep="40.0"];\n';
    dotfile = [dotfile '\tnode [shape=record];\n'];
    replacementMap = containers.Map();
    
    % Iterate through blocks in address
    for n = 1:length(blocks)
        BlockType = get_param(blocks{n}, 'BlockType');
        Ports = get_param(blocks{n}, 'Ports');
        
        % dotfile notations for different block types
        switch BlockType
            
            case 'SubSystem'
                % dotfile notation for subsystem by finding number of inputs and outputs
                inputnum = Ports(1) + Ports(3) + Ports(4) + Ports(8);
                outputnum = Ports(2);
                blockname = get_param(blocks{n}, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(blockname, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    blockname = strrep(blockname, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                dotfile = [dotfile blockname '[label="{{'];
                for z = 1:inputnum
                    if z == inputnum
                        dotfile = [dotfile '<i' num2str(z) '>' num2str(z)];
                    else
                        dotfile = [dotfile '<i' num2str(z) '>' num2str(z) '|'];
                    end
                end
                dotfile = [dotfile '}|' blockname '|{'];
                for y = 1:outputnum
                    if y == outputnum
                        dotfile = [dotfile '<o' num2str(y) '>' num2str(y)];
                    else
                        dotfile = [dotfile '<o' num2str(y) '>' num2str(y) '|'];
                    end
                end
                c = max([inputnum outputnum]) ;
                dotfile = [dotfile '}}", ' subwidth(c)];
                
            case 'Inport'
                % Add text to the dotfile to represent the block
                blockname = get_param(blocks{n}, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(blockname, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    blockname = strrep(blockname, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                dotfile = [dotfile blockname];
                dotfile = [dotfile ' [label="{{<i1>1}|' blockname '|{<o1>1}}", ' portwidth];
                
            case 'Outport'
                % Add text to the dotfile to represent the block
                blockname = get_param(blocks{n}, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(blockname, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    blockname = strrep(blockname, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                dotfile = [dotfile blockname];
                dotfile = [dotfile ' [label="{{<i1>1}|' blockname '|{<o1>1}}", ' portwidth];
                
            otherwise
                % Add text to the dotfile to represent the block along
                % with its ports and the relative positions of the ports so
                % this information can be used
                blockname = get_param(blocks{n}, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(blockname, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    blockname = strrep(blockname, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                dotfile = [dotfile blockname ' [label="{'];
                inputnum = Ports(1);
                outputnum = Ports(2);
                if inputnum ~= 0
                    dotfile = [dotfile '{'];
                    for x = 1:inputnum
                        if x == inputnum
                            dotfile = [dotfile '<i' num2str(x) '>' num2str(x)];
                        else
                            dotfile = [dotfile '<i' num2str(x) '>' num2str(x) '|'];
                        end
                    end
                    dotfile = [dotfile '}|'];
                end
                dotfile = [dotfile blockname];
                if outputnum ~= 0
                    dotfile = [dotfile '|{'];
                    for w = 1:outputnum
                        if w == outputnum
                            dotfile = [dotfile '<o' num2str(w) '>' num2str(w)];
                        else
                            dotfile = [dotfile '<o' num2str(w) '>' num2str(w) '|'];
                        end
                    end
                    dotfile = [dotfile '}'];
                end
                blocktype = get_param(blocks{n}, 'BlockType');
                c = max([inputnum outputnum]) ;
                dotfile = [dotfile '}", ' blockwidth(c, blocktype)];
                
        end
    end
    
    % dotfile notations for connections
    for n = 1:length(blocks)
        linesH = get_param(blocks{n}, 'LineHandles');
        if ~isempty(linesH.Inport)
            for m = 1:length(linesH.Inport)
                % Find source port number and source block name
                src = get_param(linesH.Inport(m), 'SrcBlockHandle');
                srcName = get_param(src, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(srcName, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    srcName = strrep(srcName, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                srcportHandle = get_param(linesH.Inport(m), 'SrcPortHandle');
                srcport = get_param(linesH.Inport(m), 'SrcPort');
                srcportParent = get_param(srcportHandle, 'Parent');
                srcpHandles = get_param(srcportParent, 'portHandles');
                tol = 1e-6;
                if srcpHandles.Outport
                    srcoutport = srcpHandles.Outport;
                    srcport = find(abs(srcoutport- srcportHandle)<tol);
                elseif srcport
                else
                    srcport = 1;
                end
                srcPortinfo = get_param(src, 'Ports');
                srcinputnum = srcPortinfo(1);
                srcoutputnum = srcPortinfo(2);
                % Find destination block and port
                dest = get_param(linesH.Inport(m), 'DstBlockHandle');
                destName = get_param(dest, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(destName, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    destName = strrep(destName, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                destportHandle = get_param(linesH.Inport(m), 'DstPortHandle');
                destportParent = get_param(destportHandle, 'Parent');
                destpHandles = get_param(destportParent, 'portHandles');
                destport = get_param(linesH.Inport(m), 'DstPort');
                if destpHandles.Inport
                    destinport = destpHandles.Inport;
                    destport = find(abs(destinport-destportHandle)<tol);
                elseif destport
                else
                    destport = 1;
                end
                destPortinfo = get_param(dest, 'Ports');
                destinputnum = destPortinfo(1);
                destoutputnum = destPortinfo(2);
                if srcoutputnum ~= 0
                    
                    dotfile = [dotfile srcName ':o' num2str(srcport)];
                    if destinputnum ~= 0
                        dotfile = [dotfile ' -> ' destName ':i' num2str(destport) sprintf('\n')];
                    else
                        dotfile = [dotfile ' -> ' destName sprintf('\n')];
                    end
                else
                    dotfile = [dotfile srcName];
                    if destinputnum ~= 0
                        dotfile = [dotfile ' -> ' destName ':i' num2str(destport) sprintf('\n')];
                    else
                        dotfile = [dotfile ' -> ' destName sprintf('\n')];
                    end
                end
            end
        end
        % Same as above but for trigger
        if ~isempty(linesH.Ifaction)
            for m = 1:length(linesH.Ifaction)
                if strcmp(get_param(linesH.Ifaction(m), 'type'), 'port')
                    ifactionLine = get_param(linesH.Ifaction(m), 'line');
                else
                    ifactionLine = linesH.Ifaction(m);
                end
                
                % Find source port number and source block name
                src = get_param(ifactionLine, 'SrcBlockHandle');
                srcName = get_param(src, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(srcName, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    srcName = strrep(srcName, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                srcportHandle = get_param(ifactionLine, 'SrcPortHandle');
                srcport = get_param(ifactionLine, 'SrcPort');
                srcportParent = get_param(srcportHandle, 'Parent');
                srcpHandles = get_param(srcportParent, 'portHandles');
                tol = 1e-6;
                if srcpHandles.Outport
                    srcoutport = srcpHandles.Outport;
                    srcport = find(abs(srcoutport- srcportHandle)<tol);
                elseif srcport
                else
                    srcport = 1;
                end
                srcPortinfo = get_param(src, 'Ports');
                srcinputnum = srcPortinfo(1);
                srcoutputnum = srcPortinfo(2);
                
                % Find destination block and port
                dest = get_param(ifactionLine, 'DstBlockHandle');
                destName = get_param(dest, 'Name');
                pattern = '[^\w]|^[0-9]';
                itemsToReplace = regexp(destName, pattern, 'match');
                for item = 1:length(itemsToReplace)
                    replacement = ['badcharacterreplacement' dec2bin(itemsToReplace{item}, 8)];
                    destName = strrep(destName, itemsToReplace{item}, replacement);
                    replacementMap(replacement) = itemsToReplace{item};
                end
                destportHandle = get_param(ifactionLine, 'DstPortHandle');
                destportParent = get_param(destportHandle, 'Parent');
                destpHandles = get_param(destportParent, 'portHandles');
                destport = get_param(ifactionLine, 'DstPort');
                if destpHandles.Ifaction
                    destinport = destpHandles.Ifaction;
                    destport = find(abs(destinport-destportHandle)<tol);
                elseif destport
                else
                    destport = 1;
                end
                destPortinfo = get_param(dest, 'Ports');
                destinputnum = destPortinfo(1);
                destoutputnum = destPortinfo(2);
                if srcoutputnum ~= 0
                    
                    dotfile = [dotfile srcName ':o' num2str(srcport)];
                    if destinputnum ~= 0
                        dotfile = [dotfile ' -> ' destName ':i' num2str(destport) sprintf('\n')];
                    else
                        dotfile = [dotfile ' -> ' destName sprintf('\n')];
                    end
                else
                    dotfile = [dotfile srcName];
                    if destinputnum ~= 0
                        dotfile = [dotfile ' -> ' destName ':i' num2str(destport) sprintf('\n')];
                    else
                        dotfile = [dotfile ' -> ' destName sprintf('\n')];
                    end
                end
            end
        end
    end
    
    % Create edges between gotos and froms so the final graph will place
    % them closer to each other
    Gotos = find_in_blocks(blocks, 'BlockType', 'Goto');
    GotosLength = length(Gotos);
    % When a local goto is found then assume the Goto and From is connected
    for w = 1:GotosLength
        GotoTag = get_param(Gotos{w}, 'Gototag');
        Froms = find_in_blocks(blocks, 'BlockType', 'From', 'Gototag', GotoTag);
        GotoName = get_param(Gotos{w}, 'Name');
        [GotoName, replacementMap] = replaceItems(GotoName, replacementMap);
        Fromslength = length(Froms);
        for h = 1:Fromslength
            FromName = get_param(Froms{h}, 'Name');
            [FromName, replacementMap] = replaceItems(FromName, replacementMap);
            dotfile = [dotfile GotoName '->' FromName sprintf('\n') ];
        end
    end
    
    % Same as above, but for Data Stores
    Writes = find_in_blocks(blocks, 'BlockType', 'DataStoreWrite');
    WritesLength = length(Writes);
    for w = 1:WritesLength
        DataStoreName = get_param(Writes{w}, 'DataStoreName');
        Reads = find_in_blocks(blocks, 'BlockType', 'DataStoreRead', 'DataStoreName', DataStoreName);
        WriteName = get_param(Writes{w}, 'Name');
        [WriteName, replacementMap] = replaceItems(WriteName, replacementMap);
        Readslength = length(Reads);
        for h = 1:Readslength
            ReadName = get_param(Reads{h}, 'Name');
            [ReadName, replacementMap] = replaceItems(ReadName, replacementMap);
            dotfile = [dotfile WriteName '->' ReadName sprintf('\n') ];
        end
    end
    
    dotfile = [dotfile '}'];
    fullname = sys;
    pattern = '[^\w]|^[0-9]';
    itemsToReplace = regexp(fullname, pattern, 'match');
    for item = 1:length(itemsToReplace)
        fullname = strrep(fullname, itemsToReplace{item}, '');
    end
    thefilename = [fullname '.dot'];
    fid = fopen(thefilename, 'w');
    fprintf(fid,dotfile);
    fclose(fid);
end

function blocks = find_in_blocks(blocks, varargin)
    % Find blocks of matching parameters and values indicated by varargin
    % Returns a vector of block handles even if blocks was given as a cell
    % array of block paths.
    %
    % varargin is given as parameter-value pairs, blocks in the input will
    % be removed in the output if their value for a given parameter does
    % not match that indicated by the value portion of the corresponding
    % parameter-value pair.
    
    blocks = inputToNumeric(blocks);
    
    assert(mod(length(varargin),2) == 0, 'Even number of varargin arguments expected.')
    for i = length(blocks):-1:1
        keep = true;
        for j = 1:2:length(varargin)
            param = varargin{j};
            value = varargin{j+1};
            if ~strcmp(get_param(blocks(i), param), value)
                keep = false;
                break
            end
        end
        
        if ~keep
            blocks(i) = [];
        end
    end
end