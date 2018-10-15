function b = any2(vector)
% ANY2 True if any element of a vector is a nonzero number.

   found_idx = find(vector);
   if found_idx > 0
       b = true;
   else
       b = false;
   end
end