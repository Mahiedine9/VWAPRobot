//+------------------------------------------------------------------+
//|                                                    VWAPRobot.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property strict

#define EA_VERSION "v3.1"

#include <Trade\Trade.mqh>

#include "Utils.mqh"
#include "ConvergingVWAP.mqh"
#include "DivergingVWAP.mqh"
#include "TradeExecutor.mqh"
#include "TradeManager.mqh"
#include "SL/StopLossATR.mqh"
#include "SL/FixedStopLoss.mqh"
#include "SL/StopLossVWAP.mqh"
#include "SL/StopLossSwing.mqh"



enum ENUM_StopLossType
{
   SL_FIXED = 0,
   SL_ATR,
   SL_VWAP,
   SL_SWING
};

//+------------------------------------------------------------------+
//| Paramètres externes                                             |
//+------------------------------------------------------------------+
input int    VWAP_LookbackBars    = 10;
input double VWAPEntryBuffer      = 13.0;
input double RiskPercent          = 1.0;
input ulong  MagicNumber          = 123456;

input bool   UseConvergingStrategy = true;
input bool   UseDivergingStrategy  = false;

input bool   UseBreakEven         = false;
input int    MinProfitToBE        = 95;

input bool   UseTrailingStop      = false;
input int    TrailingStopPoints   = 50;
input int    MinProfitToTrailing  = 70;


input ENUM_StopLossType StopLossType = SL_ATR;
input int    FixedSL_Points           = 180;       
input int    ATR_Period               = 8.0;
input double ATR_Multiplier           = 2.35;
input int    SwingLookback            = 15;
input int    SwingOffset              = 20;

input int CooldownAfterLossSec = 1900;


input bool   UsePartialTP         = false;
input double PartialTP_Points     = 150;  
input double PartialTP_Volume     = 0.5;   


//+------------------------------------------------------------------+
//| Objets globaux                                                  |
//+------------------------------------------------------------------+
ConvergingVWAP *converging = NULL;
DivergingVWAP  *diverging  = NULL;
TradeExecutor  *executor   = NULL;
TradeManager   *manager    = NULL;
IStopLoss *stopLoss = NULL; 
datetime lastTradeTime = 0;
bool     lastTradeWasLoss = false;
int cooldownSeconds = 0;



//+------------------------------------------------------------------+
//| Initialisation de l’EA                                          |
//+------------------------------------------------------------------+
int OnInit()
{
   cooldownSeconds = CooldownAfterLossSec;
   Print(" Démarrage de l'EA - Version ", EA_VERSION);


   string symbol = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

   if (UseConvergingStrategy)
      converging = new ConvergingVWAP(symbol, tf, VWAP_LookbackBars, VWAPEntryBuffer);

   if (UseDivergingStrategy)
      diverging = new DivergingVWAP(symbol, tf, VWAP_LookbackBars, VWAPEntryBuffer);

   switch(StopLossType)
   {
      case SL_FIXED:
         stopLoss = new FixedStopLoss(FixedSL_Points, _Point);
         break;
      case SL_ATR:
         stopLoss = new StopLossATR(ATR_Period, ATR_Multiplier);
         break;
      case SL_VWAP:
         stopLoss = new StopLossVWAP(FixedSL_Points);
         break;
      case SL_SWING:
         stopLoss = new StopLossSwing(SwingLookback, SwingOffset);
         break;
   }



   manager = new TradeManager(
      converging,
      diverging,
      NULL,
      UseConvergingStrategy,
      UseDivergingStrategy,
      UseBreakEven,
      MinProfitToBE,
      UseTrailingStop,
      TrailingStopPoints,
      MinProfitToTrailing, 
      UsePartialTP,
      PartialTP_Points,
      PartialTP_Volume
   );


   executor = new TradeExecutor(symbol, manager, stopLoss, MagicNumber, RiskPercent);


   manager.SetExecutor(executor);

   string slName = EnumToString(StopLossType);
   Print("VWAPRobotPro initialisé avec SL de type : ", slName);

   return INIT_SUCCEEDED;
}


//+------------------------------------------------------------------+
//| Tick principal                                                   |
//+------------------------------------------------------------------+
void OnTick()
{
   if (manager != NULL)
      manager.OnTick();
}

//+------------------------------------------------------------------+
//| Gestion des transactions                                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if (manager != NULL)
      manager.OnTradeTransaction(trans, request, result);

   if (trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      ulong deal_id = trans.deal;

      if (HistoryDealSelect(deal_id))
      {
         double deal_profit = HistoryDealGetDouble(deal_id, DEAL_PROFIT);
         int    deal_entry  = (int)HistoryDealGetInteger(deal_id, DEAL_ENTRY);

         if (deal_entry == DEAL_ENTRY_OUT)
         {
            if (deal_profit < 0)
            {
               lastTradeWasLoss = true;
               lastTradeTime = TimeCurrent();
               Print(" Trade clôturé en perte. Pause de ", CooldownAfterLossSec, " secondes activée.");
            }
            else
            {
               lastTradeWasLoss = false;
               Print(" Trade clôturé gagnant. Reset cooldown.");
            }
         }
      }
   }
}


//+------------------------------------------------------------------+
//| Libération mémoire                                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   delete converging;
   delete diverging;
   delete executor;
   delete manager;
   delete stopLoss;
}


