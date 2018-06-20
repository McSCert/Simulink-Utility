function [param1,param2,param3] = template_to_parse_param_value_pairs(varargin)
    % Input:
    %   varargin	Parameter-Value pairs as detailed below.
    %
    % Parameter-Value pairs:
    %   Parameter: 'Param1'
    %   Value:  {'Default'} - (Default) Chooses default option.
    %           {'Option2'} - Chooses the 2nd option.
	%	Parameter: 'Param2'
    %   Value: Any number. Default: 1.
    %   Parameter: 'Param3'
	%	Value:  Some cell array. Default: {1, 'default'}.
    
    % Handle parameter-value pairs
    param1 = lower('Default');
    param2 = 1;
    param3 = {1, 'default'};
    assert(mod(length(varargin),2) == 0, 'Even number of varargin arguments expected.')
    for i = 1:2:length(varargin)
        param = lower(varargin{i});
        value = lower(varargin{i+1});
        
        switch param
            case 'param1'
                assert(any(strcmp(value,{'default','option2'})), ...
                    ['Unexpected value for ' param ' parameter.'])
                param1 = value;
            case 'param2'
                param2 = value;
            case 'param3'
                param3 = value;
            otherwise
                error('Invalid parameter.')
        end
    end
end