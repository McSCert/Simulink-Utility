function convertBranches2Goto(address, varargin)
    % CONVERTBRANCHES2GOTO Convert all branching signal lines in address into a
    % goto/from connections.
    %
    %   Inputs:
    %       address     Simulink system name or path.
    %       varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'BaseTag'
    %   Value: Char array. All tags of created gotos/froms begin with the
    %          base tag and are followed with a number. Default: 'Tag'.
    %	Parameter: 'SelectedOnly'
    %	Value:  {'on'} - Only selected lines may be replaced with
    %                    gotos/froms.
    %           {'off'} - (Default) All branched lines at address will be
    %                     considered.
    %
    %   Examples:
    %       % open some system with at least 1 branching line
    %       convertBranches2Goto(gcs)
    %           All branching lines in the current Simulink system are
    %           replaced with goto/from blocks with the tag 'Tag#'
    %           replacing # with 1,2,... skipping options that are already
    %           in use.
    
    % Get base tag
    baseTag = 'Tag';
    selectedOnly = 'off';
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = varargin{i+1};
        
        switch param
            case 'basetag'
                baseTag = value;
            case 'selectedonly'
                selectedOnly = lower(value);
            otherwise
                error('Invalid parameter.')
        end
    end
    
    % Get handles of all branched lines
    if strcmp(selectedOnly, 'on')
        branchedLines = find_system(gcs,'FindAll','on','Type','line','SegmentType','trunk','Selected','on');
    elseif strcmp(selectedOnly, 'off')
        branchedLines = find_system(gcs,'FindAll','on','Type','line','SegmentType','trunk');
    else
        error('Unexpected parameter value for SelectedOnly.')
    end
    for i = length(branchedLines):-1:1
        if length(get_param(branchedLines(i),'DstPortHandle')) <= 1
            branchedLines(i) = [];
        end
    end
    
    % Run line2Goto on each branched line
    i = 1;
    while ~isempty(branchedLines)
        lh = branchedLines(1);
        tag = [baseTag num2str(i)];
        if gotofromConflictCheck(address,tag)
            line2Goto(address, lh, tag);
            branchedLines(1) = [];
        end
        i = i + 1;
    end
end

function [bool, msg, offenders] = gotofromConflictCheck(address, tag)
    % Outputs
    %   bool    Logical value indicating if the address is free to use new
    %           goto and from blocks with the given tag. true when the
    %           address is free of conflict and false otherwise.
    %   msg     Char array describing the cause of the conflict. When there
    %           are multiple causes, only the first found will be given.
    %           Empty if there is no conflict.
    %   offenders   List of blocks which cause the conflict. Empty if there
    %               is no conflict.
    
    % Default assumptions
    bool = true;
    msg = '';
    offenders = {};
    
    % Check for conflicts with existing gotos with the same name
    conflictLocalGotos = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto', 'GotoTag', tag);
    
    conflictsGlobalGotos = find_system(bdroot(address), 'BlockType', 'Goto', 'TagVisibility', 'global', 'GotoTag', tag);
    
    allScopedGotos = find_system(bdroot(address), 'BlockType', 'Goto', 'TagVisibility', 'scoped', 'GotoTag', tag);
    belowScopedGotos = find_system(address, 'BlockType', 'Goto', 'TagVisibility', 'scoped', 'GotoTag', tag);
    conflictsScopedGotos = setdiff(allScopedGotos, belowScopedGotos);
    
    if ~isempty(conflictLocalGotos)
        bool = false;
        msg = [' Goto block "', tag, '" already exists locally:'];
        offenders = conflictLocalGotos;
    elseif ~isempty(conflictsGlobalGotos)
        bool = false;
        msg = [' Goto block "' tag '" overlaps with existing global goto:'];
        offenders = conflictsGlobalGotos;
    elseif ~isempty(conflictsScopedGotos)
        bool = false;
        msg = [' Goto block "' tag '" overlaps with existing scoped goto(s):'];
        offenders = conflictsScopedGotos;
    end
    
    % Check for conflicts with existing froms with the same name
    conflictLocalFroms = find_system(address, 'SearchDepth', 1, 'BlockType', 'From', 'GotoTag', tag);
    if ~isempty(conflictLocalFroms) && isempty(conflictLocalGotos)
        bool = false;
        msg = [' From block "', tag, '" already exists locally:'];
        offenders = conflictLocalFroms;
    end
end