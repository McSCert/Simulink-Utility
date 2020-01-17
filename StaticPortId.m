classdef StaticPortId
    % Object that uniquely identifies a port. Can be used to find the handle of
    % a port across different sessions with a model. This identifier is liable
    % to fail if the model is modified.
    properties
        Parent      % Fullname of the parent block.
        %portType    % Type of port.
        PortField   % Name of corresponding field within a block's PortHandles.
        PortNumber  % Port number of the port.
    end
    methods
        function staticId = StaticPortId(handle)
            % Creates static port id given the current handle (dynamic id).
            
            staticId.Parent = get_param(handle, 'Parent');
            staticId.PortField = staticId.getPortField(staticId.Parent, handle);
            %obj.portType = get_param(handle, 'PortType');
            staticId.PortNumber = get_param(handle, 'PortNumber');
        end
        
        function handle = getHandle(staticId)
            portStruct = get_param(staticId.Parent, 'PortHandles');
            phs = portStruct.(staticId.PortField);
            for i = 1:length(phs)
                if get_param(phs(i), 'PortNumber') == staticId.PortNumber
                    handle = phs(i);
                    break
                end
            end
        end
    end
    methods(Static)
        function portField = getPortField(block, handle)
            portStruct = get_param(block, 'PortHandles');
            fieldsCell = fields(portStruct);
            for i = 1:length(fieldsCell)
                field = fieldsCell{i};
                phs = portStruct.(field);
                for j = 1:length(phs)
                    if phs(j) == handle
                        portField = field;
                        return
                    end
                end
            end
            portField = ''; % Something went wrong.
        end
        
        function portIds = ports2portIds(ports)
            % PORTS2PORTIDS Convert vector of ports to cell array of
            % StaticPortId objects.
            
            portIds = cell(1, length(ports));
            for i = 1:length(ports)
                portIds{i} = StaticPortId(ports(i));
            end
        end
        
        function ports = portIds2ports(portIds)
            % PORTIDS2PORTS Convert cell array of StaticPortId objects to vector
            % of ports.

            ports = zeros(length(portIds), 1);
            for i = 1:length(portIds)
                ports(i) = portIds{i}.getHandle;
            end
        end
    end
end