//+------------------------------------------------------------------+
//|                                                 StopLossVWAP.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include "IStopLoss.mqh"
#include "../Utils.mqh"

class StopLossVWAP : public IStopLoss
{
private:
   double offset;

public:
   StopLossVWAP(double _offset)
   {
      offset = _offset;
   }

   double Calculate(int direction, double entryPrice)
   {
      double vwap = CalculateCustomVWAP(_Symbol, PERIOD_CURRENT, 0, 20); // ex
      return (direction == 1)
         ? vwap - offset * _Point
         : vwap + offset * _Point;
   }
};

//+------------------------------------------------------------------+
