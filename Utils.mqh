//+------------------------------------------------------------------+
//|                                                        Utils.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+


extern datetime lastTradeTime;
extern bool     lastTradeWasLoss;
extern int      cooldownSeconds ;


double CalculateCustomVWAP(string symbol, ENUM_TIMEFRAMES timeframe, int startBar, int endBar)
{
    double totalVolume = 0;
    double totalPriceVolume = 0;

    MqlRates rate[];

    for(int i = startBar; i <= endBar; i++)
    {
        
        if(CopyRates(symbol, timeframe, i, 1, rate) != 1)
            continue;

        double price  = rate[0].close;
        double volume = rate[0].tick_volume;

        totalPriceVolume += price * volume;
        totalVolume += volume;
    }

    if(totalVolume == 0)
        return 0;

    return totalPriceVolume / totalVolume;
}






void LogError(string functionName, int errorCode, string additionalInfo = "")
   {
      string errorDesc = "";

      switch (errorCode)
      {
         case 0:      errorDesc = "Pas d'erreur"; break;
         case 1:      errorDesc = "Erreur inconnue"; break;
         case 10004:  errorDesc = "Trade server busy"; break;
         case 10006:  errorDesc = "No connection"; break;
         case 10009:  errorDesc = "Invalid price"; break;
         case 10010:  errorDesc = "Invalid stops"; break;
         case 10011:  errorDesc = "Trade disabled"; break;
         default:     errorDesc = "Erreur non répertoriée"; break;
      }

      Print("ERREUR dans ", functionName, " - Code: ", errorCode,
            " - Description: ", errorDesc, " - Info: ", additionalInfo);
   }
   



bool TimeFilterOk()
{
   MqlDateTime now;
   TimeCurrent(now);

   if (now.hour >= 15 && now.hour < 18)
   {
      Print(" Filtre horaire activé : trading bloqué à ", now.hour, "h");
      return false;
   }

   return true;
}

bool TrendFilterOk(int signal)
{
   string symbol = _Symbol;
   ENUM_TIMEFRAMES tfTrend = PERIOD_H1;

   double emaFast[], emaSlow[];
   int handleFast = iMA(symbol, tfTrend, 50, 0, MODE_EMA, PRICE_CLOSE);
   int handleSlow = iMA(symbol, tfTrend, 200, 0, MODE_EMA, PRICE_CLOSE);

   if (handleFast == INVALID_HANDLE || handleSlow == INVALID_HANDLE)
   {
      Print(" Erreur création handle EMA");
      return false;
   }

   if (CopyBuffer(handleFast, 0, 0, 1, emaFast) <= 0 ||
       CopyBuffer(handleSlow, 0, 0, 1, emaSlow) <= 0)
   {
      Print(" Erreur lecture EMA");
      return false;
   }

   double fast = emaFast[0];
   double slow = emaSlow[0];
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);

   if (fast == 0 || slow == 0)
   {
      Print(" EMA invalide");
      return false;
   }

   double emaGap = MathAbs(fast - slow);
   if (emaGap < 10 * pointValue)
   {
      Print(" Pas de tendance claire (EMA Gap < 10 pts)");
      return false;
   }

   if (signal == 1 && fast < slow)
   {
      Print(" Signal BUY mais tendance baissière");
      return false;
   }

   if (signal == -1 && fast > slow)
   {
      Print(" Signal SELL mais tendance haussière");
      return false;
   }

   return true;
}



bool VolatilityFilterOk()
{
   string symbol = _Symbol;
   int atrPeriod = 14;
   double atrBuffer[];
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);

   int atrHandle = iATR(symbol, PERIOD_M10, atrPeriod);

   if (atrHandle == INVALID_HANDLE)
   {
      Print(" Erreur création handle ATR");
      return false;
   }

   if (CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) <= 0)
   {
      Print(" Erreur lecture ATR");
      return false;
   }

   double atr = atrBuffer[0];

   if (atr < 50 * pointValue)
   {
      Print(" ATR trop faible : ", atr);
      return false;
   }

   return true;
}


bool RSIFilterOk(int signal)
{
   if (signal == 0)
      return false;

   string symbol = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_M10;
   int rsiPeriod = 14;

   double rsiBuffer[];
   int rsiHandle = iRSI(symbol, tf, rsiPeriod, PRICE_CLOSE);

   if (rsiHandle == INVALID_HANDLE)
   {
      Print(" Erreur création handle RSI");
      return false;
   }

   if (CopyBuffer(rsiHandle, 0, 0, 1, rsiBuffer) <= 0)
   {
      Print(" Erreur lecture RSI");
      return false;
   }

   double rsi = rsiBuffer[0];
   Print("RSI = ", rsi);

   if (signal == 1 && rsi > 30)
   {
      Print(" Signal BUY bloqué : RSI > 30");
      return false;
   }

   if (signal == -1 && rsi < 70)
   {
      Print(" Signal SELL bloqué : RSI < 70");
      return false;
   }

   return true;
}



bool CanTradeNow()
{
   if (lastTradeWasLoss && (TimeCurrent() - lastTradeTime < cooldownSeconds))
   {
      Print(" Pause après perte encore active : ", (cooldownSeconds - (TimeCurrent() - lastTradeTime)), " sec restantes");
      return false;
   }
   return true;
}


bool IsTradeAllowed(int signal)
{
   return (
      //TimeFilterOk() 
      //TrendFilterOk(signal)
      //VolatilityFilterOk() 
      //RSIFilterOk(signal)
      true
   );
}
