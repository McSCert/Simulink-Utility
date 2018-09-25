function phDataTypeStruct = findPortDataTypes(block)
    % FINDPORTDATATYPES Finds the data type of ports of a given Simulink block.
    % First tries to get the datatype by compiling the model containing the
    % block if necessary and checking the block's CompiledPortDataTypes
    % parameter and if that fails will use the getDataType function which may
    % yield less accurate results.
    %
    % Inputs:
    %   block               Simulink block fullname or handle.
    %
    % Outputs:
    %   phDataTypeStruct    Struct with fields as types of ports and values as
    %                       cell arrays of elements representing the datatypes
    %                       of the ports of that type.
    
    try
        model = bdroot(block);
        
        initSimStatus = get_param(bdroot(block),'SimulationStatus');
        
        if strcmp(initSimStatus, 'paused')
            phDataTypeStruct = get_param(block, 'CompiledPortDataTypes');
        else
            eval([model, '([], [], [], ''compile'');']);
            phDataTypeStruct = get_param(block, 'CompiledPortDataTypes');
            eval([model, '([], [], [], ''term'');']);
        end
    catch
        if ~strcmp(initSimStatus, 'paused') && ...
                strcmp(get_param(bdroot(block),'SimulationStatus'), 'paused')
            eval([model, '([], [], [], ''term'');']);
        end
        
        phStruct = get_param(block, 'PortHandles');
        phDataTypeStruct = phStruct; % This is just to give the structure, values will all be overwritten
        fieldNames = fields(phStruct);
        
        for i = 1:length(fieldNames)
            f = fieldNames{i};
            
            values = getfield(phStruct, f);
            
            if isempty(values)
                portDataTypes = [];
            else
                portDataTypes = cell(1,length(values));
                for j = 1:length(values)
                    dt = getDataType(values(j));
                    if length(dt) == 1 && iscell(dt)
                        dt = dt{1};
                    end
                    portDataTypes{j} = dt;
                end
            end
            
            phDataTypeStruct = setfield(phDataTypeStruct, f, portDataTypes);
        end
    end
end