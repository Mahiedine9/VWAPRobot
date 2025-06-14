//+------------------------------------------------------------------+
//|                                                DivergingVWAP.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                               DivergingVWAP.mqh |
//|     Implémentation de la stratégie de divergence VWAP           |
//+------------------------------------------------------------------+

#ifndef __DIVERGING_VWAP_MQH__
#define __DIVERGING_VWAP_MQH__

#include "StrategyBase.mqh"
#include "Utils.mqh"


class DivergingVWAP : public StrategyBase
{
private:
   string symbol;
   ENUM_TIMEFRAMES timeframe;
   int    vwapLookback;
   double vwapBuffer;
   int    rsiPeriod;

public:
   DivergingVWAP(string _symbol, ENUM_TIMEFRAMES _tf, int _lookback, double _buffer, int _rsiPeriod = 14)
   {
      symbol       = _symbol;
      timeframe    = _tf;
      vwapLookback = _lookback;
      vwapBuffer   = _buffer * SymbolInfoDouble(_symbol, SYMBOL_POINT);
      rsiPeriod    = _rsiPeriod;
   }

   virtual int CheckSignal()
   {
      MqlRates rates[3];
      if (CopyRates(symbol, timeframe, 0, 3, rates) < 3)
         return 0;

      double price_now  = rates[0].close;
      double price_prev = rates[1].close;
      double price_2ago = rates[2].close;

      double vwap_now  = CalculateCustomVWAP(symbol, timeframe, 0, vwapLookback);
      double vwap_prev = CalculateCustomVWAP(symbol, timeframe, 1, vwapLookback + 1);
      double vwap_2ago = CalculateCustomVWAP(symbol, timeframe, 2, vwapLookback + 2);


      bool sellDivergence = (price_now > price_prev && price_prev > price_2ago &&
                              vwap_now < vwap_prev && vwap_prev < vwap_2ago &&
                              price_now > vwap_now + vwapBuffer);


      bool buyDivergence  = (price_now < price_prev && price_prev < price_2ago &&
                              vwap_now > vwap_prev && vwap_prev > vwap_2ago &&
                              price_now < vwap_now - vwapBuffer);

      int signal = 0;
      if (buyDivergence)  signal = 1;
      if (sellDivergence) signal = -1;


      int rsi_handle = iRSI(symbol, timeframe, rsiPeriod, PRICE_CLOSE);
      double rsi_buffer[];

      if (CopyBuffer(rsi_handle, 0, 0, 1, rsi_buffer) > 0)
      {
         double rsi = rsi_buffer[0];

         if ((signal == 1 && rsi > 60) || (signal == -1 && rsi < 40))
         {
            Print(" Divergence détectée mais RSI ne confirme pas : RSI=", rsi);
            return 0;
         }
      }

      if (signal != 0)
         Print(" Signal DivergingVWAP détecté : ", (signal == 1 ? "BUY" : "SELL"));

      return signal;
   }
};

#endif
