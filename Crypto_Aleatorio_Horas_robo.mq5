//+------------------------------------------------------------------+
//|                                 Crypto_Aleatorio_Horas_robo.mql5 |
//|                                                         Tarcyzio |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tarcyzio"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
#include <CustomFunctions.mqh>
CTrade trade;

input int EMA_Period = 200;
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
      
      datetime date1=TimeCurrent();
      MqlDateTime str1;
      TimeToStruct(date1,str1);
      
      MqlRates PriceInfo[];
      ArraySetAsSeries(PriceInfo,true);
      int Data = CopyRates(Symbol(),Period(),0,3,PriceInfo);
      
      double EMAArray [];
      double EMADefinition = iMA(_Symbol,_Period,EMA_Period,0,MODE_EMA,PRICE_CLOSE);
      ArraySetAsSeries(EMAArray,true);
      CopyBuffer(EMADefinition,0,0,3,EMAArray);
      double EMAValue = EMAArray[1];
      
      //if((str1.hour == 2 || str1.hour == 4 || str1.hour == 6 || str1.hour == 8 || str1.hour == 10 || str1.hour == 12 || str1.hour == 14 || str1.hour == 16 || str1.hour == 18 || str1.hour == 20 || str1.hour == 22) && str1.min == 1 && PositionsTotal() == 0)
      if(str1.min == 1 && PriceInfo[1].close > EMAValue && PositionsTotal() == 0)
      {
         
         int AskDL = Ask*FLossLong/0.5;
         isLong = true;
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
         request.sl       = AskDL*0.5;               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      
      //else if((str1.hour == 1 || str1.hour == 3 || str1.hour == 5 || str1.hour == 7 || str1.hour == 9 || str1.hour == 11 || str1.hour == 13 || str1.hour == 15 || str1.hour == 17 || str1.hour == 19 || str1.hour == 21) && str1.min == 1 && PositionsTotal() == 0)
      else if(str1.min == 1 && PriceInfo[1].close < EMAValue && PositionsTotal() == 0)
      {
         int BidDL = Bid*FLossShort/0.5;
         isLong = false;
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
         request.sl       = BidDL*0.5;               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      else if(PositionsTotal() != 0)
      {
         CheckTrailingStop(Ask,Bid,isLong);
      }
      /*if(str1.min == 59)
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
         
         int AskDL = Ask*FLossLong/0.5;
         int BidDL = Bid*FLossShort/0.5;
         double SLb = AskDL * 0.5;
         double SLs = BidDL * 0.5;
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
