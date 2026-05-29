--  Anomaly Detection Package Specification
--  Thread-safe anomaly detection with baseline tracking
--
--  SPDX-License-Identifier: MIT

with Conservation_Spectral;

package Anomaly is

   pragma Elaborate_Body (Anomaly);

   --  Anomaly threshold configuration
   type Threshold_Config is record
      Spectral_Gap_Delta   : Float := 0.1;   -- allowed drift in spectral gap
      Cheeger_Delta        : Float := 0.1;   -- allowed drift in Cheeger bound
      Conservation_Delta   : Float := 5.0;   -- allowed drift in conservation
      Min_Confidence       : Float := 0.7;   -- minimum confidence to flag
      Entropy_Delta        : Float := 0.5;   -- allowed drift in entropy
   end record;

   Default_Thresholds : constant Threshold_Config := (others => <>);

   --  Thread-safe anomaly detector task type
   --  Supports concurrent Check calls from multiple threads
   task type Anomaly_Detector is
      --  Set the baseline (calibration) report
      entry Set_Baseline (Report : Conservation_Spectral.Conservation_Report);

      --  Configure detection thresholds
      entry Set_Thresholds (Config : Threshold_Config);

      --  Check current state against baseline
      --  Returns True if anomalous
      entry Check
        (Spectral_Gap     : in     Float;
         Cheeger_Constant : in     Float;
         Conservation     : in     Float;
         Entropy          : in     Float;
         Is_Anomalous     :    out Boolean;
         Severity         :    out Conservation_Spectral.Anomaly_Severity);

      --  Get current baseline
      entry Get_Baseline
        (Report : out Conservation_Spectral.Conservation_Report);

      --  Graceful shutdown
      entry Stop;
   end Anomaly_Detector;

   --  Protected object for thread-safe statistics accumulation
   protected type Statistics_Collector is
      procedure Record_Sample (Value : Float);
      function  Mean return Float;
      function  Std_Dev return Float;
      function  Sample_Count return Long_Integer;
      procedure Reset;
   private
      Sum       : Float := 0.0;
      Sum_Sq    : Float := 0.0;
      Count     : Long_Integer := 0;
   end Statistics_Collector;

end Anomaly;
