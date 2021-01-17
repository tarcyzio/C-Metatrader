//+------------------------------------------------------------------+
//|                                           Crypto_TriEMA_robo.mq5 |
//|                                                         Tarcyzio |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tarcyzio"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
CTrade trade;

//BTCUSD 2H

input double   PorcentLoss = 0.5;
input double   PorcentGain = 3;
input int      EMA0_Period = 20;
input int      EMA1_Period = 50;
input int      EMA2_Period = 100;

bool isLong;

int   magicNB = 171717;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- 
      Sleep(1000*5);
      double balanco  = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
      double equidade = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY),2);
      double Ask      = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
      double Bid      = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
      
      double EMA0Array [];
      double EMA0Definition = iMA(_Symbol,_Period,EMA0_Period,0,MODE_EMA,PRICE_CLOSE);
      ArraySetAsSeries(EMA0Array,true);
      CopyBuffer(EMA0Definition,0,0,3,EMA0Array);
      double EMA0Value = EMA0Array[1];
      
      double EMA1Array [];
      double EMA1Definition = iMA(_Symbol,_Period,EMA1_Period,0,MODE_EMA,PRICE_CLOSE);
      ArraySetAsSeries(EMA1Array,true);
      CopyBuffer(EMA1Definition,0,0,3,EMA1Array);
      double EMA1Value = EMA1Array[1];
      
      double EMA2Array [];
      double EMA2Definition = iMA(_Symbol,_Period,EMA2_Period,0,MODE_EMA,PRICE_CLOSE);
      ArraySetAsSeries(EMA2Array,true);
      CopyBuffer(EMA2Definition,0,0,3,EMA2Array);
      double EMA2Value = EMA2Array[1];
      
      if(EMA0Value > EMA1Value /*&& EMA1Value > EMA2Value*/ && PositionsTotal() == 0)
      {
         isLong = true;
         int AskD = Ask / 0.5;
         double contratos = NormalizeDouble(balanco / Ask,2);
         Comment("buy");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = NormalizeDouble(contratos,1);                                   
         request.type     = ORDER_TYPE_BUY;                        
         request.price    = Ask; 
         request.deviation= 50;                                     
         request.magic    = magicNB;
         request.sl       = 0;//NormalizeDouble((AskD * 0.5)*(1-PorcentLoss/100),1);               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      
      else if(EMA0Value < EMA1Value /*&& EMA1Value < EMA2Value*/ && PositionsTotal() == 0)
      {
         isLong = false;
         int BidD = Bid / 0.5;
         double contratos = NormalizeDouble(balanco / Bid,2);
         Comment("sell");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = NormalizeDouble(contratos,1);                                   
         request.type     = ORDER_TYPE_SELL;                        
         request.price    = Bid; 
         request.deviation= 50;                                     
         request.magic    = magicNB;
         request.sl       = 0;//NormalizeDouble((BidD * 0.5)*(1+PorcentLoss/100),1);               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      else if(PositionsTotal() != 0)
      {
         if((isLong == true && EMA0Value < EMA1Value) || (isLong == false && EMA0Value > EMA1Value))
         {
            CloseBuySellSymbol();
         }
      }
  }
void CheckTrailingStop(int Ask,int Bid,bool isLong)
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      string symbol=PositionGetSymbol(i);
      
      if(_Symbol==symbol)
      {
         ulong PositionTicket=PositionGetInteger(POSITION_TICKET);
         
         int AskD = Ask / 0.1;
         int BidD = Bid / 0.1;
         double SLb = (AskD * 0.1)*(1-PorcentLoss/100);
         double SLs = (BidD * 0.1)*(1+PorcentLoss/100);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
      
         if(CurrentStopLoss<SLb && isLong == true)
         {
            MqlTradeRequest request={0};
            MqlTradeResult  result= {0};
            request.action    = TRADE_ACTION_SLTP;
            request.position  = PositionTicket;
            request.symbol    = _Symbol;
            request.sl        = CurrentStopLoss +25;
            request.tp        = 0;
            request.magic     = magicNB;
                  
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
         }
         if(CurrentStopLoss>SLs && isLong == false)
         {
            MqlTradeRequest request={0};
            MqlTradeResult  result= {0};
            request.action    = TRADE_ACTION_SLTP;
            request.position  = PositionTicket;
            request.symbol    = _Symbol;
            request.sl        = CurrentStopLoss -25;
            request.tp        = 0;
            request.magic     = magicNB;
                  
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
         }
      }
   }
}

void CloseBuySellSymbol()
 {
    for(int i=PositionsTotal()-1; i>=0; i--)
    {
       ulong ticket=PositionGetTicket(i);
       trade.PositionClose(ticket);   
    }  
 }
//+------------------------------------------------------------------+
