--  Eigen Package Specification
--  Eigendecomposition with range checking and safety guarantees
--
--  SPDX-License-Identifier: MIT

package Eigen is

   pragma Elaborate_Body (Eigen);

   Max_Dimension : constant := 1000;

   subtype Eigen_Index is Integer range 1 .. Max_Dimension;

   type Real_Vector is array (Eigen_Index range <>) of Float;
   type Real_Matrix is array (Eigen_Index range <>,
                              Eigen_Index range <>) of Float;

   type Eigenvalue_Array is array (Eigen_Index range <>) of Float;

   --  Result of eigendecomposition
   type Decomposition_Result (N : Eigen_Index) is record
      Values  : Eigenvalue_Array (1 .. N);
      Conv    : Boolean;  -- did it converge?
      Iters   : Integer;  -- iterations used
   end record;

   --  QR-based eigendecomposition for symmetric matrices
   function QR_Decompose
     (Matrix     : Real_Matrix;
      Max_Iter   : Integer := 200;
      Tolerance  : Float   := 1.0e-8) return Decomposition_Result
   with
     Pre => Matrix'Length(1) = Matrix'Length(2) and then
            Matrix'Length(1) >= 1;

   --  Power iteration for dominant eigenvalue
   function Power_Iteration
     (Matrix     : Real_Matrix;
      Max_Iter   : Integer := 300;
      Tolerance  : Float   := 1.0e-8) return Float
   with
     Pre => Matrix'Length(1) = Matrix'Length(2) and then
            Matrix'Length(1) >= 1;

   --  Find second-smallest eigenvalue (Fiedler value)
   function Fiedler_Value
     (Matrix : Real_Matrix) return Float
   with
     Pre => Matrix'Length(1) = Matrix'Length(2) and then
            Matrix'Length(1) >= 2;

   Singular_Matrix : exception;

end Eigen;
