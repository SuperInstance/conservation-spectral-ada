--  Anomaly Detection Package Body
--  Thread-safe implementation using Ada tasking and protected objects
--
--  SPDX-License-Identifier: MIT

with Ada.Calendar;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Anomaly is

   ---------------------------------------------------------------------------
   --  Statistics_Collector: thread-safe accumulation
   ---------------------------------------------------------------------------

   protected body Statistics_Collector is

      procedure Record_Sample (Value : Float) is
      begin
         Sum    := Sum + Value;
         Sum_Sq := Sum_Sq + Value * Value;
         Count  := Count + 1;
      end Record_Sample;

      function Mean return Float is
      begin
         if Count = 0 then
            return 0.0;
         end if;
         return Sum / Float (Count);
      end Mean;

      function Std_Dev return Float is
         Variance : Float;
      begin
         if Count < 2 then
            return 0.0;
         end if;
         Variance := (Sum_Sq - Sum * Sum / Float (Count)) / Float (Count - 1);
         if Variance < 0.0 then
            Variance := 0.0;
         end if;
         return Sqrt (Variance);
      end Std_Dev;

      function Sample_Count return Long_Integer is
      begin
         return Count;
      end Sample_Count;

      procedure Reset is
      begin
         Sum    := 0.0;
         Sum_Sq := 0.0;
         Count  := 0;
      end Reset;

   end Statistics_Collector;

   ---------------------------------------------------------------------------
   --  Anomaly_Detector task body
   --  Uses rendezvous-based synchronization (Ada tasking model)
   ---------------------------------------------------------------------------

   task body Anomaly_Detector is
      Baseline  : Conservation_Spectral.Conservation_Report :=
        (Spectral_Gap       => 0.0,
         Cheeger_Constant   => 0.0,
         Is_Anomalous       => False,
         Confidence         => 0.0,
         Conservation_Score => 0.0,
         Graph_Entropy      => 0.0,
         Timestamp          => Ada.Calendar.Clock);
      Threshold : Threshold_Config := Default_Thresholds;
      Running   : Boolean := True;
      Calibrated : Boolean := False;
   begin
      while Running loop
         select
            accept Set_Baseline (Report : Conservation_Spectral.Conservation_Report) do
               Baseline   := Report;
               Calibrated := True;
            end Set_Baseline;

         or
            accept Set_Thresholds (Config : Threshold_Config) do
               Threshold := Config;
            end Set_Thresholds;

         or
            accept Check
              (Spectral_Gap     : in     Float;
               Cheeger_Constant : in     Float;
               Conservation     : in     Float;
               Entropy          : in     Float;
               Is_Anomalous     :    out Boolean;
               Severity         :    out Conservation_Spectral.Anomaly_Severity)
            do
               Is_Anomalous := False;
               Severity := Conservation_Spectral.None;

               if not Calibrated then
                  --  No baseline → cannot detect anomalies
                  Is_Anomalous := False;
                  Severity := Conservation_Spectral.None;
               else
                  --  Score drift from baseline
                  declare
                     SG_Drift  : constant Float :=
                       abs (Spectral_Gap - Baseline.Spectral_Gap);
                     CH_Drift  : constant Float :=
                       abs (Cheeger_Constant - Baseline.Cheeger_Constant);
                     CS_Drift  : constant Float :=
                       abs (Conservation - Baseline.Conservation_Score);
                     EN_Drift  : constant Float :=
                       abs (Entropy - Baseline.Graph_Entropy);
                     Violations : Integer := 0;
                  begin
                     if SG_Drift > Threshold.Spectral_Gap_Delta then
                        Violations := Violations + 1;
                     end if;
                     if CH_Drift > Threshold.Cheeger_Delta then
                        Violations := Violations + 1;
                     end if;
                     if CS_Drift > Threshold.Conservation_Delta then
                        Violations := Violations + 1;
                     end if;
                     if EN_Drift > Threshold.Entropy_Delta then
                        Violations := Violations + 1;
                     end if;

                     --  Classify severity
                     case Violations is
                        when 0 =>
                           Severity := Conservation_Spectral.None;
                        when 1 =>
                           Severity := Conservation_Spectral.Low;
                        when 2 =>
                           Severity := Conservation_Spectral.Medium;
                        when 3 =>
                           Severity := Conservation_Spectral.High;
                        when others =>
                           Severity := Conservation_Spectral.Critical;
                     end case;

                     Is_Anomalous := Violations >= 1;
                  end;
               end if;
            end Check;

         or
            accept Get_Baseline
              (Report : out Conservation_Spectral.Conservation_Report)
            do
               Report := Baseline;
            end Get_Baseline;

         or
            accept Stop do
               Running := False;
            end Stop;

         or
            terminate;
         end select;
      end loop;
   end Anomaly_Detector;

end Anomaly;
