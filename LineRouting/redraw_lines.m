function redraw_lines(sys, varargin)
    % REDRAW_LINES Redraw all lines in the system.
    %
    %   Inputs:
    %       sys         Simulink system path name.
    %       varargin	Parameter-Value pairs as detailed below.
    %
    %   Parameter-Value pairs:
    %       Parameter: 'Autorouting' Chooses type of automatic line routing
    %               around other blocks.
    %       Value:  'smart' - may not work, presumably depends on MATLAB
    %                         version.
    %               'on'
    %               'off' - (Default).
    %
    %   Outputs:
    %       N/A
    %
    %   Examples:
    %       redraw_lines(gcs)
    %           Redraws lines in the current system with autorouting off.
    %
    %       redraw_lines(gcs, 'autorouting', 'on')
    %           Redraws lines in the current system with autorouting on.
    
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
    
    allBlocks = get_param(sys, 'Blocks');
    for n = 1:length(allBlocks)
        allBlocks{n} = strrep(allBlocks{n}, '/', '//');
        lineHdls = get_param([sys, '/', allBlocks{n}], 'LineHandles');
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