//+------------------------------------------------------------------+
//|                                             Crypto_MACD_robo.mq5 |
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
input int      MACD_fEMA = 17;
input int      MACD_sEMA = 33;
input int      MACD_SMA = 20;

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
      Sleep(1000*60*60*2);
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
      
      double MACDArray [];
      int MACDDefinition = iMACD(_Symbol,_Period,MACD_fEMA,MACD_sEMA,MACD_SMA,PRICE_CLOSE);
      ArraySetAsSeries(MACDArray,true);
      CopyBuffer(MACDDefinition,0,0,3,MACDArray);
      double MACDValue = MACDArray[1];
      
      if(MACDValue > 0 && PositionsTotal()==0)// && str1.hour < 17)
      {
         isLong = true;
         int AskD = Ask / 0.5;
         double contratos = NormalizeDouble(balanco / Ask,2);
         Comment("buy");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = 1;//NormalizeDouble(contratos,1);                                   
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
      
      else if(MACDValue < 0 && PositionsTotal()==0)// && str1.hour < 17)
      {
         isLong = false;
         int BidD = Bid / 0.5;
         double contratos = NormalizeDouble(balanco / Bid,2);
         Comment("sell");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = 1;//NormalizeDouble(contratos,1);                                   
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
      else if(PositionsTotal() != 0)// && str1.hour < 17)
      {
         if((isLong == true && MACDValue < 0) || (isLong == false && MACDValue > 0))
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
