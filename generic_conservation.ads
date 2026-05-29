--  Generic Conservation package
--  Works with any floating-point precision
--
--  SPDX-License-Identifier: MIT

generic
   type Real is digits <>;
package Generic_Conservation is

   subtype Conservation_Value is Real range -100.0 .. 100.0;

   type Real_Vector is array (Integer range <>) of Real;
   type Real_Matrix is array (Integer range <>, Integer range <>) of Real;

   --  Compute conservation ratio for arbitrary precision
   function Compute_Ratio
     (L : Real_Matrix;
      A : Real_Matrix) return Conservation_Value
   with
     Pre => L'Length(1) = L'Length(2) and then
            A'Length(1) = A'Length(2) and then
            L'Length(1) = A'Length(1);

   --  Compute trace of a matrix
   function Trace (M : Real_Matrix) return Real
   with Pre => M'Length(1) = M'Length(2);

   --  Compute Frobenius norm
   function Frobenius_Norm (M : Real_Matrix) return Real;

   --  Check symmetry within tolerance
   function Is_Symmetric
     (M         : Real_Matrix;
      Tolerance : Real := 1.0e-6) return Boolean
   with Pre => M'Length(1) = M'Length(2);

end Generic_Conservation;
