//+------------------------------------------------------------------+
//|                                               ConvergingVWAP.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                              ConvergingVWAP.mqh |
//|     Implémentation de la stratégie de convergence VWAP          |
//+------------------------------------------------------------------+
#ifndef __CONVERGING_VWAP_MQH__
#define __CONVERGING_VWAP_MQH__

#include "StrategyBase.mqh"
#include "Utils.mqh" 

class ConvergingVWAP : public StrategyBase
{
private:
   string symbol;
   ENUM_TIMEFRAMES timeframe;
   int    vwapLookback;
   double vwapBuffer;
   int    rsiPeriod;

public:
   
   ConvergingVWAP(string _symbol, ENUM_TIMEFRAMES _tf, int _lookback, double _buffer, int _rsiPeriod = 14)
   {
      symbol       = _symbol;
      timeframe    = _tf;
      vwapLookback = _lookback;
      vwapBuffer   = _buffer * SymbolInfoDouble(_symbol, SYMBOL_POINT);
      rsiPeriod    = _rsiPeriod;
   }

  
   virtual int CheckSignal()
   {
      MqlRates rates[2];
      if (CopyRates(symbol, timeframe, 0, 2, rates) < 2)
         return 0;

      double price_now  = rates[0].close;
      double price_prev = rates[1].close;

      double vwap_now  = CalculateCustomVWAP(symbol, timeframe, 0, vwapLookback);
      double vwap_prev = CalculateCustomVWAP(symbol, timeframe, 1, vwapLookback + 1);

      bool buySignal  = (price_prev < vwap_prev - vwapBuffer) && (price_now >= vwap_now - vwapBuffer);
      bool sellSignal = (price_prev > vwap_prev + vwapBuffer) && (price_now <= vwap_now + vwapBuffer);

      int signal = 0;
      if (buySignal)  signal = 1;
      if (sellSignal) signal = -1;

      int rsi_handle = iRSI(symbol, timeframe, rsiPeriod, PRICE_CLOSE);
      double rsi_buffer[];
      if (CopyBuffer(rsi_handle, 0, 0, 1, rsi_buffer) > 0)
      {
         double rsi = rsi_buffer[0];
         if ((signal == 1 && rsi > 60) || (signal == -1 && rsi < 40))
            return 0;
      }

      return signal;
   }
};

#endif

//+------------------------------------------------------------------+
