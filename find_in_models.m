function out = find_in_models(modelname,varargin)
%FIND_IN_MODELS Search full block diagram hierarchy
%  Wrapper for find_system which searches the full block diagram hierarchy,
%  following library links and model references.  The contents of masked systems
%  will be searched only if the LookUnderMasks option is supplied.
%
% out = find_in_models(modelname,varargin);
% out = find_in_models(modelhandle,varargin);
%
% The first input must be the name or numeric handle of a block diagram.
% Additional arguments are the same as those for find_system.  If a SearchDepth 
% is specified, this will be applied when searching each model in the hierarchy.
%
% The return value will be a cell array of strings if:
%   1) the first input (modelname) is a string
%   2) the "FindAll" option is absent or "off".
% Otherwise the return value will be a numeric array.
%
% However, note that if strings are returned, any block diagrams which are loaded
% during the search will be closed again to save memory.
% If numeric handles are returned then the block diagrams will be retained in
% memory, though they may not be visible.  Use:
%    find_system('SearchDepth',0)
% to find the list of block diagrams which are in memory.
%
% Examples:
%   To find all Gain blocks involved in the simulation:
%     names = find_in_models('mymodel','BlockType','Gain');
%
%   To find all lines with name "voltage":
%     handles = find_in_models('mymodel','FindAll','on','Type','line','Name','voltage')
%
%   To find all models in the simulation which have buffer reuse turned off:
%     names = find_in_models('mymodel','SearchDepth',0,'BufferReuse','off')

% Copyright (c) 2016, The MathWorks, Inc. All rights reserved.
% Downloaded from: https://www.mathworks.com/matlabcentral/fileexchange/15707-find-in-models--search-the-entire-block-diagram-hierarchy

    if ~ischar(modelname) && ( ~isnumeric(modelname) || numel(modelname)~=1 )
        error('Simulink:find_in_models:BadModelSpecifier',...
            'First input must be single model name or handle');
    end

    % First guess at whether we need to close any block diagrams we load
    close_after_search = ischar(modelname);

    % The list of names of block diagrams currently in memory
    loaded_mdls = find_system('SearchDepth',0);
    
    % The list of block diagrams we've searched already, to avoid duplication
    % of effort where a block diagram appears in multiple locations in the hierarchy.
    searched_mdls = {};
    
    % Fix: Change all args to str (M. Jaskolka)
    varargin = cellfun(@num2str,varargin,'un',0);
    % Run the search.
    out = i_search(modelname,varargin{:});
    
    if close_after_search
        % Close any block diagrams which are now open but weren't open to
        % start with.  Since we closed models after we searched them, this will
        % only include libraries.
        now_loaded = find_system('SearchDepth',0);
        for k=1:numel(now_loaded)
            if ~ismember(now_loaded{k},loaded_mdls)
                close_system(now_loaded{k},0);
            end
        end
    end
    
    %-----------------------------------------------
    % Peforms the search on the specified model and any models it references.
    function out = i_search(thismodel,varargin)
        
        % Check whether we need to load this model.
        if ischar(thismodel)
            isloaded = ismember(thismodel,loaded_mdls);
            if ~isloaded
                load_system(thismodel);
            end
        end
        % Perform the search.
        out = find_system(thismodel,'FollowLinks','on',varargin{:});
        if close_after_search && isnumeric(out)
            % We supplied a name but got numeric handles back.  The caller must
            % have specified the "FindAll" option.  We can't close models after
            % searching them now, because that would make the handles invalid.
            close_after_search = false;
        end
        % Determine from the inputs whether we are following library links.
        [follow_links,ind] = ismember('FollowLinks',varargin);
        if follow_links && nargin>ind(1)
            follow_links = strcmpi(varargin{ind+1},'on');
        end
        if follow_links
            extra_args = {'FollowLinks','on'};
        else
            extra_args = {};
        end
        % Look for any Model References, following library links as
        % appropriate.
        mdlrefs = find_system(thismodel,'LookUnderMasks','on',...
                        extra_args{:},'BlockType','ModelReference');
        if ~isempty(mdlrefs)
            % Find the names of the referenced models
            mdls = get_param(mdlrefs,'ModelName');
            others = cell(size(mdls));
            for i=1:numel(mdls)
                submodel = mdls{i};
                submodelname = submodel; % keep a copy of the name
                if ~ismember(submodelname,searched_mdls)
                    % We haven't searched this model already.
                    if ~ischar(thismodel)
                        % We need to supply numeric handles to find_system.  First
                        % make sure that this model is loaded.
                        if ~ismember(submodel,loaded_mdls)
                            load_system(submodel);
                            loaded_mdls{end+1} = submodel; %#ok (growing in a loop, but hard to avoid)
                        end
                        % Now get the handle.
                        submodel = get_param(submodel,'Handle');
                    end
                    % Now search the model.
                    others{i} = i_search(submodel,varargin{:});
                    % Record the fact that we've already searched this model,
                    % so that we don't search it again.
                    searched_mdls{end+1} = submodelname; %#ok (growing in a loop, but hard to avoid)
                end
            end
            % Combine results for this model and all the models it references.
            out = vertcat(out,others{:}); %#ok (growing in a loop, but hard to avoid)
        end
        % If we're returning strings, close this model to free the memory.
        % This may leave libraries in memory, but that will save us loading them
        % again if they're used by another model, and we'll close them at the end.
        if close_after_search
            if ~isloaded
                close_system(thismodel,0);
            end
        end
    end
end