//+------------------------------------------------------------------+
//|                                                    IStopLoss.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#ifndef __ISTOPLOSS_MQH__
#define __ISTOPLOSS_MQH__

class IStopLoss
{
public:
   virtual double Calculate(int direction, double entryPrice) = 0;
};

#endif

//+------------------------------------------------------------------+
