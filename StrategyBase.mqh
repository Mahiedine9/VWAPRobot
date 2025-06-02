//+------------------------------------------------------------------+
//|                                                 StrategyBase.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#ifndef __STRATEGY_BASE_MQH__
#define __STRATEGY_BASE_MQH__


class StrategyBase
{
public:
   virtual int CheckSignal() = 0;  
};

#endif