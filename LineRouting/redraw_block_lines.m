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