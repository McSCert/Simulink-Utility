function match = matchSimFcn(blk)
% MATCHSIMFCN For a Simulink Function find its corresponding Function Caller.
% For a Simulink Function Caller, find its corresponding Simulink Function.
%
%   Inputs:
%       blk     Simulink Function or Function Caller block pathname or handle.
%
%   Outputs:
%       match   Corresponding Simulink Function or Function Caller pathname(s).

    blktype = get_param(blk, 'BlockType');
    sys = get_param(blk, 'Parent');
    if strcmp(blktype, 'FunctionCaller')
        caller_prototype = get_param(blk, 'FunctionPrototype');
        [fcns, prototype] = getCallableFunctions(sys);
        idx = contains2(prototype, caller_prototype);
        match = fcns{idx};             
    elseif isSimulinkFcn(blk)
        match = findCallers(blk);
    end