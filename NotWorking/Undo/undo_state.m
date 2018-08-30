classdef undo_state
    properties
        state
        subStates
    end
    methods
        function obj = undo_state(sys, varargin)
            warning(['While this may be useful for reverting changes ', ...
                'resulting from use of MATLAB code, it gives no ', ...
                'guarantee that it will be able to correctly revert ', ...
                'any changes that are made.'])
            
            obj.state = save(sys,varargin);
        end
    end
    methods(Static)
        function state =  save(sys, varargin)
            
            % Go through parameter value pairs
            rememberDepth = '';
            for i = 1:2:length(varargin)
                param = lower(varargin{i});
                value = lower(varargin{i+1});
                
                switch param
                    case 'RememberDepth'
                        rememberDepth = value;
                    otherwise
                        error('Invalid parameter.')
                end
            end
            
            if strcmp(rememberDepth,'')
                subs = find_system(sys, ...
                    'BlockType','SubSystem'); % Probably still need to consider masks and linked systems
            else
                subs = find_system(sys, ...
                    'SearchDepth',rememberDepth, ...
                    'BlockType','SubSystem'); % Probably still need to consider masks and linked systems
            end
            
            subStates = cell(1,length(subs));
            for i = 1:length(subs)
                subStates{i} = undo_state(sys);
            end
            
            state = save_aux(sys);
        end
        function state = save_aux(sys)
            % ???
            % Record all objects (blocks,lines,annotations,ports) with their full parameter list?
            % What about blocks that might be deleted? -- not necessary in all cases
            % Also record model parameters
            
            blocks = find_system(); % find blocks
            
        end
        function success = undo(sys)
            % ???
            % Go through parameters and 
        end
    end
end