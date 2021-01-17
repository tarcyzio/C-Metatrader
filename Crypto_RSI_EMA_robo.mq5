//+------------------------------------------------------------------+
//|                                          Crypto_RSI_EMA_robo.mq5 |
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
input int RSI_Period = 5;

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
      
      double EMAArray [];
      double EMADefinition = iMA(_Symbol,_Period,EMA_Period,0,MODE_EMA,PRICE_CLOSE);
      ArraySetAsSeries(EMAArray,true);
      CopyBuffer(EMADefinition,0,0,3,EMAArray);
      double EMAValue = EMAArray[1];
      
      double RSIArray [];
      double RSIDefinition = iRSI(_Symbol,_Period,RSI_Period,PRICE_CLOSE);
      ArraySetAsSeries(RSIArray,true);
      CopyBuffer(RSIDefinition,0,0,3,RSIArray);
      double RSIValue0 = RSIArray[0];
      double RSIValue1 = RSIArray[1];
      
      if(PriceInfo[1].close > EMAValue && RSIValue1 < 20 && RSIValue0 > 20 && PositionsTotal() == 0)
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
         request.sl       = AskDL*0.5;               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      
      else if(PriceInfo[1].close < EMAValue && RSIValue1 > 80 && RSIValue0 < 80 && PositionsTotal() == 0)
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
         request.sl       = BidDL*0.5;               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      else if(PositionsTotal() != 0)
      /*{
         CheckTrailingStop(Ask,Bid,isLong);
      }*/
      if((isLong == true && RSIValue1 > 80 && RSIValue0 < 80) || (isLong == false && RSIValue1 < 20 && RSIValue0 > 20))
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
