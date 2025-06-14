   //+------------------------------------------------------------------+
   //|                                                TradeExecutor.mqh |
   //|                                  Copyright 2025, MetaQuotes Ltd. |
   //|                                             https://www.mql5.com |
   //+------------------------------------------------------------------+
   #property copyright "Copyright 2025, MetaQuotes Ltd."
   #property link      "https://www.mql5.com"
   #property version   "1.00"
   //+------------------------------------------------------------------+
   //|                                                 TradeExecutor.mqh |
   //|    Exécute les ordres selon le signal fourni                     |
   //+------------------------------------------------------------------+
   #ifndef __TRADE_EXECUTOR_MQH__
   #define __TRADE_EXECUTOR_MQH__
   
   #include <Trade\Trade.mqh>          
   #include "Utils.mqh"                 
   #include "SL/IStopLoss.mqh"         
   #include "TradeManager.mqh"          


   class TradeManager;
   
   class TradeExecutor
   {
   private:
      string symbol;
      TradeManager *manager;
      IStopLoss    *stopLogic;
      ulong        magicNumber;
      double       riskPercent;
   
   public:
      TradeExecutor(string _symbol, TradeManager *_manager, IStopLoss *_stopLogic, ulong _magic, double _risk)
      {
         symbol       = _symbol;
         manager      = _manager;
         stopLogic    = _stopLogic;
         magicNumber  = _magic;
         riskPercent  = _risk;
      }
   
      void Execute(int signal)
      {
         if (signal == 0 || HasOpenPosition(symbol, magicNumber))
            return;
      
         MqlRates rates[1];
         if (CopyRates(symbol, PERIOD_CURRENT, 0, 1, rates) < 1)
         {
            Print(" Erreur CopyRates");
            return;
         }
      
         double entryPrice = rates[0].close;
         double point      = SymbolInfoDouble(symbol, SYMBOL_POINT);
         int    digits     = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      
         ENUM_ORDER_TYPE orderType = (signal == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      
 
         double stopLossPrice = stopLogic.Calculate(signal, entryPrice);
         if (stopLossPrice <= 0 || stopLossPrice == entryPrice)
         {
            Print(" Erreur dans le calcul du SL : ", stopLossPrice);
            return;
         }
      
         double slDistance = MathAbs(entryPrice - stopLossPrice);
         if (slDistance < 5 * point)
         {
            Print(" SL trop proche : slDistance = ", slDistance);
            return;
         }
      

         double tpDistance = 3 * slDistance;
         double tpPrice    = (signal == 1)
                             ? entryPrice + tpDistance
                             : entryPrice - tpDistance;
      

         double stopLevel = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
         if (slDistance < stopLevel || MathAbs(tpPrice - entryPrice) < stopLevel)
         {
            Print(" SL ou TP trop proches du prix actuel. stopLevel = ", stopLevel);
            return;
         }
      

         double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
         double equityRisk = equity * riskPercent / 100.0;
         double lotSize    = manager.CalculateLotSizeFromPrice(equityRisk, stopLossPrice, orderType, true);
         if (lotSize <= 0)
         {
            Print(" Lot size invalide");
            return;
         }
      

         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};
         
         request.action    = TRADE_ACTION_DEAL;
         request.symbol    = symbol;
         request.volume    = lotSize;
         request.sl        = NormalizeDouble(stopLossPrice, digits);
         request.tp        = NormalizeDouble(tpPrice, digits);
         request.magic     = magicNumber;
         request.deviation = 10;
         request.type      = orderType;
         request.price     = (orderType == ORDER_TYPE_BUY)
                             ? SymbolInfoDouble(symbol, SYMBOL_ASK)
                             : SymbolInfoDouble(symbol, SYMBOL_BID);
         

         ENUM_ORDER_TYPE_FILLING filling_modes[] = {ORDER_FILLING_IOC, ORDER_FILLING_FOK, ORDER_FILLING_RETURN};
         bool success = false;
         
         for (int i = 0; i < ArraySize(filling_modes); i++)
         {
             request.type_filling = filling_modes[i];
         
             if (OrderSend(request, result))
             {
                 PrintFormat("Trade ouvert avec filling mode : %d", request.type_filling);
                 Print("Trade ouvert (", (signal == 1 ? "BUY" : "SELL"),
                       "), entry=", request.price,
                       ", SL=", request.sl,
                       ", TP=", request.tp,
                       ", Lot=", lotSize);
                 success = true;
                 break;
             }
             else if (result.retcode != TRADE_RETCODE_INVALID_FILL)
             {
                 PrintFormat(" Erreur autre que filling mode (%d): %s", result.retcode, result.comment);
                 break;
             }
         }
         
         if (!success)
         {
             LogError("TradeExecutor.Execute", result.retcode, "Échec d’ouverture de position même après fallback filling modes");
         }

      
      }
      
      bool HasOpenPosition(string symbol, ulong magic)
      {
         for (int i = 0; i < PositionsTotal(); i++)
         {
            if (PositionGetTicket(i) > 0)
            {
               if (PositionGetString(POSITION_SYMBOL) == symbol &&
                   (ulong)PositionGetInteger(POSITION_MAGIC) == magic)
                  return true;
            }
         }
         return false;
      }

   };
   
   #endif
   
   
   //+------------------------------------------------------------------+
