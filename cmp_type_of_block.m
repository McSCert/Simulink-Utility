function bool = cmp_type_of_block(block1, block2)
    % CMP_TYPE_OF_BLOCK Compares if 2 blocks have the same type. THIS DOES NOT
    % REFER SPECIFICALLY TO BLOCK TYPE. This refers to block type as well
    % as mask type.
    %
    % Inputs:
    %   block1  Simulink block fullname or handle. May also be a cell
    %           array or vector of blocks.
    %   block2  Simulink block fullname or handle. May also be a cell
    %           array or vector of blocks.
    %
    % Output:
    %   bool    Logical true if input blocks have the same mask and block
    %           type. If block1 has length > 1 and block2 has length == 1
    %           then bool will have the same length as block1 and will
    %           perform the comparison of block2 with each element in
    %           block1. Likewise if block2 has length > 1 and block1 has
    %           length == 1. If block1 and block2 have length > 1 then they
    %           must have the same length and the result will do an
    %           element-wise comparison.
    
    bType1 = get_param(block1, 'BlockType');
    bType2 = get_param(block2, 'BlockType');
    
    mType1 = get_param(block1, 'MaskType');
    mType2 = get_param(block2, 'MaskType');

    bool = and(strcmp(bType1, bType2), strcmp(mType1, mType2));
end