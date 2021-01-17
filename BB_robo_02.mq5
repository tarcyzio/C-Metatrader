//+------------------------------------------------------------------+
//|                                                   BB_robo_02.mq5 |
//|                                                         Tarcyzio |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tarcyzio"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
#include <CustomFunctions.mqh>
CTrade trade;

input int BBPeriod = 20;
input int BBDev = 2;
input int PipsLoss = 400;
input int capitalPorContratos = 1000;

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
      double balanco  = AccountInfoDouble(ACCOUNT_BALANCE);
      double equidade = AccountInfoDouble(ACCOUNT_EQUITY);
      int Ask      = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      int Bid      = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      int contratos = balanco / capitalPorContratos;
      
      datetime date1=TimeCurrent();
      MqlDateTime str1;
      TimeToStruct(date1,str1);
      
      MqlRates PriceInfo[];
      ArraySetAsSeries(PriceInfo,true);
      int Data = CopyRates(Symbol(),Period(),0,3,PriceInfo);
      
      double MiddleBandArray[];
      double UpperBandArray[];
      double LowerBandArray[];
      
      ArraySetAsSeries(MiddleBandArray,true);
      ArraySetAsSeries(UpperBandArray,true);
      ArraySetAsSeries(LowerBandArray,true);
      
      int BollingerBandsDefinition = iBands(_Symbol,_Period,BBPeriod,0,BBDev,PRICE_CLOSE);
      
      CopyBuffer(BollingerBandsDefinition,0,0,3,MiddleBandArray);
      CopyBuffer(BollingerBandsDefinition,1,0,3,UpperBandArray);
      CopyBuffer(BollingerBandsDefinition,2,0,3,LowerBandArray);
      
      double myMiddleBandValue0 = MiddleBandArray[0];
      double myUpperBandValue0 = UpperBandArray[0];
      double myLowerBandValue0 = LowerBandArray[0];
      
      double myMiddleBandValue1 = MiddleBandArray[1];
      double myUpperBandValue1 = UpperBandArray[1];
      double myLowerBandValue1 = LowerBandArray[1];
      
      if((PriceInfo[1].close < myLowerBandValue1)&&(PriceInfo[0].close > myLowerBandValue0) && PositionsTotal()==0 && str1.hour < 17)
      {
         isLong = true;
         int AskD = Ask / 5;
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
         request.sl       = AskD*5 - PipsLoss;               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      
      else if((PriceInfo[1].close > myUpperBandValue1)&&(PriceInfo[0].close < myUpperBandValue0) && PositionsTotal()==0 && str1.hour < 17)
      {
         isLong = false;
         int BidD = Bid / 5;
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
         request.sl       = BidD*5 + PipsLoss;               
         request.tp       = 0;
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      else if(PositionsTotal() != 0)
      {
         if(str1.hour > 16)
         {
            CloseBuySellSymbol();
         }
         CheckTrailingStop(Ask,Bid,isLong);
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
         
         int AskD = Ask / 5;
         int BidD = Bid / 5;
         int SLb = AskD*5 - PipsLoss;
         int SLs = BidD*5 + PipsLoss;
         int CurrentStopLoss = PositionGetDouble(POSITION_SL);
      
         if(CurrentStopLoss<SLb && isLong == true)
         {
            MqlTradeRequest request={0};
            MqlTradeResult  result= {0};
            request.action    = TRADE_ACTION_SLTP;
            request.position  = PositionTicket;
            request.symbol    = _Symbol;
            request.sl        = CurrentStopLoss +10;
            request.tp        = 0;
            request.magic     = magicNB;
                  
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            //trade.PositionModify(PositionGetTicket(0),(CurrentStopLoss+10),0);
         }
         if(CurrentStopLoss>SLs && isLong == false)
         {
            Alert("sim", CurrentStopLoss);
            MqlTradeRequest request={0};
            MqlTradeResult  result= {0};
            request.action    = TRADE_ACTION_SLTP;
            request.position  = PositionTicket;
            request.symbol    = _Symbol;
            request.sl        = CurrentStopLoss -10;
            request.tp        = 0;
            request.magic     = magicNB;
                  
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            //trade.PositionModify(PositionGetTicket(0),SL,0);
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
