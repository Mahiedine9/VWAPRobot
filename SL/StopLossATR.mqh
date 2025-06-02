//+------------------------------------------------------------------+
//|                                                  StopLossATR.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include "IStopLoss.mqh"

class StopLossATR : public IStopLoss
{
private:
   int atrPeriod;
   double atrMultiplier;

public:
   StopLossATR(int _period, double _mult)
   {
      atrPeriod = _period;
      atrMultiplier = _mult;
   }

   double Calculate(int direction, double entryPrice)
   {
      int atrHandle = iATR(_Symbol, PERIOD_CURRENT, atrPeriod);
      double atrBuffer[];

      if (CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) > 0)
      {
         double atr = atrBuffer[0];
         return (direction == 1)
              ? entryPrice - atr * atrMultiplier
              : entryPrice + atr * atrMultiplier;
      }

      return 0; 
   }

      
   
};

//+------------------------------------------------------------------+
