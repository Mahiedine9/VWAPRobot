//+------------------------------------------------------------------+
//|                                                FixedStopLoss.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "IStopLoss.mqh"

class FixedStopLoss : public IStopLoss
{
private:
   double slPoints;
   double point;
public:
   FixedStopLoss(double _slPoints, double _point)
   {
      slPoints = _slPoints;
      point    = _point;
   }

   double Calculate(int direction, double entryPrice) override
   {
      return (direction == 1)
         ? entryPrice - slPoints * point
         : entryPrice + slPoints * point;
   }
};

