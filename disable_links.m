function linkedSubs = disable_links(sys)
    % DISABLE_LINKS Disables all links within given system.
    %
    % sys           System to disable links within.
    % linkedSubs    Cell array of subsystems which still have a LinkStatus other
    %               than none.
    
    subs = find_system(sys, 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
        'Variants', 'AllVariants', 'IncludeCommented', 'on', ...
        'BlockType', 'SubSystem');%, 'LinkStatus', 'resolved');
    
    for i = 1:length(subs)
        if strcmp(get_param(subs{i}, 'LinkStatus'), 'resolved')
            set_param(subs{i}, 'LinkStatus', 'none');
        end
    end
    
    linkedSubs = {};
    for i = 1:length(subs)
        ls = get_param(subs{i}, 'LinkStatus');
        if ~strcmp(ls, 'none')
            linkedSubs{end+1} = subs{i};
        end
    end
end