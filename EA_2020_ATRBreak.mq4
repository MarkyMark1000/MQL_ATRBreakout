//+------------------------------------------------------------------+
//|                                             EA_2020_ATRBreak.mq4 |
//|                                   https://www.markjohnwilson.com |
//+------------------------------------------------------------------+
#include <C_BASIC_OPTIMIZATION_LOG.mqh>

#property copyright "Copyright 2020, Mark Wilson."
#property link      "https://www.markjohnwilson.net"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                            |
//+------------------------------------------------------------------+
//--- day of week
enum StoplossMethod 
  {
   LowOrHighOfLast2Candles=0,
   ATRMultiplier=1,
  };
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input int I_MagicNumber = 20200505;             //Magic Number
input int I_ATRPeriod = 5;                      //ATR Period
input double I_AtRisk=20;                       //AtRisk in Account Curr
input StoplossMethod I_StoplossMethod=0;        //Stoploss Calculation Method.
input int I_ReversionPercent=20;                //Reversion of Limit/Stop Open relative to last 2 candles.
input double I_StoplossATRMultiplier=1.0;       //ATRMultiplier to calculate stoploss.
input double I_TypicalSpread = 0.00030;         //Typical Spread used in SL Offsets
input double I_MaxLotSize=0.5;                  //Max Lot Size for Risk Management.
input double I_RiskRewardRatio=1.5;             //Risk/Reward Ratio for T.P.
input int I_LimitStopOrderExpiryMins=60;        //Lim/Stop Order Duration in minutes.
input double I_HiddenStoplossOffset=0;          //Hidden Stoploss offset.
input int I_TradingStartHour=7;                 //Trading Start Hour.
input int I_TradingEndHour=20;                  //Trading End Hour.
input bool I_LogResultsInFile=false;            //Log Results in File.
//+------------------------------------------------------------------+
//| Description                                                      |
//+------------------------------------------------------------------+
/*
If you look at a one hour fx chart, plotting the ATR, you will see that
there is a certain cyclical pattern.   Generally the volatility/ATR 
increases during the trading day, but then shrinks significantly during
the night.   This EA is looking for a signal when the ATR is low and
increasing and the trading day is just starting.   It looks at the ATR 
peak and trough from the previous day and then only trades when the ATR
increase, but is below the mid of the previous days peak/trough.
It looks for a fat candle breaking out of the previous days mid +/- 0.5ATR
and the candle before that being below the band.   It then sets a
Limit/Stop order relative the previous 2 candles by the amount I_ReversionPercent.
If I_ReversionPercent is 50, the limit order position will be half way between
the close and low of the break-up (2) candles.   If it is -50, then it will
by 50% above the close of a break-up (2) candles.

The Lot size can be capped to limit gap risk.
When entering a trade, the StopLoss is placed TypicalSpread below/above the
relevant low/high.
A hidden stoploss can also be used if I_HiddenStoplossOffset is greater than
zero.

*/
//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   //--- Blank out comment
   Comment("");

   Print("***********************************************");
   Print("*******************  EA START******************");
   Print("***********************************************");
         
   //--- Input Validation
   
   if(I_ATRPeriod<2 || I_ATRPeriod>200)
   {
      reportError("ATR Period must be between 2 and 200");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(I_AtRisk<=0)
   {
      reportError("AtRisk must be positive");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(I_ReversionPercent<-100 || I_ReversionPercent>100)
   {
      reportError("Reversion Percent must be between -100 and 100");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(I_TypicalSpread<0)
   {
      reportError("Stoploss Spread Offset cannot be negative.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(I_MaxLotSize<0)
   {
      reportError("Max LotSize cannot be negative.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(I_RiskRewardRatio<=0)
   {
      reportError("Risk/Reward ratio cannot be less than or equal to zero.");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(I_LimitStopOrderExpiryMins<PeriodSeconds()/60)
   {
      reportError("Stop/Limit Order Expiry cannot be less than the period of the chart.");
      return(INIT_PARAMETERS_INCORRECT);
   }
      
   if(I_HiddenStoplossOffset<0)
   {
      reportError("Hidden Stoploss Offset cannot be less than zero.");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
//---
   return(INIT_SUCCEEDED);
  }
void reportError(string strError)
{
   Print(strError);
   Comment(strError);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- If we are recording the results in a log file, then add the titles
   if(I_LogResultsInFile)
   {
      //--- REMEMBER TO DELETE THE FILE BEFORE EACH OPTIMIZATION OTHERWISE
      //--- YOUR FILE WILL CONTAIN MIXED RESULTS.
      
      //-- Get parameter titles 
      string strEAParameterTitles[14] = {"I_MagicNumber", "I_ATRPeriod", "I_AtRisk",
            "I_StoplossMethod", "I_ReversionPercent","I_StoplossATRMultiplier", "I_TypicalSpread",
            "I_MaxLotSize", "I_RiskRewardRatio", "I_LimitStopOrderExpiryMins", "I_HiddenStoplossOffset",
            "I_TradingStartHour", "I_TradingEndHour", "I_LogResultsInFile"};
      
      //-- Initiate the Log object
      C_BASIC_OPTIMIZATION_LOG *objLog = new C_BASIC_OPTIMIZATION_LOG(strEAParameterTitles);
      
      //-- Get array of paramter values
      string strEAParameterValues[14];
      strEAParameterValues[0] = IntegerToString(I_MagicNumber);
      strEAParameterValues[1] = IntegerToString(I_ATRPeriod);
      strEAParameterValues[2] = DoubleToString(I_AtRisk,4);
      strEAParameterValues[3] = EnumToString(I_StoplossMethod);
      strEAParameterValues[4] = IntegerToString(I_ReversionPercent);
      strEAParameterValues[5] = DoubleToString(I_StoplossATRMultiplier,4);
      strEAParameterValues[6] = DoubleToString(I_TypicalSpread,6);
      strEAParameterValues[7] = DoubleToString(I_MaxLotSize,6);
      strEAParameterValues[8] = DoubleToString(I_RiskRewardRatio,6);
      strEAParameterValues[9] = IntegerToString(I_LimitStopOrderExpiryMins);
      strEAParameterValues[10] = DoubleToString(I_HiddenStoplossOffset,6);
      strEAParameterValues[11] = IntegerToString(I_TradingStartHour);
      strEAParameterValues[12] = IntegerToString(I_TradingEndHour);
      strEAParameterValues[13] = IntegerToString(I_LogResultsInFile);

      //-- Now Update the log object
      objLog.UpdateLog(I_MagicNumber, strEAParameterValues);
      
      //-- Print location of log file
      Print("***********************************************");
      objLog.PrintLocationOfLogFiles();
      
      //-- Now delete the log object and arrays
      ArrayFree(strEAParameterTitles);
      ArrayFree(strEAParameterValues);
      delete objLog;
      
   }
   
   Print("***********************************************");
   Print("*******************  EA END *******************");
   Print("***********************************************");
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   /*
   Check for the first tick of the candle where we see if we are
   going to trade.   Otherwise do hidden stoploss evaluation and 
   look to close trades on a Friday.
   */
   
   if(Volume[0]<=1)
   {
      //-- First tick where we look for new trades
      if(NoLiveTradesExist())
      {
         tryToTrade();
      }
   }
   else
   {
      //-- Remaining ticks where we try to manage hidden stoplosses or
      //-- look for a friday close.
      
      checkForHiddenStoplossBreach();
      
      checkForFridayClose();
   }
   
   return;
   
  }
//+------------------------------------------------------------------+
//| FUNCTIONS - TRADING ALGORITM                                     |
//+------------------------------------------------------------------+
void tryToTrade()
{
   
   //-- Do not try to trade if it is disabled.
   if(IsTradeAllowed()==false)   return;
   
   //-- Firstly, we do not trade unless we are within the trading hours
   //-- specified by I_TradingStartHour and I_TradingEndHour.   Do not
   //-- trade in I_TradingEndHour on a Friday.
   if(I_TradingEndHour>I_TradingStartHour)
   {
      int intHour = TimeHour(TimeCurrent());
      bool boolMonThurClosed = intHour < I_TradingStartHour ||
            intHour > I_TradingEndHour;
      bool boolFridayClosed = (DayOfWeek()==5 && intHour >= I_TradingEndHour);
      
      if(boolMonThurClosed || boolFridayClosed) return;
         
   }
   else
   {
      int intHour = TimeHour(TimeCurrent());
      bool boolMonThurClosed = intHour < I_TradingStartHour &&
         intHour > I_TradingEndHour;
      bool boolFridayClosed = (DayOfWeek()==5 && intHour >= I_TradingEndHour);
      
      if(boolMonThurClosed || boolFridayClosed) return;
   }

   //-- Do not trade during christmas week and near new years day.   Closing hours of
   //-- brokerages can be very different, which means backtesting during this period
   //-- is prone to error.
   if(TimeMonth(TimeCurrent())==12 && TimeDay(TimeCurrent()) >= 20)  return;
   if(TimeMonth(TimeCurrent())==1 && TimeDay(TimeCurrent()) <= 7) return;
   
   //-- Market Data is rubbish during the brexit referendum, so assume no trading around
   //-- such large political events.
   if(TimeYear(TimeCurrent())==2016 && TimeMonth(TimeCurrent())==6 && 
      TimeDay(TimeCurrent()) >= 18 && TimeDay(TimeCurrent()) <=28)   return;
   
   //-- Look for the candlestick signal to buy/sell.   Update intOP_BUY... with
   //-- OP_BUY or OP_SELL, although we will actually use LIMIT/STOP orders later.
   int intOP_BUY_OR_SELL_SIGNAL=-1;
   if(!lookForCandlestickSignal(intOP_BUY_OR_SELL_SIGNAL))  return;
   
   //-- Ensure ATR is below mid of the previous days high/low ATR.
   if(!checkATRIsBelowMid())   return;
   
   double dblStopOrLimitLevel, dblStoploss, dblTakeprofit, dblLots;
   int intSlippage;
   
   //-- Calculate where the stoploss etc go and the lot size.
   if(!getTradeCharacteristics(intOP_BUY_OR_SELL_SIGNAL, dblStopOrLimitLevel, dblStoploss, 
                              dblTakeprofit, dblLots, intSlippage))   return;
   
   //-- Now attempt to add the trade.
   addLimitOrStopOrder(intOP_BUY_OR_SELL_SIGNAL, dblStopOrLimitLevel, dblStoploss, 
                              dblTakeprofit, dblLots, intSlippage);
   
   return;
   
}

bool getTradeCharacteristics(int intOP_BUY_OR_SELL_SIGNAL, double &dblStopOrLimitLevel, double &dblStoploss, 
                           double &dblTakeprofit, double &dblLots, int &intSlippage)
{
   
   if(intOP_BUY_OR_SELL_SIGNAL==OP_BUY)
   {
      double dblBottom = MathMin(iLow(Symbol(),0,1),iLow(Symbol(),0,2));
      
      //-- Stop or Limit level is dependent upon the reversion and difference between
      //-- close and low/high for buy/sell
      dblStopOrLimitLevel = iClose(Symbol(),0,1) 
                           - I_ReversionPercent*(iClose(Symbol(),0,1)-dblBottom)/100;
      
      //-- Depending on the model, calculate the stoploss
      dblStoploss=0;
      if(I_StoplossMethod==LowOrHighOfLast2Candles)
      {
         dblStoploss = dblBottom - I_TypicalSpread;
      }
      else
      {
         dblStoploss = dblStopOrLimitLevel - 
              (I_StoplossATRMultiplier*iATR(Symbol(),0,I_ATRPeriod,1)) - I_TypicalSpread;
      }
      
      double dblSL = dblStopOrLimitLevel-dblStoploss;
      
      //-- Take profit is size of stoploss multiplied by risk/reward plus an adjustment
      //-- for the spread.
      dblTakeprofit = dblStopOrLimitLevel + (Ask-Bid) + (dblSL*I_RiskRewardRatio);
      
      //-- Normalize key figures
      dblStopOrLimitLevel = NormalizeDouble(dblStopOrLimitLevel,Digits);
      dblStoploss = NormalizeDouble(dblStoploss,Digits);
      dblTakeprofit = NormalizeDouble(dblTakeprofit,Digits);
      
      //-- Calculate the Lot Size
      dblLots = calculateLotSize(dblStopOrLimitLevel-dblStoploss);
      if(dblLots <= 0)  return false;
      
      //-- Use 10% of ATR as slippage, rounded to nearest pointsize
      double dblS = 0.1*iATR(Symbol(),0,I_ATRPeriod,1);
      intSlippage = (int)MathFloor(dblS/MarketInfo(Symbol(),MODE_POINT));
      
                     
   }
   else if(intOP_BUY_OR_SELL_SIGNAL==OP_SELL)
   {
      double dblTop = MathMax(iHigh(Symbol(),0,1),iHigh(Symbol(),0,2));

      //-- Stop or Limit level is dependent upon the reversion and difference between
      //-- close and low/high for buy/sell
      dblStopOrLimitLevel = iClose(Symbol(),0,1) 
                           + I_ReversionPercent*(dblTop - iClose(Symbol(),0,1))/100;
                           
      //-- Depending on the model, calculate the stoploss
      dblStoploss=0;
      if(I_StoplossMethod==LowOrHighOfLast2Candles)
      {
         dblStoploss = dblTop + I_TypicalSpread;
      }
      else
      {
         dblStoploss = dblStopOrLimitLevel + 
              (I_StoplossATRMultiplier*iATR(Symbol(),0,I_ATRPeriod,1)) + I_TypicalSpread;
      }
      
      double dblSL = dblStoploss - dblStopOrLimitLevel;
                           
      //-- Take profit is size of stoploss multiplied by risk/reward plus an adjustment
      //-- for the spread.
      dblTakeprofit = dblStopOrLimitLevel - (Ask-Bid) - (dblSL*I_RiskRewardRatio);

      //-- Normalize key figures
      dblStopOrLimitLevel = NormalizeDouble(dblStopOrLimitLevel,Digits);
      dblStoploss = NormalizeDouble(dblStoploss,Digits);
      dblTakeprofit = NormalizeDouble(dblTakeprofit,Digits);
      
      //-- Calculate the Lot Size
      dblLots = calculateLotSize(dblStoploss - dblStopOrLimitLevel);
      if(dblLots <= 0)  return false;
      
      //-- Use 10% of ATR as slippage, rounded to nearest pointsize
      double dblS = 0.1*iATR(Symbol(),0,I_ATRPeriod,1);
      intSlippage = (int)MathFloor(dblS/MarketInfo(Symbol(),MODE_POINT));
      
   }
   else
   {
      //-- Coding problem, break the EA.
      reportError("Error with intOP_BUY_OR_SELL_SIGNAL");
      int i, j=1, k=0;
      i=j/k;
      return false;
   }
   
   return true;
}

bool checkATRIsBelowMid()
{
   /*
   We are looking to trade when ATR has increased and when the ATR is below the
   mid line between yesterdays maximum and minumum ATR.
   */
   
   int intPeak = getATRPeakOrTrough(1,true);
   if(intPeak < 1)  return false;
   
   int intTrough = getATRPeakOrTrough(intPeak,false);
   if(intTrough < 1 || intTrough<intPeak) return false;
   
   double dblPeakATR = iATR(Symbol(),0,I_ATRPeriod,intPeak);
   double dblTroughATR = iATR(Symbol(),0,I_ATRPeriod,intTrough);
   double dblMidLevel = 0.5*(dblPeakATR+dblTroughATR);
   
   //-- Test ATR to ensure below mid level
   double dblATR = iATR(Symbol(),0,I_ATRPeriod,1);
   return dblATR<=dblMidLevel;
}

int getATRPeakOrTrough(int intStartCandle=1, bool boolFindPeak=true)
{
   /*
   Scan back 24 hours from intStartCandle looking for a candle that
   is a peak or trough.   Return -1 if it could not be found
   */
   
   int intNoScan = (int)MathFloor(24*60*60/PeriodSeconds());
   
   for(int i=intStartCandle;i<intStartCandle+intNoScan;i++)
   {
      //--If we are after a peak we want the atr to go down, reverse
      //-- for a trough
      double dblATR_tm1 = iATR(Symbol(),0,I_ATRPeriod,i);
      double dblATR_tm2 = iATR(Symbol(),0,I_ATRPeriod,i+1);
      
      if(boolFindPeak && dblATR_tm1 >= dblATR_tm2)
      {
         //-- Now check to see if we are a peak
         if(isATRPeakOrTrough(i,true)) return i;
      }
      else if(!boolFindPeak && dblATR_tm1 <= dblATR_tm2)
      {
         //-- Now check to see if we are a trough.
         if(isATRPeakOrTrough(i,false)) return i;
      }
   
   }
   
   return -1;
   
}

bool isATRPeakOrTrough(int intCandle=1, bool boolFindPeak=true)
{
   /*
   Scan through 3 hours of candles either side of intCandle to ensure
   intCandle it the highest/lowest atr based upon boolFindPeak
   */
   
   int intNoSideCandles = (int)MathFloor(3*60*60/PeriodSeconds());
   int intStart = intCandle - intNoSideCandles;
   
   //-- If at start of chart, assume not peak or trough (not enough data)
   if(intStart<=0)   return false;
   
   //-- Get ATR of candle intCandle
   double dblATRKey = iATR(Symbol(),0,I_ATRPeriod,intCandle);
   
   for(int i=intStart;i<=intCandle+intNoSideCandles;i++)
   {
      if(i!=intCandle)
      {
         if(boolFindPeak && iATR(Symbol(),0,I_ATRPeriod,i) > dblATRKey)
         {
            return false;
         }
         else if(!boolFindPeak && iATR(Symbol(),0,I_ATRPeriod,i) < dblATRKey)
         {
            return false;
         }
      }
   }
   
   return true;
 
}
bool lookForCandlestickSignal(int &intOP_BUY_OR_SELL_SIGNAL)
{
   /*
   Look for a breakout of the ATR as follows:
      i) Candle is fat body, ie not doji
      ii) Candle closes above mid+0.5*atr for buy or below mod-0.5*atr for sell
      iii) Candlw opens below/above this range.
      iv) Previous candle is below/above +/-0.5*atr
      v) ATR has increased from tm3 to tm2
   */
   
   double dblATR_tm2 = iATR(Symbol(),0,I_ATRPeriod,2);
   double dblMID_tm2 = 0.5*(iHigh(Symbol(),0,2)+iLow(Symbol(),0,2));
   double dblATR_tm3 = iATR(Symbol(),0,I_ATRPeriod,3);
   double dblMID_tm3 = 0.5*(iHigh(Symbol(),0,3)+iLow(Symbol(),0,3));
   
   //-- Check ATR increase first, it is easy.
   if(dblATR_tm2 <= dblATR_tm3)  return false;
   
   //-- If candle doesn't have a fat body, exit
   if(!candleHasFatBody(1))   return false;
   
   if(iClose(Symbol(),0,1) > (dblMID_tm2+0.5*dblATR_tm2))
   {
      //-- Close above mid+0.5*atr
      if(iOpen(Symbol(),0,1) < (dblMID_tm2+0.5*dblATR_tm2))
      {
         //-- Open below mid+0.5atr
         if(MathMax(iOpen(Symbol(),0,2),iClose(Symbol(),0,2)) <= (dblMID_tm3+0.5*dblATR_tm3))
         {
            //-- Prev candle is below atr breakout

            intOP_BUY_OR_SELL_SIGNAL = OP_BUY;
            return true;
            
          }
      }
   }
   else if(iClose(Symbol(),0,1) < (dblMID_tm2-0.5*dblATR_tm2))
   {
      //-- Close below mid0.5*atr
      if(iOpen(Symbol(),0,1) > (dblMID_tm2-0.5*dblATR_tm2))
      {
         //-- Open above mid-0.5atr
         if(MathMin(iOpen(Symbol(),0,2),iClose(Symbol(),0,2)) >= (dblMID_tm3-0.5*dblATR_tm3))
         {
            //-- Prev candle is above atr breakout
            
            intOP_BUY_OR_SELL_SIGNAL = OP_SELL;
            return true;
            
         }
      }
   }
   
   return false;
}

bool candleHasFatBody(int intCandle=1)
{
   //-- Look for a fat body candle
   
   double dblBody, dblUpperWick, dblLowerWick;
         
   getCandleCharacteristics(dblBody, dblUpperWick, dblLowerWick, intCandle);
   
   if(dblBody > dblUpperWick && dblBody > dblLowerWick)  return true;
   
   return false;
}

void getCandleCharacteristics(double &dblBody, double &dblUpperWick, double &dblLowerWick, int intCandle=1)
{
   //-- Get the upper wick, body and lower wick of candle intCandle
   
   dblBody = MathAbs(iClose(Symbol(),0,intCandle)
            -iOpen(Symbol(),0,intCandle));
            
   dblUpperWick = iHigh(Symbol(),0,intCandle) 
                  - MathMax(iClose(Symbol(),0,intCandle),iOpen(Symbol(),0,intCandle));
                  
   dblLowerWick = MathMin(iClose(Symbol(),0,intCandle),iOpen(Symbol(),0,intCandle))
                  - iLow(Symbol(),0,intCandle);
}
//+------------------------------------------------------------------+
//| FUNCTIONS - HIDDEN STOPLOSS                                      |
//+------------------------------------------------------------------+
void checkForHiddenStoplossBreach()
{
   /*
   This function should be called on most ticks, other than the first one.
   It scans through open trades to see if the hidden stoploss has been breached.
   The hidden stoploss should be the real stoploss offset by I_HiddenStoplossOffset
   */
   
   //-- Exit if hidden stoploss offset is <=0 to save computational time.
   if(I_HiddenStoplossOffset<=0) return;
   
   int intCount=OrdersTotal();
   if(intCount<1) return;
   
   for(int i=0;i<intCount;i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==I_MagicNumber)
         {
            if(OrderType()==OP_BUY)
            {
               //-- Check to see if the Bid is below the hidden stoploss
               RefreshRates();
               if(Bid < (OrderStopLoss()+I_HiddenStoplossOffset))
               {
               
                  closeSelectedOrder();
                  
               }
            }
            else if(OrderType()==OP_SELL)
            {
               //-- Check to see if the Ask is above the hidden stoploss
               RefreshRates();
               if(Ask > (OrderStopLoss()-I_HiddenStoplossOffset))
               {
               
                  closeSelectedOrder();
                  
               }
            }
         }
      }
   }
   
   return;
   
}

void checkForFridayClose()
{
   /*
   This function checks to see if the weekday is friday and the hour is the I_TradingEndHour
   If it is then it closes orders associated with this trade.
   
   Weekends are dangerous.
   */
   
   if(DayOfWeek()!=5)   return;
   
   if(TimeHour(TimeCurrent())!=I_TradingEndHour) return;
   
   int intCount=OrdersTotal();
   if(intCount<1) return;
   
   for(int i=0;i<intCount;i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         //-- This function won't close orders with a different
         //-- magic number and symbol.
         
         closeSelectedOrder();     
         
      }
   }
}
//+------------------------------------------------------------------+
//| FUNCTIONS - ASSOCIATED WITH TRADE STATE (OPEN/CLOSE/NO ORDERS)   |
//+------------------------------------------------------------------+
bool NoLiveTradesExist()
{
   /*
   Function returns true if there are no trades associated with this symbol/magic number,
   or false if it finds a trade.   Limit/Stop orders count.
   */
   
   bool boolRet=true;
   
   int intCount=OrdersTotal();
   
   for(int i=0;i<intCount;i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==I_MagicNumber)
         {
            boolRet = false;
            break;
         }
      }
   }
   
   return boolRet;
}

bool closeSelectedOrder()
{
   //-- ONLY CALL THIS ONCE A LIVE TRADE HAS BEEN SELECTED AS IT USES THAT TRADES
   //-- CHARACTERISTICS.
   
   if(OrderSymbol()==Symbol() && OrderMagicNumber()==I_MagicNumber)
   {
      //-- Try to close the order 3 times using a slippage of 5
      for(int i=0;i<3;i++)
      {
         if(IsTradeAllowed())
         {
            RefreshRates();
            
            double dblSpot;
            int intColour;
            if(OrderType()==OP_BUY || OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP)
            {
               dblSpot = Bid;
               intColour = Green;
            }
            else
            {
               dblSpot = Ask;
               intColour = Red;
            }
            
            //-- This should also try to close stop/limit orders, but hopefully the spot
            //-- is less important for these (freeze level could interfere).
            
            if(OrderClose(OrderTicket(),OrderLots(),dblSpot,5,intColour))   return true;
         }
         else
         {
            reportError("Trading not allowed when closing trade: "+IntegerToString(OrderTicket()));
         }
      }
      
      Print("***********************************************");
      Print("*** "+IntegerToString(OrderTicket()));
      Print("*** Could not add delete order id:*************");
      Print("***********************************************");
      
   }
   
   return false;
   
}

void addLimitOrStopOrder(int intOP_BUY_OR_SELL_SIGNAL, double dblStopOrLimitLevel, double dblStoploss, 
                           double dblTakeprofit, double dblLots, int intSlippage)
{
   
   /*
   Try to add a limit order, if this fails it could be the wrong side of the level, so try stop order.
   Repeat this up to 3 times when trying to add a trade
   */
   
   //-- Define colour of the trade
   int intColour = (intOP_BUY_OR_SELL_SIGNAL==OP_BUY) ? Green : Red;
   
   //-- Limit Expiry of limit/stop order
   datetime dtExpiry = TimeCurrent() + (I_LimitStopOrderExpiryMins*60);
   
   //-- If we are using a hidden stoploss, then adjust the real stoploss here
   double dblSL = dblStoploss;
   if(I_HiddenStoplossOffset>0)
   {
      //-- Round hidden stoploss off to nearest ticksize.
      //-- WARNING THERE MAY BE A SMALL ERROR IN THE HIDDEN STOPLOSS DUE TO THIS
      //-- BUT IT SHOULD BE SMALLER THAN 1 TICK.
      
      double dblTickSize = MarketInfo(Symbol(),MODE_TICKSIZE);
      double dblAdjust = MathFloor(I_HiddenStoplossOffset/dblTickSize)*dblTickSize;
      
      //--Adjust real stoploss for hidden stoploss.
      dblSL = intOP_BUY_OR_SELL_SIGNAL==OP_BUY ? 
               dblStoploss-dblAdjust : 
               dblStoploss+dblAdjust;
   }
   
   //-- Try to add a stop or limit order up to 3 times.
   for(int i=0;i<3;i++)
   {
      
      //-- Attempt to add a limit order and exit if successful
      int intType = (intOP_BUY_OR_SELL_SIGNAL==OP_BUY) ? OP_BUYLIMIT : OP_SELLLIMIT;
      
      int intRet = OrderSend(Symbol(), intType,dblLots,dblStopOrLimitLevel,intSlippage,
                        dblSL,dblTakeprofit,NULL,I_MagicNumber,dtExpiry,intColour);
      
      if(intRet>=0)  break;
   
      //-- If cannot add limit order, try to add stop order and then exit if 
      //-- successful.
      intType = (intOP_BUY_OR_SELL_SIGNAL==OP_BUY) ? OP_BUYSTOP : OP_SELLSTOP;
      
      intRet = OrderSend(Symbol(), intType,dblLots,dblStopOrLimitLevel,intSlippage,
                        dblSL,dblTakeprofit,NULL,I_MagicNumber,dtExpiry,intColour);
      
      if(intRet>=0)  break;
      
      Print("***********************************************");
      Print("*** "+IntegerToString(intOP_BUY_OR_SELL_SIGNAL)+", "
                  +DoubleToString(dblLots,4)+", "
                  +DoubleToString(dblStopOrLimitLevel,6)+", "
                  +DoubleToString(dblSL, 6)+", "+DoubleToString(dblTakeprofit,6)+", "
                  +IntegerToString(intSlippage));
      Print("*** Buy/Sell, Lots, Level, SL, TP, Slippage");
      Print("*** Could not add Stop/Limit order*************");
      Print("***********************************************");
      
   }
   
   return;

}

double calculateLotSize(double dblSLSize)
{
   //-- Get market info
   double dblTickValue = MarketInfo(Symbol(),MODE_TICKVALUE);
   double dblTickSize = MarketInfo(Symbol(),MODE_TICKSIZE);
   double dblMinLot = MarketInfo(Symbol(), MODE_MINLOT);
   double dblMaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double dblLotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   
   //-- Calculate the rough number of lots for the trade
   double dblLots = (I_AtRisk * dblTickSize)/(dblSLSize*dblTickValue);
   
   //-- Cap the lot
   dblLots = MathMin(dblLots, I_MaxLotSize);
   
   //-- Now ensure lots is in correct market data range
   double dblDiff = dblLots-dblMinLot;
   if(dblDiff<0)  return 0;
   dblLots = dblMinLot + MathFloor(dblDiff/dblLotStep)*dblLotStep;
   if(dblLots > dblMaxLot) dblLots = dblMaxLot;
   
   return dblLots;
}
