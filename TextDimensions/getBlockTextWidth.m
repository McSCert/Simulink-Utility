function [neededWidth, supported] = getBlockTextWidth(block)
    %GETBLOCKTEXTWIDTH Determines appropriate block width in order to fit the
    %   text within it.
    %
    %   Inputs:
    %       block           Full name of a block (character array).
    %
    %   Outputs:
    %       neededWidth     Needed block width in order to fit its text.
    
    supported = true; % Initial assumption
    isMask = get_param(block, 'Mask');
    switch isMask
        case 'on'
            mType = get_param(block, 'MaskType');
            switch mType
                case 'DocBlock'
                    docString = 'DOC';
                    [~, docWidth] = blockStringDims(block, docString);
                    
                    docTypeString = get_param(block,'DocumentType');
                    [~, docTypeWidth] = blockStringDims(block, docTypeString);
                    
                    neededWidth = docWidth + docTypeWidth;
                otherwise
                    neededWidth = 0;
                    supported = false;
            end
        case 'off'
            bType = get_param(block, 'BlockType');
            switch bType
                case 'SubSystem'
                    inports = find_system(block, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', 'Inport');
                    
                    % % May need to consider other port types
                    %             inports = [inports; find_system(block, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', 'EnablePort')];
                    %             inports = [inports; find_system(block, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', 'TriggerPort')];
                    %             inports = [inports; find_system(block, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', 'ActionPort')];
                    
                    outports = find_system(block, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', 'Outport');
                    
                    leftWidth = 0;
                    for i = 1:length(inports)
                        string = get_param(inports{i}, 'Name');
                        [~, width] = blockStringDims(block, string);
                        if width > leftWidth
                            leftWidth = width;
                        end
                    end
                    
                    rightWidth = 0;
                    for i = 1:length(outports)
                        string = get_param(outports{i}, 'Name');
                        [~, width] = blockStringDims(block, string);
                        if width > rightWidth
                            rightWidth = width;
                        end
                    end
                    
                    if strcmp(get_param(block, 'Mask'),'on')
                        maskType = get_param(block, 'MaskType');
                        [~, blockWidth] = blockStringDims(block, get_param(block, 'Name'));
                        [~, maskWidth] = blockStringDims(block, maskType);
                        centerWidth = max(blockWidth,maskWidth);
                    else
                        %                 maskType = '';
                        centerWidth = 0;
                    end
                    
                    %             if strcmp(get_param(block,'ShowName'),'on')
                    %                 string = block;
                    %                 [~, width] = blockStringDims(block, string);
                    %                 if width > centerWidth
                    %                     centerWidth = width;
                    %                 end
                    %             end
                    
                    width = sum([leftWidth, rightWidth, centerWidth]);
                    neededWidth = width;   %To fit different blocks of text within the block
                case 'If'
                    ifExpression = get_param(block, 'ifExpression');
                    elseIfExpressions = get_param(block, 'ElseIfExpressions');
                    elseIfExpressions = strsplit(elseIfExpressions, ',');
                    if isempty(elseIfExpressions{1})
                        elseIfExpressions = {};
                    end
                    expressions = [{ifExpression} elseIfExpressions];
                    width = 0;
                    for i = 1:length(expressions)
                        [~, width] = blockStringDims(block, expressions{i});
                        if width > width
                            width = width;
                        end
                    end
                    neededWidth = width * 2;   %To fit different blocks of text within the block
                case {'Goto', 'From'}
                    string = get_param(block, 'gototag');
                    if strcmp(get_param(block,'TagVisibility'), 'local')
                        string = ['[' string ']'];
                    elseif strcmp(get_param(block,'TagVisibility'), 'scoped')
                        string = ['{' string '}'];
                    elseif strcmp(get_param(block,'TagVisibility'), 'global')
                        %Do nothing
                    else
                        msgID = 'GotoTag:UnexpectedVis';
                        msg = ['Unexpected tag visibility on ' block '.'];
                        tagVisException = MException(msgID, msg);
                        throw(tagVisException)
                    end
                    [~, neededWidth] = blockStringDims(block, string);
                case 'GotoTagVisibility'
                    string = get_param(block, 'gototag');
                    string = ['[' string ']']; % Add for good measure (ideally would know how to check what brackets if any)
                    [~, neededWidth] = blockStringDims(block, string);
                    
                case {'DataStoreRead', 'DataStoreWrite', 'DataStoreMemory'}
                    string = get_param(block, 'DataStoreName');
                    [~, neededWidth] = blockStringDims(block, string);
                case 'Constant'
                    string = get_param(block, 'Value');
                    [~, neededWidth] = blockStringDims(block, string);
                    
                case 'ModelReference'
                    string = get_param(block, 'ModelName');
                    [~, modelNameWidth] = blockStringDims(block, string);
                    
                    try
                        [inWidth, outWidth] = getModelReferencePortWidths(block);
                        defaultCenterWidth = 0;
                    catch ME
                        if strcmp(ME.identifier, 'Simulink:Commands:OpenSystemUnknownSystem')
                            string = 'Model Not Found';
                            [~, defaultCenterWidth] = blockStringDims(block, string);
                            inWidth = 0;
                            outWidth = 0;
                        elseif any(strcmp(ME.identifier, ...
                                {'Simulink:utility:InvalidBlockDiagramName', ...
                                'Simulink:LoadSave:InvalidBlockDiagramName'}))
                            string = 'Unspecified Model Name';
                            [~, defaultCenterWidth] = blockStringDims(block, string);
                            inWidth = 0;
                            outWidth = 0;
                        else
                            rethrow(ME)
                        end
                    end
                    
                    cenWidth = max([modelNameWidth, defaultCenterWidth]);
                    neededWidth = sum([cenWidth, inWidth, outWidth]);
                    
                case 'Gain'
                    string = get_param(block, 'Gain');
                    [~, neededWidth] = blockStringDims(block, string);
                    
                case 'Switch'
                    criteria = get_param(block, 'Criteria');
                    thresh = get_param(block, 'Threshold');
                    string = strrep(strrep(criteria, 'u2 ', ''), 'Threshold', thresh);
                    [~, stringWidth] = blockStringDims(block, string);
                    
                    neededWidth = ceil(2*stringWidth/5)*5+5; % Appoximate -- decided through some test cases
                otherwise
                    neededWidth = 0;
                    supported = false;
            end
        otherwise
            error('Unexpected Mask parameter value.')
    end
end

function [inWidth, outWidth] = getModelReferencePortWidths(block)
    modelName = get_param(block, 'ModelName');
    
    if ~bdIsLoaded(modelName)
        load_system(modelName);
        closeAfter = true;
    else
        closeAfter = false;
    end
    
    load_system(modelName);
    inports = find_system(modelName, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', 'Inport');
    outports = find_system(modelName, 'SearchDepth', 1, 'LookUnderMasks', 'all', 'BlockType', 'Outport');
    
    inWidth = getBiggestNameWidth(block, inports);
    outWidth = getBiggestNameWidth(block, outports);
    
    if closeAfter
        close_system(modelName);
    end
end

function biggestNameWidth = getBiggestNameWidth(block, objects)
    biggestNameWidth = 0;
    for i = 1:length(objects)
        string = get_param(objects{i}, 'Name');
        [~, width] = blockStringDims(block, string);
        if width > biggestNameWidth
            biggestNameWidth = width;
        end
    end
end