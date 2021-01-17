//+------------------------------------------------------------------+
//|                                               Crypto_LR_robo.mq5 |
//|                                                         Tarcyzio |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tarcyzio"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
CTrade trade;

int magicNB = 333333;
bool isLong;

input int      QtdeBarras = 30;
input int      RegrGrau = 1;
input double   RegrShiftCurto = 1.0;
input double   RegrShiftLongo = 2.0;
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
      
      double i_regrCurto = iCustom(_Symbol,_Period,"i_regr_channel_time",RegrGrau,RegrShiftCurto,QtdeBarras,PRICE_CLOSE,0);
      double i_regrLongo = iCustom(_Symbol,_Period,"i_regr_channel_time",RegrGrau,RegrShiftLongo,QtdeBarras,PRICE_CLOSE,0);
      
      double i_regrCurtoArrayUp [];
      double i_regrCurtoArrayDown [];
      double i_regrCurtoArrayMed [];
      double i_regrLongoArrayUp [];
      double i_regrLongoArrayDown [];
      double i_regrLongoArrayMed [];
      
      ArraySetAsSeries(i_regrCurtoArrayUp,true);
      ArraySetAsSeries(i_regrCurtoArrayDown,true);
      ArraySetAsSeries(i_regrCurtoArrayMed,true);
      ArraySetAsSeries(i_regrLongoArrayUp,true);
      ArraySetAsSeries(i_regrLongoArrayDown,true);
      ArraySetAsSeries(i_regrLongoArrayMed,true);
      
      CopyBuffer(i_regrCurto,0,0,3,i_regrCurtoArrayUp);
      CopyBuffer(i_regrCurto,1,0,3,i_regrCurtoArrayDown);
      CopyBuffer(i_regrCurto,2,0,3,i_regrCurtoArrayMed);
      CopyBuffer(i_regrLongo,0,0,3,i_regrLongoArrayUp);
      CopyBuffer(i_regrLongo,1,0,3,i_regrLongoArrayDown);
      CopyBuffer(i_regrLongo,2,0,3,i_regrLongoArrayMed);
      
      double i_regrCurtoUpV = i_regrCurtoArrayUp[1];
      double i_regrCurtoDownV = i_regrCurtoArrayDown[1];
      double i_regrCurtoMedV = i_regrCurtoArrayMed[1];
      double i_regrLongoUpV = i_regrLongoArrayUp[1];
      double i_regrLongoDownV = i_regrLongoArrayDown[1];
      double i_regrLongoMedV = i_regrLongoArrayMed[1];
      
      Comment("i_regrLongoUpV: ",i_regrLongoUpV);
      Comment("i_regrCurtoUpV: ",i_regrCurtoUpV);
      Comment("i_regrCurtoMedV: ",i_regrCurtoMedV);
      Comment("i_regrLongoMedV: ",i_regrLongoMedV);
      Comment("i_regrCurtoDownV: ",i_regrCurtoDownV);
      Comment("i_regrLongoDownV: ",i_regrLongoDownV);
      
      double i_regrCurtoMedV01 = i_regrCurtoArrayMed[1];
      double i_regrCurtoMedV02 = i_regrCurtoArrayMed[2];
      
  if(i_regrCurtoMedV01 > i_regrCurtoMedV02 && PositionsTotal() == 0)
      {
         isLong = true;
         int AskD = Ask / 5;
         Comment("buy");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = 1;                                   
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
      
      else if(i_regrCurtoMedV01 < i_regrCurtoMedV02 && PositionsTotal() == 0)
      {
         isLong = false;
         int BidD = Bid / 5;
         Comment("sell");
         MqlTradeRequest request={0};
         MqlTradeResult  result= {0};
         request.action   = TRADE_ACTION_DEAL;                     
         request.symbol   = _Symbol;                              
         request.volume   = 1;                                   
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
      {
         if((isLong == true && i_regrCurtoMedV01 < i_regrCurtoMedV02) || (isLong == false && i_regrCurtoMedV01 > i_regrCurtoMedV02))
         {
            CloseBuySellSymbol();
         }
      }
  }
void CheckTrailingStop(double myLowerBandValue2, double myUpperBandValue2, bool isLong)
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      string symbol=PositionGetSymbol(i);
      
      if(_Symbol==symbol)
      {
         ulong PositionTicket=PositionGetInteger(POSITION_TICKET);
         
         int AskD = myLowerBandValue2 / 5;
         int BidD = myUpperBandValue2 / 5;
         double SLb = AskD * 5;
         double SLs = BidD * 5;
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
      
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
         }
         if(CurrentStopLoss>SLs && isLong == false)
         {
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

