//+------------------------------------------------------------------+
//|                                              Crypto_RSI_robo.mq5 |
//|                                                         Tarcyzio |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tarcyzio"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
CTrade trade;

input int      RSIPeriod = 14;
input double   PorcentLoss = 5;
input int      MAPeriod1 = 30;

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
      
      double RSIArray [];
      int RSIDefinition = iRSI(_Symbol,_Period,RSIPeriod,PRICE_CLOSE);
      ArraySetAsSeries(RSIArray,true);
      CopyBuffer(RSIDefinition,0,0,3,RSIArray);
      double RSIValue0 = NormalizeDouble(RSIArray[0],2);
      double RSIValue2 = NormalizeDouble(RSIArray[2],2);
      
      double MA1Array [];
      int MA1handle = iMA(_Symbol,PERIOD_H1,MAPeriod1,0,MODE_EMA,PRICE_CLOSE);
      ArraySetAsSeries(MA1Array,true);
      CopyBuffer(MA1handle,0,0,1,MA1Array);
      double MA1Price = MA1Array[0];
      
      if(RSIValue0 > 30 && RSIValue2 < 30 /*&& PriceInfo[0].close > MA1Price*/ && PositionsTotal()==0)// && str1.hour < 17)
      {
         isLong = true;
         int AskD = Ask / 0.1;
         double contratos = NormalizeDouble(balanco / Ask,2);
         Print("buy");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = contratos;                                   
         request.type     = ORDER_TYPE_BUY;                        
         request.price    = Ask; 
         request.deviation= 50;                                     
         request.magic    = magicNB;
         request.sl       = (AskD * 0.1)*(1-PorcentLoss/100);               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      
      else if(RSIValue0 < 70 && RSIValue2 > 70 /*&& PriceInfo[0].close < MA1Price*/ && PositionsTotal()==0)// && str1.hour < 17)
      {
         isLong = false;
         int BidD = Bid / 0.1;
         double contratos = NormalizeDouble(balanco / Bid,2);
         Print("sell");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = contratos;                                   
         request.type     = ORDER_TYPE_SELL;                        
         request.price    = Bid; 
         request.deviation= 50;                                     
         request.magic    = magicNB;
         request.sl       = (BidD * 0.1)*(1+PorcentLoss/100);               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      else if(PositionsTotal() != 0)// && str1.hour < 17)
      {
         CheckTrailingStop(Ask,Bid,isLong);
      }
      /*else if(PositionsTotal() != 0 && str1.hour > 16)
      {
         CloseBuySellSymbol();
      }*/
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
