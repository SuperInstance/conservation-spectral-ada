--  Generic Conservation package body
--  Precision-parameterized conservation computations
--
--  SPDX-License-Identifier: MIT

with Ada.Numerics.Generic_Elementary_Functions;

package body Generic_Conservation is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   function Compute_Ratio
     (L : Real_Matrix;
      A : Real_Matrix) return Conservation_Value
   is
      N         : constant Integer := L'Length(1);
      Numer     : Real := 0.0;
      Denom     : Real := 0.0;
      LTPL, LTL : Real;
   begin
      for I in L'Range(1) loop
         for J in L'Range(2) loop
            LTPL := 0.0;
            LTL  := 0.0;
            for K in L'Range(1) loop
               LTPL := LTPL + L (I, K) * A (K, J) * L (K, J);
               LTL  := LTL  + L (I, K) * L (K, J);
            end loop;
            Numer := Numer + LTPL;
            Denom := Denom + LTL;
         end loop;
      end loop;

      if abs Denom < 1.0e-10 then
         return 0.0;
      end if;

      return Conservation_Value (Numer / Denom);
   end Compute_Ratio;

   function Trace (M : Real_Matrix) return Real is
      T : Real := 0.0;
   begin
      for I in M'Range(1) loop
         T := T + M (I, I);
      end loop;
      return T;
   end Trace;

   function Frobenius_Norm (M : Real_Matrix) return Real is
      Sum : Real := 0.0;
   begin
      for I in M'Range(1) loop
         for J in M'Range(2) loop
            Sum := Sum + M (I, J) ** 2;
         end loop;
      end loop;
      return Sqrt (Sum);
   end Frobenius_Norm;

   function Is_Symmetric
     (M         : Real_Matrix;
      Tolerance : Real := 1.0e-6) return Boolean
   is
   begin
      for I in M'Range(1) loop
         for J in M'Range(2) loop
            if abs (M (I, J) - M (J, I)) > Tolerance then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Symmetric;

end Generic_Conservation;
