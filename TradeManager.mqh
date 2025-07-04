//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "StrategyBase.mqh"
#include "TradeExecutor.mqh"
#include "Utils.mqh"

class TradeExecutor;

class TradeManager
{
private:
   ulong magic;
   double riskPercent;

   TradeExecutor *executor;
   StrategyBase  *convergingStrategy;
   StrategyBase  *divergingStrategy;

   bool UseConverging;
   bool UseDiverging;
   bool UseBreakEven;
   int  breakEvenMinProfit;
   bool UseTrailing;
   int  trailingPoints;
   int  trailingMinProfit;
   bool UsePartialTP;
   double PartialTP_Points;
   double PartialTP_Volume;

   

public:

   TradeManager(StrategyBase *_converging,
                StrategyBase *_diverging,
                TradeExecutor *_executor,
                bool _useConverging,
                bool _useDiverging,
                bool _useBreakEven,
                int  _minBE,
                bool _useTrailing,
                int  _trailPts,
                int  _trailMin, 
                bool _usePartialTP,
                double _partialTP_Points,
                double _partialTP_Volume
)
   {
      convergingStrategy    = _converging;
      divergingStrategy     = _diverging;
      executor              = _executor;

      UseConverging         = _useConverging;
      UseDiverging          = _useDiverging;
      UseBreakEven          = _useBreakEven;
      breakEvenMinProfit    = _minBE;
      UseTrailing           = _useTrailing;
      trailingPoints        = _trailPts;
      trailingMinProfit     = _trailMin;
      
      UsePartialTP       = _usePartialTP;
      PartialTP_Points   = _partialTP_Points;
      PartialTP_Volume   = _partialTP_Volume;

      magic = 123456; 
      riskPercent = 0.5;
   }

   void SetExecutor(TradeExecutor *exec) { this.executor = exec; }

   bool ExecuteTrade(int signal)
   {
      if (executor == NULL || signal == 0)
         return false;

      executor.Execute(signal);
      return true;
   }

   void OnTick()
   {
      if (executor == NULL)
         return;

      int signal = 0;
      

      if (UseConverging && convergingStrategy != NULL)
         signal = convergingStrategy.CheckSignal();

      if (signal == 0 && UseDiverging && divergingStrategy != NULL)
         signal = divergingStrategy.CheckSignal();
  
      
      if (signal != 0 && CanTradeNow() && IsTradeAllowed(signal))
         executor.Execute(signal);

      else if (signal != 0)
          Print("Signal détecté mais ignoré car pas de tendance.");


      for (int i = 0; i < PositionsTotal(); ++i)
      {
         if (PositionGetTicket(i) > 0 &&
             PositionGetString(POSITION_SYMBOL) == _Symbol &&
             (ulong)PositionGetInteger(POSITION_MAGIC) == magic)
         {
            ulong ticket = PositionGetTicket(i);
            
            double entry = PositionGetDouble(POSITION_PRICE_OPEN);
            
            if (UsePartialTP)
               PartialTakeProfit(ticket, 
                                 (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                                    ? entry + PartialTP_Points * _Point
                                    : entry - PartialTP_Points * _Point,
                                 PartialTP_Volume);
                                 
            if (UseBreakEven)
               MoveToBreakEven(ticket, breakEvenMinProfit);                     
                        
            if (UseTrailing)
               ManageTrailingStop(ticket, trailingPoints, trailingMinProfit);

         }
      }
   }

   void ManageTrailingStop(ulong ticket, int trailingStopPoints, int minProfitPoints)
{
   if (!PositionSelectByTicket(ticket)) return;

   int positionType = (int)PositionGetInteger(POSITION_TYPE);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double tp        = PositionGetDouble(POSITION_TP);
   double price     = (positionType == POSITION_TYPE_BUY)
                      ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                      : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double profitPoints = (positionType == POSITION_TYPE_BUY)
                         ? (price - openPrice) / _Point
                         : (openPrice - price) / _Point;

   if (profitPoints < minProfitPoints) return;


   double newSL = (positionType == POSITION_TYPE_BUY)
                  ? price - trailingStopPoints * _Point
                  : price + trailingStopPoints * _Point;

   double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;


   if (MathAbs(price - newSL) < stopLevel)
   {
      Print("⛔ SL trop proche : niveau interdit par le broker (min ", stopLevel / _Point, " pts)");
      return;
   }

   if ((positionType == POSITION_TYPE_BUY && newSL <= currentSL) ||
       (positionType == POSITION_TYPE_SELL && newSL >= currentSL))
      return;

   MqlTradeRequest request = {};
   MqlTradeResult  result  = {};

   request.action   = TRADE_ACTION_SLTP;
   request.symbol   = _Symbol;
   request.position = ticket;
   request.sl       = NormalizeDouble(newSL, _Digits);
   request.tp       = tp;

   if (!OrderSend(request, result))
      LogError("ManageTrailingStop", result.retcode, "Échec OrderSend SL modification");
   else
      Print(" Trailing SL mis à jour pour ", (positionType == POSITION_TYPE_BUY ? "BUY" : "SELL"), " : SL=", request.sl);
}


   bool MoveToBreakEven(ulong ticket, int minTradePlus)
   {
      if (!PositionSelectByTicket(ticket)) return false;

      long   positionType = PositionGetInteger(POSITION_TYPE);
      double openPrice    = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl           = PositionGetDouble(POSITION_SL);
      double tp           = PositionGetDouble(POSITION_TP);
      string symbol       = PositionGetString(POSITION_SYMBOL);

      double point        = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int    stopLevelPts = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double stopLevel    = stopLevelPts * point;

      double currentPrice = (positionType == POSITION_TYPE_BUY)
                            ? SymbolInfoDouble(symbol, SYMBOL_BID)
                            : SymbolInfoDouble(symbol, SYMBOL_ASK);

      double currentProfit = (positionType == POSITION_TYPE_BUY)
                             ? currentPrice - openPrice
                             : openPrice - currentPrice;

      if ((positionType == POSITION_TYPE_BUY && (sl < openPrice || sl == 0.0) && currentProfit >= minTradePlus * point) ||
          (positionType == POSITION_TYPE_SELL && (sl > openPrice || sl == 0.0) && currentProfit >= minTradePlus * point))
      {
         if (MathAbs(currentPrice - openPrice) < stopLevel)
         {
            Print("BE échoué : distance minimale de stop non respectée (", stopLevelPts, " points).");
            return false;
         }

         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};

         request.action   = TRADE_ACTION_SLTP;
         request.position = ticket;
         request.symbol   = symbol;
         request.sl       = NormalizeDouble(openPrice, _Digits);
         request.tp       = tp;

         if (OrderSend(request, result))
         {
            Print("SL déplacé au BE (", (positionType == POSITION_TYPE_BUY ? "BUY" : "SELL"), ")");
            return true;
         }
         else
         {
            Print("OrderSend échoué (", (positionType == POSITION_TYPE_BUY ? "BUY" : "SELL"), ") - Code: ", result.retcode);
            return false;
         }
      }

      return false;
   }

