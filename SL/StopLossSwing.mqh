//+------------------------------------------------------------------+
//|                                                StopLossSwing.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include "IStopLoss.mqh"

class StopLossSwing : public IStopLoss
{
private:
   int barsBack;
   double gap;

public:
   StopLossSwing(int _barsBack, double _gap)
   {
      barsBack = _barsBack;
      gap = _gap;
   }

   double Calculate(int direction, double entryPrice)
   {
      if (direction == 1)
      {
         int idx = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, barsBack, 1);
         double low = iLow(_Symbol, PERIOD_CURRENT, idx);
         return low - gap * _Point;
      }
      else
      {
         int idx = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, barsBack, 1);
         double high = iHigh(_Symbol, PERIOD_CURRENT, idx);
         return high + gap * _Point;
      }
   }
};

//+------------------------------------------------------------------+
