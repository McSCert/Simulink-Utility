function redraw_block_lines(blocks, varargin)
    % REDRAW_LINES Redraw all lines connecting to any of the given blocks.
    %
    % Inputs:
    %   block       List (cell array or vector) of Simulink blocks
    %               (fullnames or handles).
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
    
    %
    blocks = inputToNumeric(blocks);
    
    %
    for n = 1:length(blocks)
        block = blocks(n);
        sys = getParentSystem(block);
        
        % Get the block's lines.
        lineHdls = get_param(block, 'LineHandles');
        fields = fieldnames(lineHdls);
        for i = 1:length(fields)
            field = fields{i};
            lines = getfield(lineHdls, field);
            for j = 1:length(lines)
                line = lines(j);
                if line ~= -1
                    % Redraw line.
                    
                    srcport = get_param(line, 'SrcPortHandle');
                    dstports = get_param(line, 'DstPortHandle');
                    % Delete and re-add.
                    delete_line(line)
                    for k = 1:length(dstports)
                        dstport = dstports(k);
                        add_line(sys, srcport, dstport, 'autorouting', autorouting);
                    end
                end
            end
        end
    end
end