   double CalculateLotSizeFromPrice(double equityAtRisk, double stopLossPrice, ENUM_ORDER_TYPE orderType, bool verbose = false)
   {
      string symbol = _Symbol;

      double lotSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      double ask     = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double bid     = SymbolInfoDouble(symbol, SYMBOL_BID);
      double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      double minLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double maxLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

      if (equityAtRisk <= 0 || stopLossPrice <= 0 || lotSize <= 0) return 0;

      double lossPerLot = (orderType == ORDER_TYPE_BUY)
                          ? (stopLossPrice - ask) * lotSize
                          : (bid - stopLossPrice) * lotSize;

      if (lossPerLot == 0) return 0;

      double rawLot       = MathAbs(equityAtRisk / lossPerLot);
      int digits          = (int)MathAbs(MathLog10(lotStep));
      double normalizedLot = MathFloor(rawLot / lotStep) * lotStep;
      normalizedLot        = NormalizeDouble(MathMax(minLot, MathMin(normalizedLot, maxLot)), digits);

      if (verbose)
      {
         Print("Équity à risque: ", equityAtRisk);
         Print("Perte par lot : ", lossPerLot);
         Print("Lot brut : ", rawLot);
         Print("Lot normalisé : ", normalizedLot);
      }

      return normalizedLot;
   }
   
   void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   
}

   void PartialTakeProfit(ulong ticket, double targetPrice, double portion = 0.5)
{
   if (!PositionSelectByTicket(ticket)) return;

   int type = (int)PositionGetInteger(POSITION_TYPE);
   double currentPrice = (type == POSITION_TYPE_BUY)
                         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if ((type == POSITION_TYPE_BUY && currentPrice >= targetPrice) ||
       (type == POSITION_TYPE_SELL && currentPrice <= targetPrice))
   {
      double volume = PositionGetDouble(POSITION_VOLUME);
      double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

      double closeVolume = NormalizeDouble(volume * portion, (int)MathLog10(1.0 / lotStep));

      if (closeVolume < minLot || closeVolume >= volume)
      {
         Print("⛔ Volume invalide pour clôture partielle : ", closeVolume);
         return;
      }

      MqlTradeRequest request = {};
      MqlTradeResult  result  = {};

      request.action   = TRADE_ACTION_DEAL;
      request.symbol   = _Symbol;
      request.position = ticket;
      request.volume   = closeVolume;
      request.type     = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price    = currentPrice;
      request.deviation = 10;
      request.magic     = (ulong)PositionGetInteger(POSITION_MAGIC);

      if (!OrderSend(request, result))
         LogError("PartialTakeProfit", result.retcode, "Fermeture partielle échouée");
      else
         Print("✅ Fermeture partielle de ", closeVolume, " lots sur position ", ticket);
   }
}




   

};
//+------------------------------------------------------------------+
