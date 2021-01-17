//+------------------------------------------------------------------+
//|                                             Crypto_ICHI_robo.mq5 |
//|                                                         Tarcyzio |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tarcyzio"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
#include <CustomFunctions.mqh>
CTrade trade;

input int tenkan_sen = 9;
input int kijun_sen = 26;
input int senkou = 52;

input double FLossLong = 0.95;
input double FLossShort = 1.05;

bool isLong;

int   magicNB = 121212;
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
      double balanco  = AccountInfoDouble(ACCOUNT_BALANCE);
      double equidade = AccountInfoDouble(ACCOUNT_EQUITY);
      int Ask      = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      int Bid      = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      
      MqlRates PriceInfo[];
      ArraySetAsSeries(PriceInfo,true);
      int Data = CopyRates(Symbol(),Period(),0,3,PriceInfo);
      
      double SpanAArray [];
      double SpanBArray [];
      double IchiDefinition = iIchimoku(_Symbol,_Period,tenkan_sen,kijun_sen,senkou);
      ArraySetAsSeries(SpanAArray,true);
      ArraySetAsSeries(SpanBArray,true);
      CopyBuffer(IchiDefinition,2,0,3,SpanAArray);
      CopyBuffer(IchiDefinition,3,0,3,SpanBArray);
      double SpanAValue = SpanAArray[1];
      double SpanBValue = SpanBArray[1];
      
      if(PriceInfo[1].close > SpanAValue && PriceInfo[1].close > SpanBValue && PositionsTotal() == 0)
      {
         isLong = true;
         int AskD = Ask / 0.5;
         int AskDL = Ask*FLossLong/0.5;
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
         request.sl       = 0;               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      
      else if(PriceInfo[1].close < SpanAValue && PriceInfo[1].close < SpanBValue && PositionsTotal() == 0)
      {
         isLong = false;
         int BidD = Bid / 0.5;
         int BidDL = Bid*FLossShort/0.5;
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
         request.sl       = 0;               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      else if(PositionsTotal() != 0)
      /*{
         CheckTrailingStop(Ask,Bid,isLong);
      }*/
      if((isLong == true && (PriceInfo[1].close < SpanAValue || PriceInfo[1].close < SpanBValue)) || (isLong == false && (PriceInfo[1].close > SpanAValue || PriceInfo[1].close > SpanBValue)))
      {
         CloseBuySellSymbol();
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
         
         int AskDL = Ask*FLossLong/0.5;
         int BidDL = Bid*FLossShort/0.5;
         int SLb = AskDL * 0.5;
         int SLs = BidDL * 0.5;
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
      
         if(CurrentStopLoss<SLb && isLong == true)
         {
            MqlTradeRequest request={0};
            MqlTradeResult  result= {0};
            request.action    = TRADE_ACTION_SLTP;
            request.position  = PositionTicket;
            request.symbol    = _Symbol;
            request.sl        = SLb;
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
            request.sl        = SLs;
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
