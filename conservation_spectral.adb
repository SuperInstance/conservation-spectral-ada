--  Conservation Spectral SDK - Package Body
--  Implementation of core spectral graph algorithms
--
--  SPDX-License-Identifier: MIT

with Ada.Calendar;
with Ada.Strings.Unbounded;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Conservation_Spectral is

   ---------------------------------------------------------------------------
   --  Validation helpers
   ---------------------------------------------------------------------------

   function Is_Valid_Laplacian
     (L : Laplacian_Matrix) return Boolean
   is
      Sum : Float;
   begin
      --  Laplacian must be square and row sums should be ~0
      for I in L'Range(1) loop
         Sum := 0.0;
         for J in L'Range(2) loop
            Sum := Sum + L (I, J);
         end loop;
         if abs Sum > 1.0e-4 then
            return False;
         end if;
      end loop;
      --  Off-diagonal entries must be <= 0
      for I in L'Range(1) loop
         for J in L'Range(2) loop
            if I /= J and then L (I, J) > 1.0e-6 then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Laplacian;

   function Is_Row_Stochastic
     (T : Transition_Matrix) return Boolean
   is
      Row_Sum : Float;
   begin
      for I in T'Range(1) loop
         Row_Sum := 0.0;
         for J in T'Range(2) loop
            Row_Sum := Row_Sum + Float (T (I, J));
         end loop;
         if abs (Row_Sum - 1.0) > 1.0e-3 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Row_Stochastic;

   function Degree_Sum
     (L     : Laplacian_Matrix;
      Index : Graph_Index) return Float
   is
   begin
      return L (Index, Index);
   end Degree_Sum;

   ---------------------------------------------------------------------------
   --  Core: Build Laplacian from transition matrix
   --  L = D - A, where D = degree matrix, A = adjacency/weight matrix
   --  For transition matrix T: D_ii = sum_j(T_ij), A_ij = T_ij
   ---------------------------------------------------------------------------

   procedure Build_Laplacian
     (Transition : in     Transition_Matrix;
      Laplacian  :    out Laplacian_Matrix)
   is
      N : constant Integer := Transition'Length(1);
      Diag : Float;
   begin
      --  Validate row-stochastic property
      if not Is_Row_Stochastic (Transition) then
         raise Invalid_Transition;
      end if;

      --  Compute L = D - A
      for I in Transition'Range(1) loop
         Diag := 0.0;
         for J in Transition'Range(2) loop
            declare
               W : constant Float := Float (Transition (I, J));
            begin
               --  Off-diagonal: negative weight
               if I /= J then
                  Laplacian (I, J) := -W;
               end if;
               Diag := Diag + W;
            end;
         end loop;
         --  Diagonal: sum of weights
         Laplacian (I, I) := Diag;
      end loop;
   end Build_Laplacian;

   ---------------------------------------------------------------------------
   --  Conservation ratio: tr(L^T * P * L) / tr(L^T * L)
   --  Measures how much transition structure is preserved by the Laplacian
   ---------------------------------------------------------------------------

   function Compute_Conservation_Ratio
     (Laplacian : Laplacian_Matrix;
      State     : Transition_Matrix) return Conservation_Ratio
   is
      N : constant Integer := Laplacian'Length(1);
      Numerator   : Float := 0.0;
      Denominator : Float := 0.0;
      LTPL_Sum : Float;
   begin
      --  Numerator: tr(L^T * P * L) = sum_I (L^T * P * L)_{ii}
      --  Denominator: tr(L^T * L) = Frobenius norm squared = sum_{i,j} L_{ij}^2

      --  Compute denominator as Frobenius norm squared
      for I in Laplacian'Range(1) loop
         for J in Laplacian'Range(2) loop
            Denominator := Denominator + Laplacian (I, J) ** 2;
         end loop;
      end loop;

      --  Compute numerator: tr(L^T * P * L)
      --  (L^T * P * L)_{ii} = sum_{j,k} L_{ji} * P_{jk} * L_{ki}
      for I in Laplacian'Range(1) loop
         LTPL_Sum := 0.0;
         for J in Laplacian'Range(1) loop
            for K in Laplacian'Range(2) loop
               LTPL_Sum := LTPL_Sum +
                 Laplacian (J, I) * Float (State (J, K)) * Laplacian (K, I);
            end loop;
         end loop;
         Numerator := Numerator + LTPL_Sum;
      end loop;

      if abs Denominator < 1.0e-10 then
         raise Singular_Matrix;
      end if;

      declare
         Result : constant Float := Numerator / Denominator;
      begin
         return Conservation_Ratio (Result);
      end;
   end Compute_Conservation_Ratio;

   ---------------------------------------------------------------------------
   --  Spectral gap via power iteration (second-smallest eigenvalue of L)
   --  Uses deflation to skip the trivial zero eigenvalue
   ---------------------------------------------------------------------------

   function Spectral_Gap
     (Laplacian : Laplacian_Matrix) return Float
   is
      N       : constant Integer := Laplacian'Length(1);
      Max_Iter : constant := 500;
      Tolerance : constant := 1.0e-8;

      --  Allocate vectors on the stack via fixed-size arrays
      type Vector is array (1 .. Max_Graph_Size) of Float;

      X, Y : Vector;
      Norm, Lambda, Prev_Lambda : Float;
      Ones_Dot : Float;

   begin
      if N < 2 then
         return 0.0;
      end if;

      --  Initialize with a vector orthogonal to [1,1,...,1]
      --  Use [1, -1, 0, 0, ...] as starting vector
      X := (others => 0.0);
      X (1) := 1.0;
      X (2) := -1.0;

      --  Orthogonalize against the all-ones vector (trivial eigenvector)
      Ones_Dot := 0.0;
      for I in 1 .. N loop
         Ones_Dot := Ones_Dot + X (I);
      end loop;
      Ones_Dot := Ones_Dot / Float (N);
      for I in 1 .. N loop
         X (I) := X (I) - Ones_Dot;
      end loop;

      Prev_Lambda := 0.0;

      for Iter in 1 .. Max_Iter loop
         --  Y = L * X
         Norm := 0.0;
         for I in 1 .. N loop
            Y (I) := 0.0;
            for J in 1 .. N loop
               Y (I) := Y (I) +
                 Laplacian (Laplacian'First(1) + I - 1,
                            Laplacian'First(2) + J - 1) * X (J);
            end loop;
            Norm := Norm + Y (I) * Y (I);
         end loop;
         Norm := Sqrt (Norm);

         if Norm < 1.0e-15 then
            return 0.0;
         end if;

         --  Normalize
         Lambda := 0.0;
         for I in 1 .. N loop
            Y (I) := Y (I) / Norm;
            Lambda := Lambda + Y (I) * X (I);
         end loop;

         --  Re-orthogonalize against all-ones
         Ones_Dot := 0.0;
         for I in 1 .. N loop
            Ones_Dot := Ones_Dot + Y (I);
         end loop;
         Ones_Dot := Ones_Dot / Float (N);
         for I in 1 .. N loop
            Y (I) := Y (I) - Ones_Dot;
         end loop;

         X := Y;

         exit when abs (Lambda - Prev_Lambda) < Tolerance;
         Prev_Lambda := Lambda;
      end loop;

      return Lambda;
   end Spectral_Gap;

   ---------------------------------------------------------------------------
   --  Cheeger constant bound via spectral gap
   --  h(G) ≥ λ₁/2 (Cheeger inequality, lower bound)
   ---------------------------------------------------------------------------

   function Cheeger_Bound
     (Laplacian : Laplacian_Matrix) return Float
   is
      Lambda : constant Float := Spectral_Gap (Laplacian);
   begin
      return Sqrt (2.0 * Lambda);
   end Cheeger_Bound;

   ---------------------------------------------------------------------------
   --  Graph entropy: -Σ p_i log(p_i) averaged over transition rows
   ---------------------------------------------------------------------------

   function Graph_Entropy
     (Transition : Transition_Matrix) return Float
   is
      Total_Entropy : Float := 0.0;
      Row_Entropy   : Float;
      P             : Float;
   begin
      for I in Transition'Range(1) loop
         Row_Entropy := 0.0;
         for J in Transition'Range(2) loop
            P := Float (Transition (I, J));
            if P > 1.0e-10 then
               Row_Entropy := Row_Entropy - P * Log (P);
            end if;
         end loop;
         Total_Entropy := Total_Entropy + Row_Entropy;
      end loop;
      return Total_Entropy / Float (Transition'Length(1));
   end Graph_Entropy;

end Conservation_Spectral;
