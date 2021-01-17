//+------------------------------------------------------------------+
//|                                            Crypto_Stoch_robo.mq5 |
//|                                                         Tarcyzio |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tarcyzio"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
CTrade trade;

input double   PorcentLoss = 0.5;
input double   PorcentGain = 3;
input int      Sch_K = 33;
input int      Sch_D = 21;
input int      Sch_retard = 19;

bool isLong;

int   magicNB = 151515;
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
      Sleep(1000*60*60*1);
      
      double balanco  = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
      double equidade = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY),2);
      double Ask      = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
      double Bid      = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
      
      datetime date1=TimeCurrent();
      MqlDateTime str1;
      TimeToStruct(date1,str1);
      
      MqlRates PriceInfo[];
      ArraySetAsSeries(PriceInfo,true);
      int Data = CopyRates(Symbol(),Period(),0,3,PriceInfo);
      
      double SchMainArray [];
      double SchSignalArray [];
      int SchDefinition = iStochastic(_Symbol,_Period,Sch_K,Sch_D,Sch_retard,MODE_EMA,STO_LOWHIGH);
      ArraySetAsSeries(SchMainArray,true);
      ArraySetAsSeries(SchSignalArray,true);
      CopyBuffer(SchDefinition,0,0,3,SchMainArray);
      CopyBuffer(SchDefinition,1,0,3,SchSignalArray);
      double SchMainValue0 = NormalizeDouble(SchMainArray[0],2);
      double SchSignalValue0 = NormalizeDouble(SchSignalArray[0],2);
      double SchMainValue1 = NormalizeDouble(SchMainArray[1],2);
      double SchSignalValue1 = NormalizeDouble(SchSignalArray[1],2);
      
      if(SchSignalValue0 < SchMainValue0 && SchSignalValue1 > SchMainValue1 && PositionsTotal()==0)// && str1.hour < 17)
      {
         isLong = true;
         int AskD = Ask / 0.5;
         double contratos = NormalizeDouble(balanco / Ask,2);
         Print("buy");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = NormalizeDouble(contratos,1);                                   
         request.type     = ORDER_TYPE_BUY;                        
         request.price    = Ask; 
         request.deviation= 50;                                     
         request.magic    = magicNB;
         request.sl       = NormalizeDouble((AskD * 0.5)*(1-PorcentLoss/100),1);               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      
      else if(SchSignalValue0 > SchMainValue0 && SchSignalValue1 < SchMainValue1 && PositionsTotal()==0)// && str1.hour < 17)
      {
         isLong = false;
         int BidD = Bid / 0.5;
         double contratos = NormalizeDouble(balanco / Bid,2);
         Print("sell");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = NormalizeDouble(contratos,1);                                   
         request.type     = ORDER_TYPE_SELL;                        
         request.price    = Bid; 
         request.deviation= 50;                                     
         request.magic    = magicNB;
         request.sl       = NormalizeDouble((BidD * 0.5)*(1+PorcentLoss/100),1);               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      else if(PositionsTotal() != 0)// && str1.hour < 17)
      {
         if(equidade > balanco*(1+PorcentGain/100))
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
