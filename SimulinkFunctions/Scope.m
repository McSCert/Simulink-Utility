classdef Scope < uint32
    % Scope values, for readability
   enumeration
      Global (0)    % Function visibility: global
      Scoped (1)    % Function visibility: scoped; Placement: root
      Local  (2)    % Function visibility: scoped; Placement: subsystem
   end
end