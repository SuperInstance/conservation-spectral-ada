--  Conservation Spectral SDK - Package Specification
--  Production-grade spectral graph theory for conservation analysis
--  Designed for DO-178C avionics certification standards
--
--  SPDX-License-Identifier: MIT

with Ada.Calendar;

package Conservation_Spectral is

   Max_Graph_Size : constant := 1000;

   subtype Graph_Index is Integer range 1 .. Max_Graph_Size;
   subtype Probability is Float range 0.0 .. 1.0;
   subtype Conservation_Ratio is Float range -100.0 .. 100.0;

   --  Transition probability matrix (row-stochastic)
   type Transition_Matrix is
     array (Graph_Index range <>, Graph_Index range <>) of Probability;

   --  Laplacian matrix (symmetric, positive semi-definite)
   type Laplacian_Matrix is
     array (Graph_Index range <>, Graph_Index range <>) of Float;

   --  Anomaly severity classification
   type Anomaly_Severity is (None, Low, Medium, High, Critical);

   --  Comprehensive conservation report
   type Conservation_Report is record
      Spectral_Gap       : Float;
      Cheeger_Constant   : Float;
      Is_Anomalous       : Boolean;
      Confidence         : Float range 0.0 .. 1.0;
      Conservation_Score : Conservation_Ratio;
      Graph_Entropy      : Float;
      Timestamp          : Ada.Calendar.Time;
   end record;

   --  Validation helpers used in pre/post conditions

   function Is_Valid_Laplacian
     (L : Laplacian_Matrix) return Boolean
   with
     Pre => L'Length(1) = L'Length(2);

   function Is_Row_Stochastic
     (T : Transition_Matrix) return Boolean
   with
     Pre => T'Length(1) = T'Length(2);

   --  Core operations

   procedure Build_Laplacian
     (Transition : in     Transition_Matrix;
      Laplacian  :    out Laplacian_Matrix)
   with
     Pre  => Transition'Length(1) = Transition'Length(2) and then
             Laplacian'Length(1) = Transition'Length(1) and then
             Laplacian'Length(2) = Transition'Length(2),
     Post => Is_Valid_Laplacian(Laplacian);

   function Compute_Conservation_Ratio
     (Laplacian : Laplacian_Matrix;
      State     : Transition_Matrix) return Conservation_Ratio
   with
     Pre => Laplacian'Length(1) = State'Length(1) and then
            Laplacian'Length(1) = Laplacian'Length(2);

   function Spectral_Gap
     (Laplacian : Laplacian_Matrix) return Float
   with
     Pre => Laplacian'Length(1) = Laplacian'Length(2) and then
            Laplacian'Length(1) >= 2;

   function Cheeger_Bound
     (Laplacian : Laplacian_Matrix) return Float
   with
     Pre => Laplacian'Length(1) = Laplacian'Length(2) and then
            Laplacian'Length(1) >= 2;

   function Graph_Entropy
     (Transition : Transition_Matrix) return Float
   with
     Pre => Transition'Length(1) = Transition'Length(2);

   --  Exception for singular/malformed matrices
   Singular_Matrix    : exception;
   Invalid_Transition : exception;

end Conservation_Spectral;
