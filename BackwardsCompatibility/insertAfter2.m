function s = insertAfter2(str, pos, text)
% INSERTAFTER Insert substring after specified position.
%    S = INSERTAFTER(STR, START_STR, NEW_TEXT) inserts NEW_TEXT into STR
%    after the substring specified by START_STR and returns the result as
%    S.
    p = strfind(str, pos);
    s = [str(1:p+1) text str(p+2:end)];
end