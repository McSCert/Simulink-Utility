function dstBlock = getSubPortDst(subsystem, subPort)
% GETSUBPORTDST Determine the next block for a signal going into a 
% subsystem block.

    portType = subPort.PortType;
    switch portType
        case 'outport'
            dstBlock = [];
        case 'enable'
            dstBlock = getSpecialPortDst(subsystem, 'EnablePort');
        case 'trigger'
            dstBlock = getSpecialPortDst(subsystem, 'TriggerPort');
        case 'state'
            dstBlock = getSpecialPortDst(subsystem, 'StatePort');
        case 'ifaction'
            dstBlock = getSpecialPortDst(subsystem, 'ActionPort');
        case 'inport'
            dstBlock = find_system(subsystem, 'SearchDepth', 1, ...
                'LookUnderMasks', 'all', 'BlockType', 'Inport', 'Port',...
                num2str(subPort.PortNumber));

            if length(dstBlock) > 1
                % This case should not occur, as only one matching Inport 
                % should be in the subsystem
                error('mapDataTypes found too many matching Inports. Something went wrong.');
            elseif length(dstBlock) < 1
                % This case may happen in some cases where the port is on a 
                % masked SubSystem, the precise cause was not clear

                % The following line is removed, but can be put back in if a better fix 
                % is put in place for the masked SubSystem issue.
                %error('mapDataTypes found no matching inports. Something went wrong.');
                dstBlock = [];
            end
    end
end

function dstBlock = getSpecialPortDst(subsystem, blockType)
% GETSPECIALPORTDST For use in getSubPortDst, returns the *only* block of
% blockType in subsystem. Throws an exception if there was more than one 
% block of blockType in subsystem.

% BlockTypes this is intended to be used with include:
% EnablePort, TriggerPort, StatePort, and ActionPort

    dstBlock = find_system(subsystem, 'SearchDepth', 1, 'LookUnderMasks',...
        'all', 'BlockType', blockType);

    % The following exceptions should only occur if getSpecialPortDst is
    % used improperly, as the types it is intended to be used with should
    % only appear once per subsystem
    if length(dstBlock) > 1
        exceptionStr = ['Multiple blocks of type ', blockType, ' were not expected.'];
        error(exceptionStr);
    elseif length(dstBlock) < 1
        exceptionStr = ['One block of type ', blockType, ' was expected, but 0 were found.'];
        error(exceptionStr);
    end
end