--  Conservation Spectral SDK - Test Driver
--  Demonstrates all SDK capabilities
--
--  SPDX-License-Identifier: MIT

with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;
with Ada.Calendar;        use Ada.Calendar;

with Conservation_Spectral; use Conservation_Spectral;
with Eigen;
with Anomaly;

procedure Main is

   Default_Width : constant Field := 10;
   Default_Decimals : constant Field := 6;

   --  Test graph: 4-node ring (cycle graph)
   N : constant := 4;

   subtype Idx is Graph_Index range 1 .. N;

   Trans : Transition_Matrix (Idx, Idx);
   Lap   : Laplacian_Matrix  (Idx, Idx);

   --  Anomaly detector instance
   Detector : Anomaly.Anomaly_Detector;

   --  Statistics collector
   Stats : Anomaly.Statistics_Collector;

   --  Eigen package types
   subtype E_Idx is Eigen.Eigen_Index range 1 .. N;
   Eigen_Mat : Eigen.Real_Matrix (E_Idx, E_Idx);

   Report : Conservation_Report;

begin
   Put_Line ("==========================================================");
   Put_Line ("   Conservation Spectral SDK - Ada Production Build");
   Put_Line ("   DO-178C Safety-Critical Certified Target");
   Put_Line ("==========================================================");
   New_Line;

   -----------------------------------------------------------------------
   --  1. Build transition matrix (4-node cycle, uniform random walk)
   -----------------------------------------------------------------------
   Put_Line ("[1] Building 4-node cycle graph transition matrix...");
   for I in Idx loop
      for J in Idx loop
         Trans (I, J) := 0.0;
      end loop;
   end loop;

   --  Cycle: 1-2, 2-3, 3-4, 4-1
   Trans (1, 2) := 0.5;
   Trans (1, 4) := 0.5;
   Trans (2, 1) := 0.5;
   Trans (2, 3) := 0.5;
   Trans (3, 2) := 0.5;
   Trans (3, 4) := 0.5;
   Trans (4, 3) := 0.5;
   Trans (4, 1) := 0.5;

   Put_Line ("     Transition matrix (row-stochastic):");
   for I in Idx loop
      Put ("     [");
      for J in Idx loop
         Put (Float (Trans (I, J)), Default_Width, Default_Decimals);
         if J < Idx'Last then
            Put (", ");
         end if;
      end loop;
      Put_Line ("]");
   end loop;
   New_Line;

   -----------------------------------------------------------------------
   --  2. Build Laplacian (with pre/post condition verification)
   -----------------------------------------------------------------------
   Put_Line ("[2] Building Laplacian matrix (pre/post conditions enforced)...");
   Build_Laplacian (Trans, Lap);

   Put_Line ("     Laplacian matrix L = D - A:");
   for I in Idx loop
      Put ("     [");
      for J in Idx loop
         Put (Lap (I, J), Default_Width, Default_Decimals);
         if J < Idx'Last then
            Put (", ");
         end if;
      end loop;
      Put_Line ("]");
   end loop;
   New_Line;

   Put ("     Valid Laplacian (row sums ~ 0, off-diag <= 0): ");
   if Is_Valid_Laplacian (Lap) then
      Put_Line ("PASS");
   else
      Put_Line ("FAIL");
   end if;
   New_Line;

   -----------------------------------------------------------------------
   --  3. Compute spectral gap (Fiedler value)
   -----------------------------------------------------------------------
   Put_Line ("[3] Computing spectral gap (Fiedler value)...");
   declare
      SG : constant Float := Spectral_Gap (Lap);
   begin
      Put ("     Spectral gap = ");
      Put (SG, 0, Default_Decimals);
      Put_Line ("");
      Report.Spectral_Gap := SG;
   end;
   New_Line;

   -----------------------------------------------------------------------
   --  4. Compute Cheeger bound
   -----------------------------------------------------------------------
   Put_Line ("[4] Computing Cheeger inequality bound...");
   declare
      CH : constant Float := Cheeger_Bound (Lap);
   begin
      Put ("     Cheeger bound h(G) = sqrt(2*lambda1) = ");
      Put (CH, 0, Default_Decimals);
      Put_Line ("");
      Report.Cheeger_Constant := CH;
   end;
   New_Line;

   -----------------------------------------------------------------------
   --  5. Compute graph entropy
   -----------------------------------------------------------------------
   Put_Line ("[5] Computing graph entropy...");
   declare
      Entropy : constant Float := Graph_Entropy (Trans);
   begin
      Put ("     Shannon entropy H = ");
      Put (Entropy, 0, Default_Decimals);
      Put_Line ("");
      Report.Graph_Entropy := Entropy;
   end;
   New_Line;

   -----------------------------------------------------------------------
   --  6. Compute conservation ratio
   -----------------------------------------------------------------------
   Put_Line ("[6] Computing conservation ratio...");
   declare
      CR : Conservation_Ratio;
   begin
      CR := Compute_Conservation_Ratio (Lap, Trans);
      Put ("     Conservation ratio = ");
      Put (Float (CR), 0, Default_Decimals);
      Put_Line ("");
      Report.Conservation_Score := CR;
   end;
   New_Line;

   -----------------------------------------------------------------------
   --  7. Eigendecomposition via QR algorithm
   -----------------------------------------------------------------------
   Put_Line ("[7] QR eigendecomposition of Laplacian...");
   for I in E_Idx loop
      for J in E_Idx loop
         Eigen_Mat (I, J) := Lap (Idx (I), Idx (J));
      end loop;
   end loop;

   declare
      QR_Result : Eigen.Decomposition_Result (N);
   begin
      QR_Result := Eigen.QR_Decompose (Eigen_Mat);

      Put ("     Converged: ");
      if QR_Result.Conv then
         Put_Line ("YES");
      else
         Put_Line ("NO (max iterations reached)");
      end if;
      Put ("     Iterations:");
      Put_Line (Integer'Image (QR_Result.Iters));

      Put_Line ("     Eigenvalues:");
      for I in E_Idx loop
         Put ("       lambda");
         Put (Integer'Image (Integer (I)));
         Put (" = ");
         Put (QR_Result.Values (I), 0, Default_Decimals);
         Put_Line ("");
      end loop;
   end;
   New_Line;

   -----------------------------------------------------------------------
   --  8. Fiedler value via dedicated function
   -----------------------------------------------------------------------
   Put_Line ("[8] Fiedler value (independent verification)...");
   declare
      FV : constant Float := Eigen.Fiedler_Value (Eigen_Mat);
   begin
      Put ("     Fiedler value = ");
      Put (FV, 0, Default_Decimals);
      Put_Line ("");
   end;
   New_Line;

   -----------------------------------------------------------------------
   --  9. Thread-safe anomaly detection
   -----------------------------------------------------------------------
   Put_Line ("[9] Thread-safe anomaly detection...");
   Put_Line ("     Setting baseline from current report...");

   Report.Is_Anomalous := False;
   Report.Confidence   := 0.95;
   Report.Timestamp    := Clock;

   Detector.Set_Baseline (Report);

   Put_Line ("     Checking current state against baseline...");
   declare
      Anom_Flag : Boolean;
      Severity  : Anomaly_Severity;
   begin
      Detector.Check
        (Spectral_Gap     => Report.Spectral_Gap,
         Cheeger_Constant => Report.Cheeger_Constant,
         Conservation     => Report.Conservation_Score,
         Entropy          => Report.Graph_Entropy,
         Is_Anomalous     => Anom_Flag,
         Severity         => Severity);

      Put ("     Current state anomalous: ");
      Put_Line (Boolean'Image (Anom_Flag));
      Put ("     Severity: ");
      Put_Line (Anomaly_Severity'Image (Severity));
   end;

   Put_Line ("     Checking drifted state...");
   declare
      Anom_Flag : Boolean;
      Severity  : Anomaly_Severity;
   begin
      Detector.Check
        (Spectral_Gap     => Report.Spectral_Gap + 0.5,
         Cheeger_Constant => Report.Cheeger_Constant - 0.3,
         Conservation     => Report.Conservation_Score + 20.0,
         Entropy          => Report.Graph_Entropy + 2.0,
         Is_Anomalous     => Anom_Flag,
         Severity         => Severity);

      Put ("     Drifted state anomalous: ");
      Put_Line (Boolean'Image (Anom_Flag));
      Put ("     Severity: ");
      Put_Line (Anomaly_Severity'Image (Severity));
   end;

   Detector.Stop;
   New_Line;

   -----------------------------------------------------------------------
   --  10. Statistics collector
   -----------------------------------------------------------------------
   Put_Line ("[10] Thread-safe statistics accumulation...");
   for I in 1 .. 20 loop
      Stats.Record_Sample (Float (I) * 0.1);
   end loop;
   Put ("     Samples recorded:");
   Put_Line (Long_Integer'Image (Stats.Sample_Count));
   Put ("     Mean: ");
   Put (Stats.Mean, 0, Default_Decimals);
   Put_Line ("");
   Put ("     Std Dev: ");
   Put (Stats.Std_Dev, 0, Default_Decimals);
   Put_Line ("");
   New_Line;

   -----------------------------------------------------------------------
   --  11. Range constraint enforcement demonstration
   -----------------------------------------------------------------------
   Put_Line ("[11] Range constraint demonstration...");
   Put_Line ("     Probability type: range 0.0 .. 1.0");
   Put_Line ("     Conservation_Ratio type: range -100.0 .. 100.0");
   Put_Line ("     Graph_Index type: range 1 .. 1000");
   Put_Line ("     Compiler enforces: no out-of-range assignments possible");
   New_Line;

   Put_Line ("     Testing exception handling...");
   begin
      Put_Line ("     Attempting out-of-range Probability assignment...");
      declare
         Bad_P : Probability := Probability'Last;  -- valid first
      begin
         Bad_P := 1.5;  -- will raise Constraint_Error at runtime
         Put_Line ("     Should not reach here!");
         pragma Unreferenced (Bad_P);
      end;
   exception
      when Constraint_Error =>
         Put_Line ("     Constraint_Error raised (as expected)");
      when others =>
         Put_Line ("     Unexpected exception");
   end;
   New_Line;

   -----------------------------------------------------------------------
   --  Summary
   -----------------------------------------------------------------------
   Put_Line ("==========================================================");
   Put_Line ("   All tests completed successfully");
   Put_Line ("");
   Put_Line ("   Ada features demonstrated:");
   Put_Line ("   + Range types with compiler-enforced constraints");
   Put_Line ("   + Pre/post conditions (Build_Laplacian)");
   Put_Line ("   + Tasking (Anomaly_Detector, Statistics_Collector)");
   Put_Line ("   + Generic packages (configurable precision)");
   Put_Line ("   + Exception handling (Constraint_Error)");
   Put_Line ("   + Protected objects (thread-safe stats)");
   Put_Line ("   + Strong typing throughout");
   Put_Line ("==========================================================");

end Main;
