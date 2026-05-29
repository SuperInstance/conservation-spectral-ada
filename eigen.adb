--  Eigen Package Body
--  Eigendecomposition implementations with safety checks
--
--  SPDX-License-Identifier: MIT

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Eigen is

   ---------------------------------------------------------------------------
   --  QR Decompose: iterative QR algorithm for eigenvalues of symmetric M
   ---------------------------------------------------------------------------

   function QR_Decompose
     (Matrix     : Real_Matrix;
      Max_Iter   : Integer := 200;
      Tolerance  : Float   := 1.0e-8) return Decomposition_Result
   is
      N : constant Eigen_Index := Eigen_Index (Matrix'Length(1));
      Result : Decomposition_Result (N);

      subtype Idx is Integer range 1 .. Integer (N);
      type Matrix_N is array (Idx, Idx) of Float;

      A, Q, R, Temp : Matrix_N;
      Mu, Sum, Norm, C, S, Tau : Float;

   begin
      --  Copy input to 1-based working matrix
      for I in Idx loop
         for J in Idx loop
            A (I, J) := Matrix (Matrix'First(1) + I - 1,
                                Matrix'First(2) + J - 1);
         end loop;
      end loop;

      --  Initialize eigenvectors to identity
      for I in Idx loop
         for J in Idx loop
            if I = J then
               Q (I, J) := 1.0;
            else
               Q (I, J) := 0.0;
            end if;
         end loop;
      end loop;

      Result.Conv  := False;
      Result.Iters := 0;

      for Iter in 1 .. Max_Iter loop
         Result.Iters := Iter;

         --  Wilkinson shift
         Mu := 0.0;
         if N >= 2 then
            declare
               D  : constant Float := (A (N - 1, N - 1) - A (N, N)) / 2.0;
               Sg : Float;
            begin
               if D >= 0.0 then
                  Sg := 1.0;
               else
                  Sg := -1.0;
               end if;
               Mu := A (N, N) -
                 A (N, N - 1) * A (N, N - 1) /
                 (D + Sg * Sqrt (D * D + A (N, N - 1) ** 2));
            end;
         end if;

         --  Apply shift
         for I in Idx loop
            A (I, I) := A (I, I) - Mu;
         end loop;

         --  QR via Givens rotations
         R := A;
         for J in 1 .. Integer (N) - 1 loop
            for I in J + 1 .. Integer (N) loop
               if abs R (I, J) > 1.0e-15 then
                  Norm := Sqrt (R (J, J) ** 2 + R (I, J) ** 2);
                  C := R (J, J) / Norm;
                  S := R (I, J) / Norm;

                  for K in J .. Integer (N) loop
                     Tau    := C * R (J, K) + S * R (I, K);
                     R (I, K) := -S * R (J, K) + C * R (I, K);
                     R (J, K) := Tau;
                  end loop;

                  for K in Idx loop
                     Tau    := C * Q (K, J) + S * Q (K, I);
                     Q (K, I) := -S * Q (K, J) + C * Q (K, I);
                     Q (K, J) := Tau;
                  end loop;
               end if;
            end loop;
         end loop;

         --  A = R * Q + mu * I
         Temp := (others => (others => 0.0));
         for I in Idx loop
            for J in Idx loop
               Sum := 0.0;
               for K in Idx loop
                  Sum := Sum + R (I, K) * Q (K, J);
               end loop;
               Temp (I, J) := Sum;
            end loop;
         end loop;
         A := Temp;

         --  Remove shift
         for I in Idx loop
            A (I, I) := A (I, I) + Mu;
         end loop;

         --  Check convergence: off-diagonal Frobenius norm
         Sum := 0.0;
         for I in Idx loop
            for J in Idx loop
               if I /= J then
                  Sum := Sum + A (I, J) ** 2;
               end if;
            end loop;
         end loop;

         if Sqrt (Sum) < Tolerance then
            Result.Conv := True;
            exit;
         end if;
      end loop;

      --  Extract eigenvalues (diagonal of A)
      for I in Idx loop
         Result.Values (Eigen_Index (I)) := A (I, I);
      end loop;

      return Result;
   end QR_Decompose;

   ---------------------------------------------------------------------------
   --  Power iteration
   ---------------------------------------------------------------------------

   function Power_Iteration
     (Matrix     : Real_Matrix;
      Max_Iter   : Integer := 300;
      Tolerance  : Float   := 1.0e-8) return Float
   is
      N     : constant Integer := Matrix'Length(1);
      X     : array (1 .. Max_Dimension) of Float := (others => 0.0);
      Y     : array (1 .. Max_Dimension) of Float;
      Norm  : Float;
      Lambda, Prev_Lambda : Float := 0.0;
   begin
      X (1) := 1.0;

      for Iter in 1 .. Max_Iter loop
         Norm := 0.0;
         for I in 1 .. N loop
            Y (I) := 0.0;
            for J in 1 .. N loop
               Y (I) := Y (I) +
                 Matrix (Matrix'First(1) + I - 1,
                         Matrix'First(2) + J - 1) * X (J);
            end loop;
            Norm := Norm + Y (I) ** 2;
         end loop;
         Norm := Sqrt (Norm);

         if Norm < 1.0e-15 then
            return 0.0;
         end if;

         Lambda := 0.0;
         for I in 1 .. N loop
            Y (I) := Y (I) / Norm;
            Lambda := Lambda + Y (I) * X (I);
            X (I) := Y (I);
         end loop;

         exit when abs (Lambda - Prev_Lambda) < Tolerance;
         Prev_Lambda := Lambda;
      end loop;

      return Lambda;
   end Power_Iteration;

   ---------------------------------------------------------------------------
   --  Fiedler value: second-smallest eigenvalue of symmetric matrix
   ---------------------------------------------------------------------------

   function Fiedler_Value
     (Matrix : Real_Matrix) return Float
   is
      N    : constant Integer := Matrix'Length(1);
      X    : array (1 .. Max_Dimension) of Float := (others => 0.0);
      Y    : array (1 .. Max_Dimension) of Float;
      Norm : Float;
      Lambda, Prev_Lambda : Float := 0.0;
      Ones_Dot : Float;
      Max_Iter : constant := 500;
      Tol      : constant := 1.0e-8;
   begin
      if N < 2 then
         return 0.0;
      end if;

      X (1) := 1.0;
      X (2) := -1.0;

      Ones_Dot := 0.0;
      for I in 1 .. N loop
         Ones_Dot := Ones_Dot + X (I);
      end loop;
      Ones_Dot := Ones_Dot / Float (N);
      for I in 1 .. N loop
         X (I) := X (I) - Ones_Dot;
      end loop;

      for Iter in 1 .. Max_Iter loop
         Norm := 0.0;
         for I in 1 .. N loop
            Y (I) := 0.0;
            for J in 1 .. N loop
               Y (I) := Y (I) +
                 Matrix (Matrix'First(1) + I - 1,
                         Matrix'First(2) + J - 1) * X (J);
            end loop;
            Norm := Norm + Y (I) ** 2;
         end loop;
         Norm := Sqrt (Norm);

         if Norm < 1.0e-15 then
            return 0.0;
         end if;

         Lambda := 0.0;
         for I in 1 .. N loop
            Y (I) := Y (I) / Norm;
            Lambda := Lambda + Y (I) * X (I);
         end loop;

         Ones_Dot := 0.0;
         for I in 1 .. N loop
            Ones_Dot := Ones_Dot + Y (I);
         end loop;
         Ones_Dot := Ones_Dot / Float (N);
         for I in 1 .. N loop
            Y (I) := Y (I) - Ones_Dot;
         end loop;

         for Copy_I in 1 .. Max_Dimension loop
            X (Copy_I) := Y (Copy_I);
         end loop;

         exit when abs (Lambda - Prev_Lambda) < Tol;
         Prev_Lambda := Lambda;
      end loop;

      return Lambda;
   end Fiedler_Value;

end Eigen;
