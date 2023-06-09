//+------------------------------------------------------------------+
//|                                             SPB core library.mqh |
//|                                                    Steve Hopwood |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property strict

/*
The dashboard code is provided by Thomas. Thanks Thomas; you are a star. 
This EA is Thomas' dashboard with automated 
trading added by me. 

*/

//#include <WinUser32.mqh>
#include <stdlib.mqh>

// TDesk code
#include <TDesk.mqh>

//Code to minimise charts provided by Rene. Many thanks again, Rene.
#import "user32.dll"
int GetParent(int hWnd);
bool ShowWindow(int hWnd, int nCmdShow);
#import

#define  AllTrades 10 //Tells closeAllTrades() to close/delete everything belonging to the passed symbol
#define  AllSymbols "All symbols"//Tells closeAllTrades() to close/delete everything on the platform, regardless of pair
#define  million 1000000;
//Define the FifoBuy/SellTicket fields for offsetting
#define  TradeTicket 1

#define  SW_FORCEMINIMIZE   11
#define  SW_MAXIMIZE         3

#define  up "Up"
#define  down "Down"
#define  mixed "Mixed"
#define  NL    "\n"


//SuperSlope colours
#define  red "Red"
#define  blue "Blue"
//Changed by tomele
#define white "White"
//RetraceTradingTimeFrame cross status
#define nocross "No cross"
#define longcross "Long cross"
#define shortcross "Short cross"

//Peaky status
#define peakylongtradable ": Long"
#define peakyshorttradable ": Short"
#define peakylonguntradable ": Long untradable"
#define peakyshortuntradable ": Short untradable"

//Trading status
#define  tradablelong "Tradable long"
#define  tradableshort "Tradable short"
#define  untradable "Not tradable"

//Spread array fields
enum SpreadFields
{
   currentspread = 0,
   averagespread = 1,
   spreadtotalsofar = 2,
   biggestspread = 3,
   tickscounted = 4,
   previousask=5,
   longtermtickscounted=6,
   longtermspread=7,
   longtermspreadtotalsofar=8
};

enum TradeFields
{
   pipst = 0,
   casht = 1,
   swapt = 2
};

enum ArrowPlaces
{
   OrderOpenPrice = 0,
   CandleHighLow = 1
};

enum LineColoring
{
   LongShort = 0,
   ProfitableUnprofitable = 1
};

enum DaysOfWeek
{
   Sunday = 0,
   Monday = 1,
   Tuesday = 2,
   Wednesday = 3,
   Thursday = 4,
   Friday = 5,
   Saturday = 6
};

//Error reporting
#define  slm " stop loss modification failed with error "
#define  tpm " take profit modification failed with error "
#define  ocm " order close failed with error "
#define  odm " order delete failed with error "
#define  pcm " part close failed with error "
#define  spm " shirt-protection close failed with error "
#define  slim " stop loss insertion failed with error "
#define  tpim " take profit insertion failed with error "
#define  tpsl " take profit or stop loss insertion failed with error "
#define  oop " pending order price modification failed with error "


//Scale back in sltp correction
string         stopLossGvName= " SPB hidden stop loss";
string         takeProfitGvName= " SPB hidden take profit";


//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Tommaso for coding the function.
double         factor;//For pips/points stuff.

//Matt's O-R stuff
int            o_R_Setting_max_retries=10;
double         o_R_Setting_sleep_time=4.0; /* seconds */
double         o_R_Setting_sleep_max=15.0; /* seconds */
int            RetryCount=10;//Will make this number of attempts to get around the trade context busy error.



//Variables for building a picture of the open position
int            marketTradesTotal=0;//Total of open market trades
int            pendingTradesTotal=0;//Total of pending orders
//Market Buy trades
bool           buyOpen=false;
int            marketBuysCount=0;
double         latestBuyPrice=0, earliestBuyPrice=0, highestBuyPrice=0, lowestBuyPrice=0;
int            buyTicketNo=-1, highestbuyTicketNo=-1, lowestbuyTicketNo=-1, latestbuyTicketNo=-1, earliestbuyTicketNo=-1;
datetime       latestBuytradeTime=0;
datetime       earliestBuytradeTime=0;

//Market Sell trades
bool           sellOpen=false;
int            marketSellsCount=0;
double         latestSellPrice=0, earliestSellPrice=0, highestSellPrice=0, lowestSellPrice=0;
int            SellTicketNo=-1, highestSellTicketNo=-1, lowestSellTicketNo=-1, latestSellTicketNo=-1, earliestSellTicketNo=-1;;
datetime       latestSelltradeTime=0;
datetime       earliestSelltradeTime=0;

//BuyStop trades
bool           buyStopOpen=false;
int            buyStopsCount=0;
double         latestBuyStopPrice=0, earliestBuyStopPrice=0, highestBuyStopPrice=0, lowestBuyStopPrice=0;
int            buyStopTicketNo=-1, highestbuyStopTicketNo=-1, lowestbuyStopTicketNo=-1, latestbuyStopTicketNo=-1, earliestbuyStopTicketNo=-1;;
datetime       latestBuyStoptradeTime=0;
datetime       earliestBuyStoptradeTime=0;

//BuyLimit trades
bool           buyLimitOpen=false;
int            buyLimitsCount=0;
double         latestBuyLimitPrice=0, earliestBuyLimitPrice=0, highestBuyLimitPrice=0, lowestBuyLimitPrice=0;
int            buyLimitTicketNo=-1, highestBuyLimitTicketNo=-1, lowestBuyLimitTicketNo=-1, latestBuyLimitTicketNo=-1, earliestBuyLimitTicketNo=-1;;
datetime       latestBuyLimittradeTime=0;
datetime       earliestBuyLimittradeTime=0;

/////SellStop trades
bool           sellStopOpen=false;
int            sellStopsCount=0;
double         latestSellStopPrice=0, earliestSellStopPrice=0, highestSellStopPrice=0, lowestSellStopPrice=0;
int            sellStopTicketNo=-1, highestSellStopTicketNo=-1, lowestSellStopTicketNo=-1, latestSellStopTicketNo=-1, earliestSellStopTicketNo=-1;;
datetime       latestSellStoptradeTime=0;
datetime       earliestSellStoptradeTime=0;

//SellLimit trades
bool           sellLimitOpen=false;
int            sellLimitsCount=0;
double         latestSellLimitPrice=0, earliestSellLimitPrice=0, highestSellLimitPrice=0, lowestSellLimitPrice=0;
int            sellLimitTicketNo=-1, highestSellLimitTicketNo=-1, lowestSellLimitTicketNo=-1, latestSellLimitTicketNo=-1, earliestSellLimitTicketNo=-1;;
datetime       latestSellLimittradeTime=0;
datetime       earliestSellLimittradeTime=0;

//Not related to specific order types
int            ticketNo=-1,openTrades,oldOpenTrades,closedTrades;
//Variables for storing market trade ticket numbers
datetime       latesttradeTime=0, earliesttradeTime=0;//More specific times are in each individual section
int            latestTradeTicketNo=-1, earliestTradeTicketNo=-1;
//We need to know the UPL values
double         pipsUpl[];//For keeping track of the pips pipsUpl of multi-trade positions. Aplies to the individual pair.
double         cashUpl[];//For keeping track of the cash pipsUpl of multi-trade positions. Aplies to the individual pair.
double         buyCashUpl[];//For keeping track of the cash pipsUpl of multi-trade positions. Aplies to the individual pair.
double         sellCashUpl[];//For keeping track of the cash pipsUpl of multi-trade positions. Aplies to the individual pair.
double         totalPipsUpl=0;//Whole position
double         totalCashUpl=0;//Whole position
double         totalClosedPipsPl=0;//Whole position
double         totalClosedCashPl=0;//Whole position
int            totalOpenTrades=0;//Whole position
int            totalClosedTrades=0;//Whole position


bool secureSetTimer(int seconds) 
{

   //This is another brilliant idea by tomele. Many thanks Thomas. Here is the explanation:
/*
I am testing something René has developed on Eaymon's VPS as well as on Google's VPS. I ran into a problem with EventSetTimer(). 
This problem was reported by other users before and apparently occurs only on VPS's, not on desktop machines. The problem is that 
calls to EventSetTimer() eventually fail with different error codes returned. The EA stays on the chart with a smiley (it 
is not removed), but no timer events are sent to OnTimer() and the EA doesn't act anymore. 

The problem might be caused by the VPS running out of handles. A limited number of these handles is shared as a pool 
between all virtual machines running on the same host machine. The problem occurs randomly when all handles are in use 
and can be cured by repeatedly trying to set a timer until you get no error code.

I have implemented a function secureSetTimer() that does this. If you replace EventSetTimer() calls with secureSetTimer() 
calls in the EA code, this VPS problem will not affect you anymore:

*/   
   
   int error=-1;
   int counter=1;
   
   do
   {
      EventKillTimer();
      ResetLastError();
      EventSetTimer(seconds);
      error=GetLastError();
      Print("secureSetTimer, attempt=",counter,", error=",error);
      if(error!=0) Sleep(1000);
      counter++;
   }
   while(error!=0 && !IsStopped() && counter<100);
   
   return(error==0);
}



void extractPairs()
{
   
   int cc = 0;
   
   //Read the pairs into a temporary array so that 
   //pairs not offered by the broker are removed.
   string tempTradePair[];
   StringSplit(PairsToTrade,',',tempTradePair);
   noOfPairs = ArraySize(tempTradePair);
   int tempIndex = 0;
   
   //Save the pairs offered by the broker into the tradePair array.
   for (cc = 0; cc < noOfPairs; cc ++)
   {
      string symbol = tempTradePair[cc];
      symbol = StringTrimLeft(symbol);
      symbol = StringTrimRight(symbol);
      symbol = StringConcatenate(PairPrefix, symbol, PairSuffix);
      
      getBasics(symbol);//Returns zero for the Bid if the symbol is not offered.
      if (!closeEnough(bid, 0) )
      {
         tempIndex++;
         ArrayResize(tradePair, tempIndex);
         tradePair[tempIndex - 1] = symbol;
         
      }//if (!closeEnough(bid, 0) )
     
   }//for (cc = 0; cc < noOfPairs; cc ++)
   
   
   
   
   
   // Resize the arrays appropriately
   ArrayResize(ttfCandleTime, noOfPairs);
   ArrayResize(htfSsStatus, noOfPairs);
   ArrayResize(htfSsVal, noOfPairs);
   ArrayResize(mtfSsStatus, noOfPairs);
   ArrayResize(mtfSsVal, noOfPairs);
   ArrayResize(ltfSsStatus, noOfPairs);
   ArrayResize(ltfSsVal, noOfPairs);
   ArrayResize(buySignal, noOfPairs);
   ArrayResize(sellSignal, noOfPairs);
   ArrayResize(timeToStartTrading, noOfPairs);
   ArrayResize(oldHtfIndiReadBarTime, noOfPairs);
   ArrayResize(oldMtfIndiReadBarTime, noOfPairs);
   ArrayResize(oldLtfIndiReadBarTime, noOfPairs);
   ArrayResize(spreadArray, noOfPairs);
   ArrayInitialize(spreadArray, 0);
   ArrayResize(pipsUpl, noOfPairs);
   ArrayInitialize(pipsUpl, 0);
   ArrayResize(cashUpl, noOfPairs);
   ArrayInitialize(cashUpl, 0);
   ArrayResize(buyTradeTotals, noOfPairs);
   ArrayInitialize(buyTradeTotals, 0);
   ArrayResize(sellTradeTotals, noOfPairs);
   ArrayInitialize(sellTradeTotals, 0);
   ArrayResize(closedBuyTradeTotals, noOfPairs);
   ArrayInitialize(closedBuyTradeTotals, 0);
   ArrayResize(closedSellTradeTotals, noOfPairs);
   ArrayInitialize(closedSellTradeTotals, 0);
   ArrayResize(peakyStatus, noOfPairs);
   ArrayResize(buyCashUpl, noOfPairs);
   ArrayResize(sellCashUpl, noOfPairs);
   

   
   for (cc = 0; cc < noOfPairs; cc ++)
   {
      
      timeToStartTrading[cc] = 0;
      oldHtfIndiReadBarTime[cc] = 0;
      oldMtfIndiReadBarTime[cc] = 0;
      oldLtfIndiReadBarTime[cc] = 0;
      
      //Average spread
      spreadGvName=tradePair[cc] + " average spread";
      spreadArray[cc][averagespread]=GlobalVariableGet(spreadGvName);//If no gv, then the value will be left at zero.
      //Create a Global Variable with the current spread if this does not already exist
      if (closeEnough(spreadArray[cc][averagespread], 0))
      {
         getBasics(tradePair[cc]);//Includes the current spread
         spreadArray[cc][averagespread] = NormalizeDouble(spread, 2);
         GlobalVariableSet(spreadGvName, spread);
      }//if (closeEnough(spreadArray[cc][averagespread], 0))
      
      //Longterm spread
      spreadGvName=tradePair[cc] + " longterm spread";
      spreadArray[cc][longtermspread]=GlobalVariableGet(spreadGvName);//If no gv, then the value will be left at zero.
      //Create a Global Variable with the current spread if this does not already exist
      if (closeEnough(spreadArray[cc][longtermspread], 0))
      {
         getBasics(tradePair[cc]);//Includes the current spread
         spreadArray[cc][longtermspread] = NormalizeDouble(spread, 2);
         GlobalVariableSet(spreadGvName, spread);
      }//if (closeEnough(spreadArray[cc][averagespread], 0))
      
      spreadArray[cc][previousask] = 0;//Used to update the tick counter when there is a price change
      
   }//for (int cc; cc<noOfPairs; cc ++)

   //Swap pairs
   if (BuyOnlyPairs != "")
   {
      StringSplit(BuyOnlyPairs,',',buyOnlyPairs);
      noOfBuyOnlyPairs = ArraySize(buyOnlyPairs);
      //Remove accidental spaces
      for (cc = 0; cc < noOfBuyOnlyPairs; cc++)
      {
         StringTrimLeft(buyOnlyPairs[cc] );
         StringTrimRight(buyOnlyPairs[cc] );
         buyOnlyPairs[cc] = StringConcatenate(PairPrefix, buyOnlyPairs[cc], PairSuffix);
      }//for (cc = 0; cc <= noOfBuyOnlyPairs - 1; cc++)      
   }//if (BuyOnlyPairs != "")
   
   if (SellOnlyPairs != "")
   {
      StringSplit(SellOnlyPairs,',',sellOnlyPairs);
      noOfSellOnlyPairs = ArraySize(sellOnlyPairs);
      //Remove accidental spaces
      for (cc = 0; cc <= noOfSellOnlyPairs - 1; cc++)
      {
         StringTrimLeft(sellOnlyPairs[cc] );
         StringTrimRight(sellOnlyPairs[cc] );
         sellOnlyPairs[cc] = StringConcatenate(PairPrefix, sellOnlyPairs[cc], PairSuffix);
      }//for (cc = 0; cc <= noOfSellOnlyPairs - 1; cc++)      
   }//if (SellOnlyPairs != "")
   

   //'Bigger picture' pairs
   if (PairsToTradeLongOnly != "")
   {
      StringSplit(PairsToTradeLongOnly,',',longOnlyPairs);
      noOfLongOnlyPairs = ArraySize(longOnlyPairs);
      //Remove accidental spaces
      for (cc = 0; cc < noOfLongOnlyPairs; cc++)
      {
         StringTrimLeft(longOnlyPairs[cc] );
         StringTrimRight(longOnlyPairs[cc] );
         longOnlyPairs[cc] = StringConcatenate(PairPrefix, longOnlyPairs[cc], PairSuffix);
      }//for (cc = 0; cc <= longOnlyPairs - 1; cc++)      
   }//if (PairsToTradeLongOnly != "")
   
   if (PairsToTradeShortOnly != "")
   {
      StringSplit(SellOnlyPairs,',',shortOnlyPairs);
      noOfSellOnlyPairs = ArraySize(shortOnlyPairs);
      //Remove accidental spaces
      for (cc = 0; cc <= noOfSellOnlyPairs - 1; cc++)
      {
         StringTrimLeft(shortOnlyPairs[cc] );
         StringTrimRight(shortOnlyPairs[cc] );
         shortOnlyPairs[cc] = StringConcatenate(PairPrefix, shortOnlyPairs[cc], PairSuffix);
      }//for (cc = 0; cc <= noOfSellOnlyPairs - 1; cc++)      
   }//if (PairsToTradeShortOnly != "")
  
}//End void extractPairs()



//For OrderSelect() Craptrader documentation states:
//   The pool parameter is ignored if the order is selected by the ticket number. The ticket number is a unique order identifier. 
//   To find out from what list the order has been selected, its close time must be analyzed. If the order close time equals to 0, 
//   the order is open or pending and taken from the terminal open orders list.
//This function heals this and allows use of pool parameter when selecting orders by ticket number.
//Tomele provided this code. Thanks Thomas.
bool betterOrderSelect(int index,int select,int pool=-1)
{
   if (select==SELECT_BY_POS)
   {
      if (pool==-1) //No pool given, so take default
         pool=MODE_TRADES;
         
      return(OrderSelect(index,select,pool));
   }
   
   if (select==SELECT_BY_TICKET)
   {
      if (pool==-1) //No pool given, so submit as is
         return(OrderSelect(index,select));
         
      if (pool==MODE_TRADES) //Only return true for existing open trades
         if(OrderSelect(index,select))
            if(OrderCloseTime()==0)
               return(true);
               
      if (pool==MODE_HISTORY) //Only return true for existing closed trades
         if(OrderSelect(index,select))
            if(OrderCloseTime()>0)
               return(true);
   }
   
   return(false);
}//End bool betterOrderSelect(int index,int select,int pool=-1)



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   
}

string getTimeFramedisplay(int tf)
{

   if (tf == 0)
      tf = Period();
      
   
   if (tf == PERIOD_M1)
      return "M1";
      
   if (tf == PERIOD_M5)
      return "M5";
      
   if (tf == PERIOD_M15)
      return "M15";
      
   if (tf == PERIOD_M30)
      return "M30";
      
   if (tf == PERIOD_H1)
      return "H1";
      
   if (tf == PERIOD_H4)
      return "H4";
      
   if (tf == PERIOD_D1)
      return "D1";
      
   if (tf == PERIOD_W1)
      return "W1";
      
   if (tf == PERIOD_MN1)
      return "Monthly";
      
   return("No recognisable time frame selected");

}//string getTimeFramedisplay()

//+--------------------------------------------------------------------+
//| Paul Bachelor's (lifesys) text display module to replace Comment()|
//+--------------------------------------------------------------------+
void sm(string message)
{
   if (displayAsText) 
   {
      displayCount++;
      display(message);
   }
   else
      screenMessage = StringConcatenate(screenMessage,gap, message);
      
}//End void sm()

//   ************************* added for OBJ_LABEL
void removeAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   if (StringFind(ObjectName(i),"OAM-",0) > -1) 
      ObjectDelete(ObjectName(i));
}//End void removeAllObjects()
//   ************************* added for OBJ_LABEL

void display(string text)
{
   string lab_str = "OAM-" + IntegerToString(displayCount);  
   double ofset = 0;
   string textpart[5];
   uint w,h;
   
   for (int cc = 0; cc < 5; cc++)
   {
      textpart[cc] = StringSubstr(text,cc*63,64);
      if (StringLen(textpart[cc]) ==0) continue;
      lab_str = lab_str + IntegerToString(cc);
      
      if(ObjectFind(0,lab_str)<0)
      {
         ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0);
         ObjectSet(lab_str, OBJPROP_CORNER, 0);
         ObjectSet(lab_str, OBJPROP_XDISTANCE, displayX + ofset);
         ObjectSet(lab_str, OBJPROP_YDISTANCE, displayY+displayCount*(int)(ScaleY*fontSize*1.5));
         ObjectSet(lab_str, OBJPROP_BACK, false);
      }
      ObjectSetText(lab_str, textpart[cc], fontSize, fontName, colour);
      
      /////////////////////////////////////////////////
      //Calculate label size
      //Tomele supplied this code to eliminate the gaps in the text.
      //Thanks Thomas.
      TextSetFont(fontName,(int)(-fontSize*10),0,0);
      TextGetSize(textpart[cc],w,h);
      
      //Trim trailing space
      if (StringSubstr(textpart[cc],63,1)==" ")
         ofset+=(int)(w-fontSize*0.3);
      else
         ofset+=(int)(w-fontSize*0.7);
      /////////////////////////////////////////////////
         
   }//for (int cc = 0; cc < 5; cc++)
}


void getBasics(string symbol)
{
   //Sets up bid, ask, digits, factor for the passed pair
   bid = MarketInfo(symbol, MODE_BID);
   ask = MarketInfo(symbol, MODE_ASK);
   digits = (int)MarketInfo(symbol, MODE_DIGITS);
   factor = getPipFactor(symbol);
   spread = (ask - bid) * factor;
   longSwap = MarketInfo(symbol, MODE_SWAPLONG);
   shortSwap = MarketInfo(symbol, MODE_SWAPSHORT);
   
      
}//End void getBasics(string symbol)

//Thomas and Rene provided this pip factor function. Thanks guys.
//There is also a contribution by lifesys, who gave us the first ever
//incarnation of this.
double getPipFactor(string symbolName)
{
   static bool brokerDigitsKnown=false;
   static int  brokerDigits=0;
 
   // We want the additional pip digits of the broker (only once)
   if(!brokerDigitsKnown)
   {  
      // Try to get the broker digits for plain EURUSD
      brokerDigits=(int)SymbolInfoInteger("EURUSD",SYMBOL_DIGITS)-4;
      
      // If plain EURUSD was found, we take that
      if(brokerDigits>=0)
         brokerDigitsKnown=true;
         
      // If plain EURUSD not found, we take the most precise of all symbols containing EURUSD 
      else
      {
         brokerDigits=0;
         
         // Cycle through all symbols
         for(int i=0; i<SymbolsTotal(false); i++) 
         {
            string symName=SymbolName(i,false);
            if(StringFind(symName,"EURUSD")>=0)
               brokerDigits=MathMax(brokerDigits,(int)SymbolInfoInteger(symName,SYMBOL_DIGITS)-4);
         }
         
         brokerDigitsKnown=true;
      }
   }

   // Now we can calculate the pip factor for the symbol
   double symbolDigits = (int) SymbolInfoInteger(symbolName,SYMBOL_DIGITS);
   double symbolFactor=MathPow(10,symbolDigits-brokerDigits);
   
   return(symbolFactor);
}//End int getPipFactor(string symbolName)

void chartAutomation(string symbol, int index)
{
   long currChart = 0, prevChart = ChartFirst();
   int cc = 0, limit = ArraySize(tradePair) -1;
   
   //We want to close charts that are not tradable
   if (timerCount==0)//We do this only every ChartCloseTimerMultiple cycle
      if (peakyStatus[index] == untradable)
      {
         //We cannot close charts with open trades
         countTradesForDashboard(symbol);
         if (openTrades > 0)
            return;
            
         while (cc < limit)
         {
            currChart = ChartNext(prevChart); // Get the new chart ID by using the previous chart 
            if(currChart < 0) 
               return;// Have reached the end of the chart list 
         
            //We do not want to close the reserved chart
            if (ChartSymbol(currChart) == ReservedPair)
            {
               prevChart=currChart;// let's save the current chart ID for the ChartNext() 
               cc++;
               continue;
            }//if (ChartSymbol() == ReservedPair)
               
            if (ChartSymbol(currChart) == symbol)
               ChartClose(currChart);   
            
            prevChart=currChart;// let's save the current chart ID for the ChartNext() 
            cc++;
         }//while (cc < limit)
         
         return;   
      }//if (tradingStatus[cc] == untradable)
   
   //Now open a new chart if there is not one already open.
   //First check that the chart is a tradable chart
   if (peakyStatus[index] == untradable)
      //if (tradingStatus[index] != tradableshort)
         return;
         
   bool found = false;
   prevChart = ChartFirst();
   //Look for a chart already opened
   while (cc < limit)
   {
      currChart = ChartNext(prevChart); // Get the new chart ID by using the previous chart 
      if(currChart < 0) 
         break;// Have reached the end of the chart list 
   
      
      if (ChartSymbol(currChart) !=ReservedPair)
         if (ChartSymbol(currChart) == symbol)
         {
            found = true;
            break;
         }//if (ChartSymbol(currChart) == symbol)
            
      prevChart=currChart;// let's save the current chart ID for the ChartNext() 
      cc++;
   }//while (cc < limit)
   
   if (!found)
   {
      //Chart not found, so open one
      long newChartId = ChartOpen(symbol, ChartTimeFrame);
      //Alert(symbol, "  ", TemplateName);
      ChartApplyTemplate(newChartId, TemplateName);
      ChartRedraw(newChartId);
   }//if (!found)
   
   
}//End void chartAutomation(string symbol)


void drawTradeArrows(string symbol, long chartid)
{
   //Find the bar shift of open trades and draw an arrow to show where they opened.
   if (OrdersTotal() == 0)
      return;//Nothing to do
      
   //Delete eventual prior symbols
   ObjectsDeleteAll(chartid,"SCB");
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      
      //Ensure the trade is still open
      if (!betterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      
      //Ensure the EA 'owns' this trade
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      if (OrderSymbol() != symbol ) continue;
      
      getBasics(OrderSymbol());
      
      string name = "";
      string lname = "";
      double price = 0;
      bool result = false;
      
      datetime time1 = OrderOpenTime();
      double price1 = OrderOpenPrice();
      datetime time2 = TimeCurrent(); 
      double price2 = MarketInfo(symbol,MODE_BID);
      
      if (OrderType() == OP_BUY)
      {
         name  = "SCB BUY "+(string)symbol+" "+(string)time1;
         lname = "SCB LONG "+(string)symbol+" "+(string)time1;
         
         if (WhereToDrawArrows==CandleHighLow)
            price=iLow(symbol,ChartPeriod(chartid),iBarShift(symbol,ChartPeriod(chartid),time1));
         else
            price=OrderOpenPrice();
         
         if(drawTradeArrows)
         {
            result = ObjectCreate(chartid,name,OBJ_ARROW,0,time1,price);
            if (!result)
               Alert("Error: can't create arrow code #",GetLastError(), "  ", ErrorDescription(GetLastError()));
            else
            {
               ObjectSetInteger(chartid, name, OBJPROP_ANCHOR, ANCHOR_TOP);
               ObjectSetInteger(chartid, name, OBJPROP_ARROWCODE, 233);
               ObjectSetInteger(chartid, name, OBJPROP_COLOR, TradeLongColor);
               ObjectSetInteger(chartid, name, OBJPROP_BACK, False);
               ObjectSetInteger(chartid, name, OBJPROP_WIDTH, TradeArrowSize);
            }
         }
        
         if(DrawTradeLines)
         {
            price2 = MarketInfo(symbol,MODE_BID);
            result = ObjectCreate(chartid,lname,OBJ_TREND,0,time1,price1,time2,price2);
            if (!result)
               Alert("Error: can't create line code #",GetLastError(), "  ", ErrorDescription(GetLastError()));
            else
            {
               if(HowToColorLines==LongShort)
                  ObjectSetInteger(chartid, lname, OBJPROP_COLOR, TradeLineLongOrProfitableColor);
               else
               {
                  if(bid-OrderOpenPrice()>=0)
                     ObjectSetInteger(chartid, lname, OBJPROP_COLOR, TradeLineLongOrProfitableColor);
                  else
                     ObjectSetInteger(chartid, lname, OBJPROP_COLOR, TradeLineShortOrUnprofitableColor);
               }
               ObjectSetInteger(chartid, lname, OBJPROP_WIDTH, TradeLineSize);
               ObjectSetInteger(chartid, lname, OBJPROP_STYLE, TradeLineStyle);
               ObjectSetInteger(chartid, lname, OBJPROP_RAY_RIGHT, False);
               ObjectSetInteger(chartid, lname, OBJPROP_BACK, False);
            }
         }
      
      }//if (OrderType() == OP_BUY)

      if (OrderType() == OP_SELL)
      {
         name  = "SCB SELL "+(string)symbol+" "+(string)time1;
         lname = "SCB SHORT "+(string)symbol+" "+(string)time1;
         
         if (WhereToDrawArrows==CandleHighLow)
            price=iHigh(symbol,ChartPeriod(chartid),iBarShift(symbol,ChartPeriod(chartid),time1));
         else
            price=OrderOpenPrice();
         
         if(drawTradeArrows)
         {
            result = ObjectCreate(chartid,name,OBJ_ARROW_DOWN,0,time1,price);
            if (!result)
               Alert("Error: can't create arrow code #",GetLastError(), "  ", ErrorDescription(GetLastError())); 
            else
            {
               ObjectSetInteger(chartid, name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
               ObjectSetInteger(chartid, name, OBJPROP_ARROWCODE, 234);
               ObjectSetInteger(chartid, name, OBJPROP_COLOR, TradeShortColor);
               ObjectSetInteger(chartid, name, OBJPROP_BACK, False);
               ObjectSetInteger(chartid, name, OBJPROP_WIDTH, TradeArrowSize);
            }
         }
               
         if(DrawTradeLines)
         {
            result = ObjectCreate(chartid,lname,OBJ_TREND,0,time1,price1,time2,price2);
            if (!result)
               Alert("Error: can't create line code #",GetLastError(), "  ", ErrorDescription(GetLastError()));
            else
            {
               if(HowToColorLines==LongShort)
                  ObjectSetInteger(chartid, lname, OBJPROP_COLOR, TradeLineShortOrUnprofitableColor);
               else
               {
                  if(OrderOpenPrice()-ask>=0)
                     ObjectSetInteger(chartid, lname, OBJPROP_COLOR, TradeLineLongOrProfitableColor);
                  else
                     ObjectSetInteger(chartid, lname, OBJPROP_COLOR, TradeLineShortOrUnprofitableColor);
               }
               ObjectSetInteger(chartid, lname, OBJPROP_WIDTH, TradeLineSize);
               ObjectSetInteger(chartid, lname, OBJPROP_STYLE, TradeLineStyle);
               ObjectSetInteger(chartid, lname, OBJPROP_RAY_RIGHT, False);
               ObjectSetInteger(chartid, lname, OBJPROP_BACK, False);
            }
         }
        
      }//if (OrderType() == OP_BUY)

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   ChartRedraw(chartid);

}//End void drawTradeArrows(string symbol)

double getSuperSlope(string symbol, int tf, int maperiod, int atrperiod, int pShift )
{
   double dblTma, dblPrev;
   int shiftWithoutSunday = pShift;
   
   double atr = iATR( symbol, tf, atrperiod, shiftWithoutSunday + 10 ) / 10;
   double result = 0.0;
   if ( atr != 0 )
   {
      dblTma = iMA( symbol, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday );
      dblPrev = ( iMA( symbol, tf, maperiod, 0, MODE_LWMA, PRICE_CLOSE, shiftWithoutSunday + 1 ) * 231 + iClose( symbol, tf, shiftWithoutSunday ) * 20 ) / 251;

      result = ( dblTma - dblPrev ) / atr;
   }
   
   return ( result );
   
}//getSuperSlope(}

double getAtr(string symbol, int tf, int period, int shift)
{
   //Returns the value of atr
   
   return(iATR(symbol, tf, period, shift) );   

}//End double getAtr()

void getPeaky(string symbol, int pairIndex)
{

   //Find the highest high and lowest close bars
   int currentPeakHighBar = iHighest(symbol, PeakyTimeFrame, MODE_CLOSE, NoOfBarsOnChart, 1);
   int currentPeakLowBar = iLowest(symbol, PeakyTimeFrame, MODE_CLOSE, NoOfBarsOnChart, 1);
   //Read the prices
   double highest = iClose(symbol, PeakyTimeFrame, currentPeakHighBar);
   double lowest = iClose(symbol, PeakyTimeFrame, currentPeakLowBar);
   //Half way point
   double HalfWay = (highest + lowest) / 2;
   
   //Set the direction
   peakyStatus[pairIndex] = peakylongtradable;
   if (currentPeakHighBar < currentPeakLowBar)
      peakyStatus[pairIndex] = peakyshorttradable;

   //Cannot be beyond the half way price between highest and lowest
   //Long
   if (peakyStatus[pairIndex] == peakylongtradable)
      if (ask > HalfWay)
         peakyStatus[pairIndex] = peakylonguntradable;
         
   //Short
   if (peakyStatus[pairIndex] == peakyshorttradable)
      if (bid < HalfWay)
         peakyStatus[pairIndex] = peakyshortuntradable;
         
  
}//End void getPeaky(string symbol, int pairIndex)




void removeTakeProfits(string symbol)
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!betterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

      if (!closeEnough(OrderTakeProfit(), 0) )
         modifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), 0, 
                     OrderExpiration(), clrNONE, __FUNCTION__, tpm);
      
      
  
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

}//void removeTakeProfits()

void removeStopLosses(string symbol)
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!betterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

      if (!closeEnough(OrderStopLoss(), 0) )
         modifyOrder(OrderTicket(), OrderOpenPrice(), 0, OrderTakeProfit(), 
                     OrderExpiration(), clrNONE, __FUNCTION__, tpm);
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

}//void removeStopLosses()

void insertStopLoss(int ticket)
{
   //Inserts a stop loss if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from countOpenTrades() if stopLoss > 0 && OrderStopLoss() == 0.
   
   if (HideStopLossAndTakeProfit)
      return;
   
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (OrderStopLoss() > 0) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double stop = 0;
   
   if (OrderType() == OP_BUY)
   {
      stop = calculateStopLoss(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      stop = calculateStopLoss(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (closeEnough(stop, 0) ) return;
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      reportError(" insertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice() ) 
   {
      stop = 0;
      reportError(" insertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 

   
   if (!closeEnough(stop, OrderStopLoss())) 
   {
      bool result = modifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!closeEnough(stop, OrderStopLoss())) 

}//End void insertStopLoss(int ticket)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void insertTakeProfit(int ticket)
{
   //Inserts a TP if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from countOpenTrades() if takeProfit > 0 && OrderTakeProfit() == 0.
   
   if (HideStopLossAndTakeProfit)
      return;
   
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (!closeEnough(OrderTakeProfit(), 0) ) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double take = 0;
   
   if (OrderType() == OP_BUY)
   {
      take = calculateTakeProfit(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      take = calculateTakeProfit(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (closeEnough(take, 0) ) return;
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice()  && !closeEnough(take, 0) ) 
   {
      take = 0;
      reportError(" insertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      reportError(" insertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   
   if (!closeEnough(take, OrderTakeProfit()) ) 
   {
      bool result = modifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!closeEnough(take, OrderTakeProfit()) ) 

}//End void insertTakeProfit(int ticket)


double calculateStopLoss(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop = 0;

   RefreshRates();
   

   
   if (type == OP_BUY)
   {
      if (!closeEnough(stopLoss, 0) ) 
      {
         stop = price - (stopLoss / factor);
         //HiddenStopLoss = stop;
      }//if (!closeEnough(stopLoss, 0) ) 

      //if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop - (HiddenPips / factor), Digits);
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!closeEnough(stopLoss, 0) ) 
      {
         stop = price + (stopLoss / factor);
         //HiddenStopLoss = stop;         
      }//if (!closeEnough(stopLoss, 0) ) 
      
      //if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop + (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   //Store the sl
   GlobalVariableSet(stopLossGvName, stop);

   return(stop);
   
}//End double calculateStopLoss(int type)

double calculateTakeProfit(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double take = 0;

   RefreshRates();
   
   
   if (type == OP_BUY)
   {
      if (!closeEnough(takeProfit, 0) )
      {
         take = price + (takeProfit / factor);
         //HiddenTakeProfit = take;
      }//if (!closeEnough(takeProfit, 0) )

               
      //if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take + (HiddenPips / factor), Digits);

   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!closeEnough(takeProfit, 0) )
      {
         take = price - (takeProfit / factor);
         //HiddenTakeProfit = take;         
      }//if (!closeEnough(takeProfit, 0) )
      
      
      //if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take - (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   //Store the tp
   GlobalVariableSet(takeProfitGvName, take);
   return(take);
   
}//End double calculateTakeProfit(int type)

bool closeOrder(int ticket)
{   
   while(IsTradeContextBusy()) Sleep(100);
   bool orderselect=betterOrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if (!orderselect) return(false);

   bool result = OrderClose(ticket, OrderLots(), OrderClosePrice(), 1000, clrBlue);

   //Actions when trade send succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade send fails
   if (!result)
   {
      reportError(" closeOrder()", ocm);
      return(false);
   }//if (!result)
   
   return(false);
   
}//End bool closeOrder(ticket)

//+------------------------------------------------------------------+
//| normalizeLots(string symbol, double lots)                        |
//+------------------------------------------------------------------+
//function added by fxdaytrader
//Lot size must be adjusted to be a multiple of lotstep, which may not be a power of ten on some brokers
//see also the original function by WHRoeder, http://forum.mql4.com/45425#564188, fxdaytrader
double normalizeLots(string symbol,double lots)
{
   if(MathAbs(lots)==0.0) return(0.0); //just in case ... otherwise it may happen that after rounding 0.0 the result is >0 and we have got a problem, fxdaytrader
   double ls=MarketInfo(symbol,MODE_LOTSTEP);
   lots=MathMin(MarketInfo(symbol,MODE_MAXLOT),MathMax(MarketInfo(symbol,MODE_MINLOT),lots)); //check if lots >= min. lots && <= max. lots, fxdaytrader
   return(MathRound(lots/ls)*ls);
}
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
//TRADE MANAGEMENT MODULE


void reportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   
}//void reportError()

bool modifyOrder(int ticket, double price, double stop, double take, datetime expiry, color col, string function, string reason)
{
   //Multi-purpose order modify function
   
   bool result = OrderModify(ticket, price ,stop , take, expiry, col);

   //Actions when trade close succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade close fails
   if (!result)
      reportError(function, reason);

   //Got this far, so modify failed
   return(false);
   
}// End bool modifyOrder()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void breakEvenStopLoss(int ticket) // Move stop loss to breakeven
{

   //Security check
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
      
   double NewStop = 0;
   bool result = true;
   bool modify=false;
   double sl = OrderStopLoss();
   double target = OrderOpenPrice();
   
   
   if (OrderType()==OP_BUY)
   {
      //if (HiddenPips > 0) target-= (HiddenPips / factor);
      if (OrderStopLoss() >= target) return;
      if (bid >= OrderOpenPrice () + (breakEvenPips / factor) )          
      {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()+(breakEvenProfit / factor), digits);
         modify = true;   
      }//if (bid >= OrderOpenPrice () + (Point*breakEvenPips) && 
   }//if (OrderType()==OP_BUY)               			         
    
   if (OrderType()==OP_SELL)
   {
     //if (HiddenPips > 0) target+= (HiddenPips / factor);
     if (OrderStopLoss() <= target && OrderStopLoss() > 0) return;
     if (ask <= OrderOpenPrice() - (breakEvenPips / factor) ) 
     {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()-(breakEvenProfit / factor), digits);
         modify = true;   
     }//if (ask <= OrderOpenPrice() - (Point*breakEvenPips) && (OrderStopLoss()>OrderOpenPrice()|| OrderStopLoss()==0))     
   }//if (OrderType()==OP_SELL)

   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      if (NewStop == OrderStopLoss() ) return;
      while (IsTradeContextBusy() ) Sleep(100);
      result = modifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (!result)
         Sleep(10000);//10 seconds before trying again
         
      while (IsTradeContextBusy() ) Sleep(100);
      if (PartCloseEnabled && OrderComment() == TradeComment) bool success = partcloseOrder(OrderTicket() );
   }//if (modify)
   
} // End BreakevenStopLoss sub

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool partcloseOrder(int ticket)
{
   //Close PartClosePercent of the initial trade.
   //Return true if close succeeds, else false
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) return(true);//in case the trade closed
   
   bool Success = false;
   double CloseLots = normalizeLots(OrderSymbol(),OrderLots() * (PartClosePercent / 100));
   
   Success = OrderClose(ticket, CloseLots, OrderClosePrice(), 1000, Blue); //fxdaytrader, normalizeLots(...
   if (Success) TradeHasPartClosed = true;//Warns countOpenTrades() that the OrderTicket() is incorrect.
   if (!Success) 
   {
       //mod. fxdaytrader, orderclose-retry if failed with ordercloseprice(). Maybe very seldom, but it can happen, so it does not hurt to implement this:
       while(IsTradeContextBusy()) Sleep(100);
       RefreshRates();
       if (OrderType()==OP_BUY) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_BID), 5000, Blue);
       if (OrderType()==OP_SELL) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_ASK), 5000, Blue);
       //end mod.  
       //original:
       if (Success) TradeHasPartClosed = true;//Warns countOpenTrades() that the OrderTicket() is incorrect.
   
       if (!Success) 
       {
         reportError(" PartcloseOrder()", pcm);
         return (false);
       } 
   }//if (!Success) 
      
   //Got this far, so closure succeeded
   return (true);   

}//bool partcloseOrder(int ticket)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void jumpingStopLoss(int ticket)
{
  // Jump sl by pips and at intervals chosen by user .

   //Thomas substantially rewrote this function. Many thanks, Thomas.
   
  //Security check
  if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     return;

  //if (OrderProfit() < 0) return;//Nothing to do
  double sl = OrderStopLoss();
  
  //This next line fixes a bug spotted by biobier. Thanks Alex.
  double point = SymbolInfoDouble(OrderSymbol(),SYMBOL_POINT);

  //if (closeEnough(sl, 0) ) return;//No line, so nothing to do
  double NewStop = 0;
  bool modify=false;
  bool result = false;
  
  double JSWidth=jumpingStopPips/factor;//Thomas
  int Jsmultiple;//Thomas
  
   if (OrderType()==OP_BUY)
   {
      if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
      // Increment sl by sl + jumpingStopPips.
      // This will happen when market price >= (sl + jumpingStopPips)
      //if (Bid>= sl + ((jumpingStopPips*2) / factor) )
      if (closeEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
      if (bid >= sl + (JSWidth * 2))//Thomas
      {
         Jsmultiple = (int)floor((bid-sl)/(JSWidth))-1;//Thomas
         NewStop = NormalizeDouble(sl + (Jsmultiple*JSWidth), digits);//Thomas
         if (NewStop - OrderStopLoss() >= point) modify = true;//George again. What a guy
      }// if (bid>= sl + (jumpingStopPips / factor) && sl>= OrderOpenPrice())    
   }//if (OrderType()==OP_BUY)
      
      if (OrderType()==OP_SELL)
      {
         if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
         // Decrement sl by sl - jumpingStopPips.
         // This will happen when market price <= (sl - jumpingStopPips)
         //if (bid<= sl - ((jumpingStopPips*2) / factor)) Original code
         if (closeEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
         if (closeEnough(sl, 0) ) sl = OrderOpenPrice();
         if (bid <= sl - (JSWidth * 2))//Thomas
         {
            Jsmultiple = (int)floor((sl-bid)/(JSWidth))-1;//Thomas
            NewStop = NormalizeDouble(sl - (Jsmultiple*JSWidth), digits);//Thomas
            if (OrderStopLoss() - NewStop >= point || OrderStopLoss() == 0) modify = true;//George again. What a guy  
         }// close if (bid>= sl + (jumpingStopPips / factor) && sl>= OrderOpenPrice())        
      }//if (OrderType()==OP_SELL)

  //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
  if (modify)
  {
     while (IsTradeContextBusy() ) Sleep(100);
     result = modifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);      
  }//if (modify)

} //End of jumpingStopLoss
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void trailingStopLoss(int ticket)
{

   //Security check
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   if (OrderProfit() < 0) return;//Nothing to do
   double sl = OrderStopLoss();

  //This next line fixes a bug spotted by biobier. Thanks Alex.
  double point = SymbolInfoDouble(OrderSymbol(),SYMBOL_POINT);
   
   double NewStop = 0;
   bool modify=false;
   bool result = false;
   
    if (OrderType()==OP_BUY)
       {
          if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
          // Increment sl by sl + trailingStopPips.
          // This will happen when market price >= (sl + jumpingStopPips)
          //if (bid>= sl + (trailingStopPips / factor) ) Original code
          if (closeEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
          if (bid >= sl + (trailingStopPips / factor) )//George
          {
             //NewStop = NormalizeDouble(sl + (trailingStopPips / factor), digits);
             //Thanks to FourXXXX for sorting out this next line of code
             NewStop = NormalizeDouble(bid - (trailingStopPips / factor), digits); //FourXXX
             if (NewStop - OrderStopLoss() >= point) modify = true;//George again. What a guy
          }//if (bid >= MathMax(sl,OrderOpenPrice()) + (trailingStopPips / factor) )//George
       }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - trailingStopPips.
          // This will happen when market price <= (sl - jumpingStopPips)
          //if (bid<= sl - (trailingStopPips / factor) ) Original code
          if (closeEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (closeEnough(sl, 0) ) sl = OrderOpenPrice();
          if (bid <= sl  - (trailingStopPips / factor))//George
          {
             //NewStop = NormalizeDouble(sl - (trailingStopPips / factor), digits);
             //Thanks to FourXXXX for sorting out this next line of code
             NewStop = NormalizeDouble(bid + (trailingStopPips / factor), digits); //FourXXX
             if (OrderStopLoss() - NewStop >= point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }//if (bid <= MathMin(sl, OrderOpenPrice() ) - (trailingStopPips / factor) )//George
       }//if (OrderType()==OP_SELL)


   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = modifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
   }//if (modify)
      
} // End of trailingStopLoss sub
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void candlestickTrailingStop(int ticket)
{

   //Security check
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   //Trails the stop at the hi/lo of the previous candle shifted by the user choice.
   //Only tries to do this once per bar, so an invalid stop error will only be generated once. I could code for
   //a too-close sl, but cannot be arsed. Coders, sort this out for yourselves.
   
   string symbol = OrderSymbol();
   
   if (oldCstBars == iBars(symbol, CstTimeFrame)) return;
   oldCstBars = iBars(symbol, CstTimeFrame);

   if (OrderProfit() < 0) return;//Nothing to do
   double sl = OrderStopLoss();
   double NewStop = 0;
   bool modify=false;
   bool result = false;
   

   if (OrderType() == OP_BUY)
   {
      if (iLow(symbol, CstTimeFrame, CstTrailCandles) > sl)
      {
         NewStop = NormalizeDouble(iLow(symbol, CstTimeFrame, CstTrailCandles), digits);
         //Check that the new stop is > the old. Exit the function if not.
         if (NewStop < OrderStopLoss() || closeEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop < OrderOpenPrice() ) return;
         
         modify = true;   
      }//if (iLow(symbol, CstTimeFrame, CstTrailCandles) > sl)
   }//if (OrderType == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      if (iHigh(symbol, CstTimeFrame, CstTrailCandles) < sl)
      {
         NewStop = NormalizeDouble(iHigh(symbol, CstTimeFrame, CstTrailCandles), digits);
         
         //Check that the new stop is < the old. Exit the function if not.
         if (NewStop > OrderStopLoss() || closeEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop > OrderOpenPrice() ) return;
         
         modify = true;   
      }//if (iHigh(symbol, CstTimeFrame, CstTrailCandles) < sl)
   }//if (OrderType() == OP_SELL)
   
   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = modifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (!result) 
      {
         oldCstBars = 0;
      }//if (!result) 
      
   }//if (modify)

}//End void candlestickTrailingStop()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void tradeManagementModule(int ticket)
{

     
   // Call the working subroutines one by one. 

   //Candlestick trailing stop
   if(UseCandlestickTrailingStop) candlestickTrailingStop(ticket);

   // Breakeven
   if(BreakEven) breakEvenStopLoss(ticket);

   // JumpingStop
   if(JumpingStop) jumpingStopLoss(ticket);

   //TrailingStop
   if(TrailingStop) trailingStopLoss(ticket);


}//void tradeManagementModule()
//END TRADE MANAGEMENT MODULE
////////////////////////////////////////////////////////////////////////////////////////


void countTradesForDashboard(string symbol)
{

   openTrades=0;
   openLongTrades=0;
   openShortTrades=0;
   
   if (OrdersTotal() == 0)
      return;
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      
      //Ensure the trade is still open
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
      openTrades++;
      
      if (OrderType()==OP_BUY)
         openLongTrades++;
         
      if (OrderType()==OP_SELL)
         openShortTrades++;
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
}//End void countTradesForDashboard()


void countClosedTradesForDashboard(string symbol)
{

   closedTrades=0;
   closedLongTrades=0;
   closedShortTrades=0;
   
   if (OrdersHistoryTotal() == 0)
      return;
      
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      
      //Ensure the trade is closed
      if (!OrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() == 0) continue; 
      if (OrderType()<0 || OrderType()>1) continue; 
      
      closedTrades++;
      
      if (OrderType()==OP_BUY)
         closedLongTrades++;
         
      if (OrderType()==OP_SELL)
         closedShortTrades++;
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
}//End void countClosedTradesForDashboard()


bool chartMinimize(long chartID = 0) 
{

   //This code was provided by Rene. Many thanks Rene.
   
   if (chartID == 0) chartID = ChartID();
   
   int chartHandle = (int)ChartGetInteger( chartID, CHART_WINDOW_HANDLE, 0 );
   int chartParent = GetParent(chartHandle);
   
   return( ShowWindow( chartParent, SW_FORCEMINIMIZE ) );
}//End bool chartMinimize(long chartID = 0) 

void shrinkCharts()
{
   //Code provided by Rene. Many thanks, Rene
   
   long chartID = ChartFirst();
   
   while( chartID >= 0 ) {
      if ( !chartMinimize( chartID ) ) {
         PrintFormat("Couldn't minimize %I64d (Symbol: %s, Timeframe: %s)", chartID, ChartSymbol(chartID), EnumToString(ChartPeriod(chartID)) );
         //break;
      }
      chartID = ChartNext( chartID );
   }
   
   //PrintFormat("Waiting 10 seconds");
   //Sleep(10000);

}//End void shrinkCharts()


//+------------------------------------------------------------------+
//| Chart Event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
      if(StringFind(sparam,"OAM-BTN")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         string result[];
         int tokens=StringSplit(sparam,StringGetCharacter("-",0),result);
         string pair=result[2];
         int tf=ChartTimeFrame;
         
         //pair = pair + suffix; //Fix Oanda shit (extern string suffix="-5" ;in top as global)
         openChart(pair,tf);
         return;
      }


      
      else if(StringFind(sparam,"OAM-SWITCH")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         switchDisplays();
         return;
      }
      
      else if(StringFind(sparam,"OAM-HIDEPIPS")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         HidePipsDetails=!HidePipsDetails;
         removeAllObjects();
         displayUserFeedback();
         return;
      }
      
      
      else if(StringFind(sparam,"OAM-HIDECASH")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         HideCashDetails=!HideCashDetails;
         removeAllObjects();
         displayUserFeedback();
         return;
      }
      
      
      else if(StringFind(sparam,"OAM-HIDESWAP")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         HideSwapDetails=!HideSwapDetails;
         removeAllObjects();
         displayUserFeedback();
         return;
      }
      
      
      else if(StringFind(sparam,"OAM-HIDESPREAD")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         HideSpreadDetails=!HideSpreadDetails;
         removeAllObjects();
         displayUserFeedback();
         return;
      }
      
      
      else if(StringFind(sparam,"OAM-OPENALL")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         openCharts();
         return;
      }
      
      else if(StringFind(sparam,"OAM-OPENTRADES")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         openTrades();
         return;
      }
      
      else if(StringFind(sparam,"OAM-TOUCH")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         touchCharts();
         return;
      }
      
      else if(StringFind(sparam,"OAM-CLOSE")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         closeCharts();
         return;
      }

}//End void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)

void openChart(string pair,int tf)
{
   //If chart is already open, bring it to top
   long nextchart=ChartFirst();
   do
   {
      string symbol=ChartSymbol(nextchart);
      int period=ChartPeriod(nextchart);
      
      if(symbol==pair && period==tf && nextchart!=ChartID())
      {
         ChartSetInteger(nextchart,CHART_BRING_TO_TOP,true);
         ChartNavigate(nextchart,CHART_END,0);
         drawTradeArrows(pair,nextchart);
         return;
      }
   }
   while((nextchart=ChartNext(nextchart))!=-1);
   
   //Chart not found, so open a new one
   long newchartid=ChartOpen(pair,tf);
   ChartApplyTemplate(newchartid,TemplateName);
   ChartRedraw(newchartid);
   ChartNavigate(newchartid,CHART_END,0);
   drawTradeArrows(pair,newchartid);
   
   timerCount=1;//Restart timer to keep it from closing too early
  
}//End void openChart(string pair,int tf)
 

void switchDisplays()
{
   if (whatToShow=="AllPairs")
      whatToShow="TradablePairs";
   else if (whatToShow=="TradablePairs")
      whatToShow="openTrades";
   else if (whatToShow=="openTrades")
      whatToShow="closedTrades";
   else if (whatToShow=="closedTrades")
      whatToShow="AllTrades";
   else if (whatToShow=="AllTrades")
      whatToShow="AllPairs";
   removeAllObjects();
   displayUserFeedback();
}//End void switchDisplays()


void openCharts()
{
   closeCharts();

   //Open chart for each tradePair
   for (int cc=0;cc<=ArraySize(tradePair)-1;cc++)
   {
      openChart(tradePair[cc],ChartTimeFrame);
   }
   
   //Make the dashboard the active chart again
   ChartSetInteger(ChartID(),CHART_BRING_TO_TOP,true);
   
   return;
   
}//End void openCharts()


void openTrades()
{
   closeCharts();

   //Open chart for each tradePair with open trades
   for (int cc=0;cc<=ArraySize(tradePair)-1;cc++)
   {
      countTradesForDashboard(tradePair[cc]);
      if (openTrades>0)
         openChart(tradePair[cc],ChartTimeFrame);
   }
   
   //Make the dashboard the active chart again
   ChartSetInteger(ChartID(),CHART_BRING_TO_TOP,true);
   
   return;
   
}//End void openCharts()


void closeCharts()
{
   //Cycle through charts
   long nextchart=ChartFirst();
   do
   {
      string symbol=ChartSymbol(nextchart);
      if(symbol!=ReservedPair && nextchart!=ChartID())
         ChartClose(nextchart);
   }
   while((nextchart=ChartNext(nextchart))!=-1);
   
   //Make the dashboard the active chart again
   ChartSetInteger(ChartID(),CHART_BRING_TO_TOP,true);
   
   return;
   
}//End void closeCharts()


void touchCharts()
{
   //Touch the charts backwards for proper CTRL-F6 chart browsing
   for (int cc=ArraySize(tradePair)-1; cc>=0; cc--)
   {
      long nextchart=ChartFirst();
      do
      {
         if(ChartSymbol(nextchart)==tradePair[cc] && nextchart!=ChartID())
         {
            ChartSetInteger(nextchart,CHART_BRING_TO_TOP,true);
            continue;
         }
      }
      while((nextchart=ChartNext(nextchart))!=-1);
   }
   
}//End void touchCharts()


bool enoughDistance(string symbol, int type, double price)
{
   //Returns false if the is < MinDistanceBetweenTradesPips
   //between the price and the nearest order open prices.
   
   double pips = 0;
   
   //No market order yet
   if (type == OP_BUY)
      if (!buyOpen)
         return(true);
      
   if (type == OP_SELL)
      if (!sellOpen)
         return(true);
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!betterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() != type) continue;

      pips = MathAbs(price - OrderOpenPrice() ) * factor;
      if (pips < minDistanceBetweenTrades)
         return(false);
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

 
   //Got here, so OK to trade
   return(true);

   

}//End bool enoughDistance(int type, double price)

double calculateLotSize(string symbol, double price1,double price2)
{
   //Calculate the lot size by risk. Code kindly supplied by jmw1970. Nice one jmw.

   if(price1==0 || price2==0) return(Lot);//Just in case

   double FreeMargin= AccountFreeMargin();
   double TickValue = MarketInfo(symbol,MODE_TICKVALUE);
   double LotStep=MarketInfo(symbol,MODE_LOTSTEP);

   double SLPts=MathAbs(price1-price2);
   //SLPts/=Point;//No idea why *= factor does not work here, but it doesn't
   SLPts = int(SLPts * factor * 10);//Code from Radar. Thanks Radar; much appreciated

   double Exposure=SLPts*TickValue; // Exposure based on 1 full lot

   double AllowedExposure=(FreeMargin*RiskPercent)/100;

   int TotalSteps = (int)((AllowedExposure / Exposure) / LotStep);
   double LotSize = TotalSteps * LotStep;

   double MinLots = MarketInfo(symbol, MODE_MINLOT);
   double MaxLots = MarketInfo(symbol, MODE_MAXLOT);

   if(LotSize < MinLots) LotSize = MinLots;
   if(LotSize > MaxLots) LotSize = MaxLots;
   
   //Dynamic basket take profit
   if (TreatAllPairsAsBasket)
      if (UseDynamicCashTP)
         calculateDynamicBasketCashTP(LotSize);
   
   
   return(LotSize);

}//double calculateLotSize(double price1, double price1)

void lookForTradingOpportunities(string symbol, int pairIndex)
{
//return;//TEMPORARY. REMOVE LATER
   
   getBasics(symbol);
   double take = 0, stop = 0, price = 0;
   int type = 0;
   bool SendTrade = false, result = false;
   double hiddenStop = 0, hiddenTake = 0;//For saving the hidden stops in a global variable
   string gvFileName = "";//For naming the GV

   double sendLots = Lot;
   

   //Check filters
   if (!isTradingAllowed(symbol, pairIndex) ) return;

   
   /////////////////////////////////////////////////////////////////////////////////////
   
   //Trading decision.
   bool SendLong = false, SendShort = false;

   //Long trade
   
   //Specific system filters
   if (buySignal[pairIndex]) 
      SendLong = true;
   
   //Usual filters
   if (SendLong)
   {
      //Cancel trade if any of the filters turned off long trading
      if (!tradeLong) return;

      if (UseZeljko && !balancedPair(symbol, OP_BUY) ) return;
      
      //Change of market state - explanation at the end of start()
      //if (OldAsk <= some_condition) SendLong = false;   
   }//if (SendLong)
   
   /////////////////////////////////////////////////////////////////////////////////////

   if (!SendLong)
   {
      //Short trade
      //Specific system filters
      if (sellSignal[pairIndex]) 
         SendShort = true;
      
      if (SendShort)
      {      
         //Usual filters

         //Cancel trade if any of the filters turned off short trading
         if (!tradeShort) return;

         //Other filters
           
         if (UseZeljko && !balancedPair(symbol, OP_SELL) ) return;
         
         //Change of market state - explanation at the end of start()
         //if (OldBid += some_condition) SendShort = false;   
      }//if (SendShort)
      
   }//if (!SendLong)
     

////////////////////////////////////////////////////////////////////////////////////////
   
   
   //Long 
   if (SendLong)
   {
       
      type=OP_BUY;
      price = NormalizeDouble(MarketInfo(symbol, MODE_ASK), digits);
         
      if (!HideStopLossAndTakeProfit)
      {
         stop = calculateStopLoss(OP_BUY, price);
            
            
         take = calculateTakeProfit(OP_BUY, price);
         
      }//if (!HideStopLossAndTakeProfit)
      
      
      //Scale back in sltp correction
      //Store hidden tpsl in a global variable for scaling back in
      if (UseScaleBackIn)
         if (HideStopLossAndTakeProfit)
         {
            hiddenStop = calculateStopLoss(OP_BUY, price);
            gvFileName = symbol + stopLossGvName;
            GlobalVariableSet(gvFileName, hiddenStop);
            
               
            hiddenTake = calculateTakeProfit(OP_BUY, price);
            gvFileName = symbol + takeProfitGvName;
            GlobalVariableSet(gvFileName, hiddenTake);
            
            
         }//if (HideStopLossAndTakeProfit)
      
      
      //Lot size calculated by risk
      if (!closeEnough(RiskPercent, 0)) sendLots = calculateLotSize(symbol, price, stop );

               
      SendTrade = true;
      
   }//if (SendLong)
   
   //Short
   if (SendShort)
   {
      
      type=OP_SELL;
      price = NormalizeDouble(MarketInfo(symbol, MODE_BID), digits);

      if (!HideStopLossAndTakeProfit)
      {
         stop = calculateStopLoss(OP_SELL, price);
            
            
         take = calculateTakeProfit(OP_SELL, price);
         
      }//if (!HideStopLossAndTakeProfit)
      
      
      //Lot size calculated by risk
      if (!closeEnough(RiskPercent, 0)) sendLots = calculateLotSize(symbol, price, stop);

      //Scale back in sltp correction
      //Store hidden tpsl in a global variable for scaling back in
      if (UseScaleBackIn)
         if (HideStopLossAndTakeProfit)
         {
            hiddenStop = calculateStopLoss(OP_SELL, price);
            gvFileName = symbol + stopLossGvName;
            GlobalVariableSet(gvFileName, hiddenStop);
            
               
            hiddenTake = calculateTakeProfit(OP_SELL, price);
            gvFileName = symbol + takeProfitGvName;
            GlobalVariableSet(gvFileName, hiddenTake);
            
            
         }//if (HideStopLossAndTakeProfit)
      
         
      SendTrade = true;      
   
      
   }//if (SendShort)
   

   if (SendTrade)
   {
      
      result = true;//Allow sending the grid if not sending an immediate market trade
      
      if (SendImmediateMarketTrade)
         result = sendSingleTrade(symbol, type, TradeComment, sendLots, price, stop, take);
      
      if (result)
      {
         //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so tell the
         //ea not to trade for a while, to give time for the trade receipt to return from the server.
         timeToStartTrading[pairIndex] = TimeCurrent() + PostTradeAttemptWaitSeconds;
        
         GlobalVariableSet(gvFileName, sendLots);
         //Also sltp for hidden stops
         gvFileName = symbol + stopLossGvName;
         GlobalVariableSet(gvFileName, stop);
         gvFileName = symbol + takeProfitGvName;
         GlobalVariableSet(gvFileName, take);
            
              
         if (betterOrderSelect(ticketNo, SELECT_BY_TICKET, MODE_TRADES) )
            checkTpSlAreCorrect(type);
            
         if (GridSize > 0)
         {
            if (type == OP_BUY || type == OP_BUYSTOP)
               sendBuyGrid(symbol, OP_BUYSTOP, price, sendLots, TradeComment);
            else
               sendSellGrid(symbol, OP_SELLSTOP, price, sendLots, TradeComment);
               
         }//if (GridSize > 0)
         
      }//if (result)          
   

      
      
   }//if (SendTrade)   
   

}//End void lookForTradingOpportunities(string symbol, int pairIndex)

bool balancedPair(string symbol, int type)
{

   //Only allow an individual currency to trade if it is a balanced trade
   //e.g. UJ Buy open, so only allow Sell xxxJPY.
   //The passed parameter is the proposed trade, so an existing one must balance that

   //This code courtesy of Zeljko (zkucera) who has my grateful appreciation.
   
   string BuyCcy1, SellCcy1, BuyCcy2, SellCcy2;

   if (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT)
   {
      BuyCcy1 = stringSubstrOld(symbol, 0, 3);
      SellCcy1 = stringSubstrOld(symbol, 3, 3);
   }//if (type == OP_BUY || type == OP_BUYSTOP)
   else
   {
      BuyCcy1 = stringSubstrOld(symbol, 3, 3);
      SellCcy1 = stringSubstrOld(symbol, 0, 3);
   }//else

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!betterOrderSelect(cc, SELECT_BY_POS)) continue;
      if (OrderSymbol() == symbol) continue;
      if (OrderMagicNumber() != MagicNumber) continue;      
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || type == OP_BUYLIMIT)
      {
         BuyCcy2 = stringSubstrOld(OrderSymbol(), 0, 3);
         SellCcy2 = stringSubstrOld(OrderSymbol(), 3, 3);
      }//if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      else
      {
         BuyCcy2 = stringSubstrOld(OrderSymbol(), 3, 3);
         SellCcy2 = stringSubstrOld(OrderSymbol(), 0, 3);
      }//else
      if (BuyCcy1 == BuyCcy2 || SellCcy1 == SellCcy2) return(false);
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so it is ok to send the trade
   return(true);

}//End bool balancedPair(int type)

bool closeEnough(double num1,double num2)
{
/*
   This function addresses the problem of the way in which mql4 compares doubles. It often messes up the 8th
   decimal point.
   For example, if A = 1.5 and B = 1.5, then these numbers are clearly equal. Unseen by the coder, mql4 may
   actually be giving B the value of 1.50000001, and so the variable are not equal, even though they are.
   This nice little quirk explains some of the problems I have endured in the past when comparing doubles. This
   is common to a lot of program languages, so watch out for it if you program elsewhere.
   Gary (garyfritz) offered this solution, so our thanks to him.
   */

   if(num1==0 && num2==0) return(true); //0==0
   if(MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);

//Doubles are unequal
   return(false);

}//End bool closeEnough(double num1, double num2)

double calculateTradeProfitInPips(int type)
{
   //This code supplied by Lifesys. Many thanks Paul.
   
   //Returns the pips Upl of the currently selected trade. Called by countOpenTrades()
   double profit = 0;
  
   if (type == OP_BUY)
   {
      profit = bid - OrderOpenPrice();
   }//if (OrderType() == OP_BUY)

   if (type == OP_SELL)
   {
      profit = OrderOpenPrice() - ask;
   }//if (OrderType() == OP_SELL)
   //profit *= PFactor(OrderSymbol()); // use PFactor instead of point. This line for multi-pair ea's
   profit *= factor; // use PFactor instead of point.

   return(profit); // in real pips
}//double calculateTradeProfitInPips(int type)

bool doesTradeExist(string symbol, int type,double price)
{

   if(OrdersTotal()==0)
      return(false);
   if(openTrades==0)
      return(false);


   for(int cc=OrdersTotal()-1; cc>=0; cc--)
   {
      if(!OrderSelect(cc,SELECT_BY_POS)) continue;
      if(OrderSymbol()!=symbol) continue;
      if(OrderMagicNumber()!=MagicNumber) continue;
      if(OrderType()!=type) continue;
      if(!closeEnough(OrderOpenPrice(),price)) continue;

      //Got to here, so we have found a trade
      return(true);

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

//Got this far, so no trade found
   return(false);

}//End bool doesTradeExist(string symbol, int type,double price)

void sendBuyGrid(string symbol,int type,double price,double lot,string comment) //MJB
{

//Send a grid of stop orders using the passed parameters

   //Max trades allowed by broker check.
   if (!checkBrokerMaxTradesOnPlatform(GridSize) )
      return;



   double stop = 0;
   double take = 0;
   bool result = false;


   
   getBasics(symbol);//Just in case these have got scrambled.
   
   //Atr for grid size
   if (UseAtrForGrid)
   {
      double val = getAtr(symbol, GridAtrTimeFrame, GridAtrPeriod, 0);
      distanceBetweenTrades = (val * factor) / GridAtrDivisor;
   }//if (UseAtrForGrid)
   
   //Set the initial trade price
   price=NormalizeDouble(price+(distanceBetweenTrades/factor),digits);
   
   //Grid orders are sent after an ititial trade has triggered.
   //All orders should have the same tpsl as the first trade, so
   //read these from the global variables.
   //We only want >0 values if the tpsl is not hidden
   if (!HideStopLossAndTakeProfit)
   {
      if (GlobalVariableCheck(symbol + takeProfitGvName) )
         take = GlobalVariableGet(symbol + takeProfitGvName);
         
      if (GlobalVariableCheck(symbol + stopLossGvName) )
         stop = GlobalVariableGet(symbol + stopLossGvName);
   }//if (!HideStopLossAndTakeProfit)

   
   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<GridSize; cc++)
   {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      if(doesTradeExist(symbol,type,price))
      {
         //Increment the price for the next pending
         if(type==OP_BUYSTOP)
            price=NormalizeDouble(price+(distanceBetweenTrades/factor),digits);
         
         continue;
      }//if (doesTradeExist(OP_BUYSTOP, price))

      /*This has to be removed or the grid will not be sent with the same sltp
      if (!HideStopLossAndTakeProfit)
      {
         stop = calculateStopLoss(OP_BUY, price);
         if (!UseNextLevelForTP)
            take = calculateTakeProfit(OP_BUY, price);
         if (UseNextLevelForTP)//Set the tp at the open price of the next trade
            take = NormalizeDouble(price + (distanceBetweenTrades / factor), digits);
      }//if (!HideStopLossAndTakeProfit)
      */  
         

      if(!IsExpertEnabled())
      {
         Comment("                          EXPERTS DISABLED");
         return;
      }//if (!IsExpertEnabled() )

      result=true;
      //TradeComment is defined either in readIndicatorValues,
      //and subsequently in countOpenTrades()
      result=sendSingleTrade(symbol,type,comment,lot,price,stop,take); //MJB

      //Each trade in the grid must be sent, so deal with failures
      if(!result)
      {
         int err=GetLastError();
         if(err==132)//Market is closed
            return;
         Alert(symbol," Buy stop: Lots ",lot,": Price ",price,": Ask ",ask);
         Alert(symbol," ",WindowExpertName()," order send failed with error(",err,"): ",ErrorDescription(err));
         Sleep(5000);
         cc--;
         continue;//Do not want price incrementing
      }//if (!result)

      price=NormalizeDouble(price+(distanceBetweenTrades/factor),digits);
      
      Sleep(1000);
      
      
      if (result)
      {  
         
      }//if (result)
            
      
   }//for (int cc = 0; cc < GridSize; cc++)


}//End void sendBuyGrid(string symbol, double price, double lot)

void sendSellGrid(string symbol,int type,double price,double lot,string comment) //MJB
{

   //Send a grid of stop orders using the passed parameters

   //Max trades allowed by broker check.
   if (!checkBrokerMaxTradesOnPlatform(GridSize) )
      return;


   double stop = 0;
   double take = 0;
   bool result = false;

   getBasics(symbol);//Just in case these have got scrambled.
   
   //Atr for grid size
   if (UseAtrForGrid)
   {
      double val = getAtr(symbol, GridAtrTimeFrame, GridAtrPeriod, 0);
      distanceBetweenTrades = (val * factor) / GridAtrDivisor;
   }//if (UseAtrForGrid)

   //Set the initial trade price
   price = NormalizeDouble(bid - (distanceBetweenTrades / factor), digits);
   
   //Grid orders are sent after an ititial trade has triggered.
   //All orders should have the same tpsl as the first trade, so
   //read these from the global variables.
   //We only want >0 values if the tpsl is not hidden
   if (!HideStopLossAndTakeProfit)
   {
      if (GlobalVariableCheck(symbol + takeProfitGvName) )
         take = GlobalVariableGet(symbol + takeProfitGvName);
         
      if (GlobalVariableCheck(symbol + stopLossGvName) )
         stop = GlobalVariableGet(symbol + stopLossGvName);
   }//if (!HideStopLossAndTakeProfit)
   
   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<GridSize; cc++)
   {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      if(doesTradeExist(symbol,type,price))
      {
         //Increment the price for the next pending
         price=NormalizeDouble(price -(distanceBetweenTrades/factor),digits);

         continue;
      }//if (doesTradeExist(OP_SELLSTOP, price))

      /*This has to be removed or the grid will not be sent with the same sltp
      if (!HideStopLossAndTakeProfit)
      {
         stop = calculateStopLoss(OP_SELL, price);
         if (!UseNextLevelForTP)
            take = calculateTakeProfit(OP_SELL, price);
         if (UseNextLevelForTP)//Set the tp at the open price of the next trade
            take = NormalizeDouble(price - (distanceBetweenTrades / factor), digits);
      }//if (!HideStopLossAndTakeProfit)
      */
       
      if(!IsExpertEnabled())
      {
         Comment("                          EXPERTS DISABLED");
         return;
      }//if (!IsExpertEnabled() )

      result=true;
      //TradeComment is defined either in readIndicatorValues,
      //and subsequently in countOpenTrades()
      result=sendSingleTrade(symbol,type,comment,lot,price,stop,take); //MJB

      //Each trade in the grid must be sent, so deal with failures
      if(!result)
      {
         int err=GetLastError();
         if(err==132)//Market is closed
            return;
         Alert(symbol, " Sell stop: Lots ",lot,": Price ",price,": Bid ",bid);Sleep(5000);
         Alert(symbol," ",WindowExpertName()," order send failed with error(",err,"): ",ErrorDescription(err));
         cc--;
         continue;//Do not want price incrementing
      }//if (!result)


      //Increment the price for the next pending
      price=NormalizeDouble(price -(distanceBetweenTrades/factor),digits);

      Sleep(1000);

      if (result)
      {  
         
      }//if (result)
            
}//for (int cc = 0; cc < GridSize; cc++)



}//End void sendSellGrid(string symbol, double price, double lot)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool sendSingleTrade(string symbol,int type,string comment,double lotsize,double price,double stop,double take)
{

   double slippage=MaxSlippagePips*MathPow(10,digits)/factor;
   int ticket = -1;


   
   datetime expiry=0;
   //if (SendPendingTrades) expiry = TimeCurrent() + (PendingExpiryMinutes * 60);

   //RetryCount is declared as 10 in the Trading variables section at the top of this file
   for(int cc=0; cc<RetryCount; cc++)
     {
      //for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);

      while(IsTradeContextBusy()) Sleep(100);//Put here so that excess slippage will cancel the trade if the ea has to wait for some time.
      
      if(type == OP_BUY) price = MarketInfo(symbol, MODE_ASK);
      if(type == OP_SELL) price = MarketInfo(symbol, MODE_BID);

      
      if(!IsGlobalPrimeOrECNCriminal)
         ticket=OrderSend(symbol,type,lotsize,price,(int)slippage,stop,take,comment,MagicNumber,expiry,clrNONE);
         //ticket=OrderSend(symbol,type,lotsize,price,slippage,stop,take,comment,MagicNumber,expiry,col);

      //Is a 2 stage criminal
      if(IsGlobalPrimeOrECNCriminal)
      {
         ticket=OrderSend(symbol,type,lotsize,price,(int)slippage,0,0,comment,MagicNumber,expiry,clrNONE);
         if(ticket>-1)
         {
            modifyOrderTpSl(ticket,stop,take);
         }//if (ticket > 0)}
      }//if (IsGlobalPrimeOrECNCriminal)

      if(ticket>-1) break;//Exit the trade send loop
      if(cc == RetryCount - 1) return(false);

      //Error trapping for both
      if(ticket<0)
        {
         string stype;
         if(type == OP_BUY) stype = "OP_BUY";
         if(type == OP_SELL) stype = "OP_SELL";
         if(type == OP_BUYLIMIT) stype = "OP_BUYLIMIT";
         if(type == OP_SELLLIMIT) stype = "OP_SELLLIMIT";
         if(type == OP_BUYSTOP) stype = "OP_BUYSTOP";
         if(type == OP_SELLSTOP) stype = "OP_SELLSTOP";
         int err=GetLastError();
         if (type < 2)
            Alert(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         Print(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         return(false);
        }//if (ticket < 0)  
     }//for (int cc = 0; cc < RetryCount; cc++);

   ticketNo=ticket;
   //Make sure the trade has appeared in the platform's history to avoid duplicate trades.
   //My mod of Matt's code attempts to overcome the bastard crim's attempts to overcome Matt's code.
   bool TradeReturnedFromCriminal=false;
   while(!TradeReturnedFromCriminal)
     {
      TradeReturnedFromCriminal=o_R_CheckForHistory(ticket);
      if(!TradeReturnedFromCriminal)
        {
         Alert(symbol," sent trade not in your trade history yet. Turn of this ea NOW.");
        }//if (!TradeReturnedFromCriminal)
     }//while (!TradeReturnedFromCriminal)

   //Got this far, so trade send succeeded
   return(true);

}//End bool sendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void modifyOrderTpSl(int ticket, double stop, double take)
{
   //Modifies an order already sent if the crim is ECN.

   if (closeEnough(stop, 0) && closeEnough(take, 0) ) return; //nothing to do

   if (!betterOrderSelect(ticket, SELECT_BY_TICKET) ) return;//Trade does not exist, so no mod needed
   
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice() && !closeEnough(take, 0) ) 
   {
      take = 0;
      reportError(" modifyOrder()", " take profit < market ");
      return;
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      reportError(" modifyOrder()", " take profit < market ");
      return;
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      reportError(" modifyOrder()", " stop loss > market ");
      return;
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice()  && !closeEnough(stop, 0) ) 
   {
      stop = 0;
      reportError(" modifyOrder()", " stop loss < market ");
      return;
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   string Reason;
   //RetryCount is declared as 10 in the Trading variables section at the top of this file   
   for (int cc = 0; cc < RetryCount; cc++)
   {
      for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);
        if (!closeEnough(take, 0) && !closeEnough(stop, 0) )
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (modifyOrder(ticket, OrderOpenPrice(), stop, take, OrderExpiration(), clrNONE, __FUNCTION__, tpsl)) return;
        }//if (take > 0 && stop > 0)
   
        if (!closeEnough(take, 0) && closeEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (modifyOrder(ticket, OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm)) return;
        }//if (take == 0 && stop != 0)

        if (closeEnough(take, 0) && !closeEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (modifyOrder(ticket, OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm)) return;
        }//if (take == 0 && stop != 0)
   }//for (int cc = 0; cc < RetryCount; cc++)
   
   
   
}//void modifyOrderTpSl(int ticket, double tp, double sl)

//=============================================================================
//                           o_R_CheckForHistory()
//
//  This function is to work around a very annoying and dangerous bug in MT4:
//      immediately after you send a trade, the trade may NOT show up in the
//      order history, even though it exists according to ticket number.
//      As a result, EA's which count history to check for trade entries
//      may give many multiple entries, possibly blowing your account!
//
//  This function will take a ticket number and loop until
//  it is seen in the history.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2010
//
//=============================================================================
bool o_R_CheckForHistory(int ticket)
  {
//My thanks to Matt for this code. He also has the undying gratitude of all users of my trading robots

   int lastTicket=OrderTicket();

   int cnt =0;
   int err=GetLastError(); // so we clear the global variable.
   err=0;
   bool exit_loop=false;
   bool success=false;
   int c = 0;

   while(!exit_loop) 
     {
/* loop through open trades */
      int total=OrdersTotal();
      for(c=0; c<total; c++) 
        {
         if(betterOrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true) 
           {
            if(OrderTicket()==ticket) 
              {
               success=true;
               exit_loop=true;
              }
           }
        }
      if(cnt>3) 
        {
/* look through history too, as order may have opened and closed immediately */
         total=OrdersHistoryTotal();
         for(c=0; c<total; c++) 
           {
            if(betterOrderSelect(c,SELECT_BY_POS,MODE_HISTORY)==true) 
              {
               if(OrderTicket()==ticket) 
                 {
                  success=true;
                  exit_loop=true;
                 }
              }
           }
        }

      cnt=cnt+1;
      if(cnt>o_R_Setting_max_retries) 
        {
         exit_loop=true;
        }
      if(!(success || exit_loop)) 
        {
         Print("Did not find #"+IntegerToString(ticket)+" in history, sleeping, then doing retry #"+IntegerToString(cnt));
         o_R_Sleep(o_R_Setting_sleep_time,o_R_Setting_sleep_max);
        }
     }
// Select back the prior ticket num in case caller was using it.
   if(lastTicket>=0) 
     {
      bool s = betterOrderSelect(lastTicket,SELECT_BY_TICKET,MODE_TRADES);
     }
   if(!success) 
     {
      Print("Never found #"+IntegerToString(ticket)+" in history! crap!");
     }
   return(success);
  }//End bool o_R_CheckForHistory(int ticket)
//=============================================================================
//                              o_R_Sleep()
//
//  This sleeps a random amount of time defined by an exponential
//  probability distribution. The mean time, in Seconds is given
//  in 'mean_time'.
//  This returns immediately if we are backtesting
//  and does not sleep.
//
//=============================================================================
void o_R_Sleep(double mean_time, double max_time)
{
   if (IsTesting()) 
   {
      return;   // return immediately if backtesting.
   }

   double p = (MathRand()+1) / 32768.0;
   double t = -MathLog(p)*mean_time;
   t = MathMin(t,max_time);
   int ms = (int)t*1000;
   if (ms < 10) {
      ms=10;
   }//if (ms < 10) {
   
   Sleep(ms);
}//End void o_R_Sleep(double mean_time, double max_time)

////////////////////////////////////////////////////////////////////////////////////////

void checkTpSlAreCorrect(int type)
{
   //Looks at an open trade and checks to see that the exact tp/sl were sent with the trade.
   
   if (HideStopLossAndTakeProfit)
      return;
   
   double stop = 0, take = 0, diff = 0;
   bool ModifyStop = false, ModifyTake = false;
   bool result;
   
   //Is the stop at BE?
   if (type == OP_BUY && OrderStopLoss() >= OrderOpenPrice() ) return;
   if (type == OP_SELL && OrderStopLoss() <= OrderOpenPrice() ) return;
   
   if (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT)
   {
      if (!closeEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderOpenPrice() - OrderStopLoss()) * factor;
         if (!closeEnough(diff, stopLoss) ) 
         {
            ModifyStop = true;
            stop = calculateStopLoss(OP_BUY, OrderOpenPrice());
         }//if (!closeEnough(diff, stopLoss) )          
      }//if (!closeEnough(OrderStopLoss(), 0) )      

      if (!closeEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderTakeProfit() - OrderOpenPrice()) * factor;
         if (!closeEnough(diff, takeProfit) ) 
         {
            ModifyTake = true;
            take = calculateTakeProfit(OP_BUY, OrderOpenPrice());
         }//if (!closeEnough(diff, takeProfit) )          
      }//if (!closeEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_BUY)
   
   if (type == OP_SELL || type == OP_SELLSTOP || type == OP_SELLLIMIT)
   {
      if (!closeEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderStopLoss() - OrderOpenPrice() ) * factor;
         if (!closeEnough(diff, stopLoss) ) 
         {
            ModifyStop = true;
            stop = calculateStopLoss(OP_SELL, OrderOpenPrice());

         }//if (!closeEnough(diff, stopLoss) )          
      }//if (!closeEnough(OrderStopLoss(), 0) )      

      if (!closeEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderOpenPrice() - OrderTakeProfit() ) * factor;
         if (!closeEnough(diff, takeProfit) ) 
         {
            ModifyTake = true;
            take = calculateTakeProfit(OP_SELL, OrderOpenPrice());
         }//if (!closeEnough(diff, takeProfit) )          
      }//if (!closeEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_SELL)
   
   if (ModifyStop)
   {
      result = modifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (ModifyStop)
   
   if (ModifyTake)
   {
      result = modifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm);
   }//if (ModifyStop)
   

}//void checkTpSlAreCorrect(int type)


void closeAllTrades(string symbol, int type)
{
   forceTradeClosure= false;
   
   countTotalsForDisplay();
  
   
   if (OrdersTotal() == 0) return;
   
   //For US traders
   if (MustObeyFIFO)
   {
      closeAllTradesFIFO(symbol, type);
      return;
   }//if (MustObeyFIFO)
      

   bool result = false;
   for (int pass = 0; pass <= 1; pass++)
   {
      
      for (int cc = ArraySize(fifoTicket) - 1; cc >= 0; cc--)
      {
         if (!betterOrderSelect(fifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
         if (OrderMagicNumber() != MagicNumber) continue;
         if (OrderSymbol() != symbol) 
            if (symbol != AllSymbols)
               continue;
         if (OrderType() != type) 
            if (type != AllTrades)
               continue;
         
         while(IsTradeContextBusy()) Sleep(100);
         if (OrderType() < 2)
         {
            result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
            if (result) 
            {
               cc++;
               openTrades--;
            }//(result) 
            
            if (!result) forceTradeClosure= true;
         }//if (OrderType() < 2)
         
         if (pass == 1)
            if (deletePendings)
               if (OrderType() > 1) 
               {
                  result = OrderDelete(OrderTicket(), clrNONE);
                  if (result) 
                  {
                     cc++;
                     openTrades--;
                  }//(result) 
                  if (!result) forceTradeClosure= true;
               }//if (OrderType() > 1) 
               
      }//for (int cc = ArraySize(fifoTicket) - 1; cc >= 0; cc--)
   }//for (int pass = 0; pass <= 1; pass++)
   
  
}//End void closeAllTrades(string symbol, int type)

void closeAllTradesFIFO(string symbol, int type)
{
   forceTradeClosure= false;
   
   if (OrdersTotal() == 0) return;

   bool result = false;
   for (int cc = ArraySize(fifoTicket) - 1; cc >= 0; cc--)
   {
      if (!betterOrderSelect(fifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != symbol) 
         if (symbol != AllSymbols)
            continue;
      if (OrderType() != type) 
         if (type != AllTrades)
            continue;
      
      while(IsTradeContextBusy()) Sleep(100);
      if (OrderType() < 2)
      {
         result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
         if (result) 
         {
            cc++;
         }//(result) 
         
         if (!result) forceTradeClosure= true;
      }//if (OrderType() < 2)
      
      if (OrderType() > 1) 
      {
         result = OrderDelete(OrderTicket(), clrNONE);
         if (result) 
         {
            cc++;
         }//(result) 
         if (!result) forceTradeClosure= true;
      }//if (OrderType() > 1) 
      
   }//for (int cc = ArraySize(fifoTicket) - 1; cc >= 0; cc--)


}//End void closeAllTradesFIFO(string symbol, int type)

void shutDownForTheWeekend()
{

   //Close/delete all trades to be flat for the weekend.
   
   int day = TimeDayOfWeek(TimeLocal() );
   int hour = TimeHour(TimeLocal() );
   bool CloseDelete = false;
   
   //Friday
   if (day == 5)
   {
      if (hour >= FridayCloseAllHour)
         if (totalCashUpl >= MaxAllowableCashLoss)//MaxAllowableCashLoss is a negative number
            CloseDelete = true;
   }//if (day == 5)
 
   //Saturday
   if (day == 6)
   {
      if (hour >= SaturdayCloseAllHour)
         if (totalCashUpl >= MaxAllowableCashLoss)//MaxAllowableCashLoss is a negative number
            CloseDelete = true;
   }//if (day == 6)
   
   if (CloseDelete)
   {
      deletePendings = true;
      closeAllTrades(AllSymbols, AllTrades);
      if (forceTradeClosure)
         closeAllTrades(AllSymbols, AllTrades);
      if (forceTradeClosure)
         closeAllTrades(AllSymbols, AllTrades);
   }//if (CloseDelete)
      

}//End void shutDownForTheWeekend()

bool mopUpTradeClosureFailures()
{
   //Cycle through the ticket numbers in the forceCloseTickets array, and attempt to close them
   
   bool Success = true;
   
   for (int cc = ArraySize(forceCloseTickets) - 1; cc >= 0; cc--)
   {
      //Order might have closed during a previous attempt, so ensure it is still open.
      if (!betterOrderSelect(forceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
         continue;
   
      bool result = closeOrder(OrderTicket() );
      if (!result)
         Success = false;
   }//for (int cc = ArraySize(forceCloseTickets) - 1; cc >= 0; cc--)
   
   if (Success)
      ArrayFree(forceCloseTickets);
   
   return(Success);


}//END bool mopUpTradeClosureFailures()


bool marginCheck()
{

   enoughMargin = true;//For user display
   marginMessage = "";
   if (UseScoobsMarginCheck && openTrades > 0)
   {
      if(AccountMargin() > (AccountFreeMargin()/100)) 
      {
         marginMessage = "There is insufficient margin to allow trading. You might want to turn off the UseScoobsMarginCheck input.";
         return(false);
      }//if(AccountMargin() > (AccountFreeMargin()/100)) 
      
   }//if (UseScoobsMarginCheck)


   if (UseForexKiwi && AccountMargin() > 0)
   {
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < FkMinimumMarginPercent)
      {
         marginMessage = StringConcatenate("There is insufficient margin percent to allow trading. ", DoubleToStr(ml, 2), "%");
         return(false);
      }//if (ml < FkMinimumMarginPercent)
   }//if (UseForexKiwi && AccountMargin() > 0)
   
   //Margin level
   if (!closeEnough(AccountMargin(), 0) )
   {
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < DeletePendingsBelowThisMarginLevelPercent || ml < CloseDeleteAllBelowThisMarginLevelPercent)
         return(false);   
   }//if (!closeEnough(AccountMargin(), 0) )
  
   //Got this far, so there is sufficient margin for trading
   return(true);
}//End bool marginCheck()

bool checkTradingTimes() 
{

	// Trade 24 hours if no input is given
	if ( ArraySize( tradeHours ) == 0 ) return ( true );

	// Get local time in minutes from midnight
    int time = TimeHour( TimeLocal() ) * 60 + TimeMinute( TimeLocal() );
   
	// Don't you love this?
	int i = 0;
	while ( time >= tradeHours[i] ) 
	{	
		i++;		
		if ( i == ArraySize( tradeHours ) ) break;
	}
	if ( i % 2 == 1 ) return ( true );
	return ( false );
}//End bool checkTradingTimes2() 
//+------------------------------------------------------------------+
//| Initialize Trading Hours Array                                   |
//+------------------------------------------------------------------+
bool initTradingHours() 
{
   // Called from init()
   
	// Assume 24 trading if no input found
	if ( tradingHours == "" )	
	{
		ArrayFree(tradeHours);
		return ( true );
	}

	int i;

	// Add 00:00 start time if first element is stop time
	if ( stringSubstrOld( tradingHours, 0, 1 ) == "-" ) 
	{
		tradingHours = StringConcatenate( "+0,", tradingHours );   
	}
	
	// Add delimiter
	if ( stringSubstrOld( tradingHours, StringLen( tradingHours ) - 1) != "," ) 
	{
		tradingHours = StringConcatenate( tradingHours, "," );   
	}
	
	string lastPrefix = "-";
	i = StringFind( tradingHours, "," );
	
	while (i != -1) 
	{

		// Resize array
		int size = ArraySize( tradeHours );
		ArrayResize( tradeHours, size + 1 );

		// Get part to process
		string part = stringSubstrOld( tradingHours, 0, i );

		// Check start or stop prefix
		string prefix = stringSubstrOld ( part, 0, 1 );
		if ( prefix != "+" && prefix != "-" ) 
		{
			Print("ERROR IN TRADINGHOURS INPUT (NO START OR CLOSE FOUND), ASSUME 24HOUR TRADING.");
			ArrayFree( tradeHours );
			return ( true );
		}

		if ( ( prefix == "+" && lastPrefix == "+" ) || ( prefix == "-" && lastPrefix == "-" ) )	
		{
			Print("ERROR IN TRADINGHOURS INPUT (START OR CLOSE IN WRONG ORDER), ASSUME 24HOUR TRADING.");
			ArrayFree ( tradeHours );
			return ( true );
		}
		
		lastPrefix = prefix;

		// Convert to time in minutes
		part = stringSubstrOld( part, 1 );
		double time = StrToDouble( part );
		int hour = (int)MathFloor( time );
		int minutes = (int)MathRound( ( time - hour ) * 100 );

		// Add to array
		tradeHours[size] = 60 * hour + minutes;

		// Trim input string
		tradingHours = stringSubstrOld( tradingHours, i + 1 );
		i = StringFind( tradingHours, "," );
	}//while (i != -1) 

	return ( true );
}//End bool initTradingHours() 

// for 6xx build compatibilità added by milanese
string stringSubstrOld(string x,int a,int b=-1) 
{
   if(a<0) a=0; // Stop odd behaviour
   if(b<=0) b=-1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
}

bool sundayMondayFridayStuff()
{

   //Friday/Saturday stop trading hour
   int d = TimeDayOfWeek(TimeLocal());
   int h = TimeHour(TimeLocal());
   
   
   //This snippet courtesy of 1of3. Many thanks, John.
   if ((d == 5 && h >= FridayCloseAllHour) || (d == 6 && h >= SaturdayCloseAllHour))
   {
      return(false);
   }//if ((day == 5 && hour >= FridayCloseAllHour) || (day == 6 && hour >= SaturdayCloseAllHour))[/code]

   
   if (d == 5)
      if (h >= FridayStopTradingHour)
         if (openTrades == 0)
            return(false);
         
   if (d == 4)
      if (!TradeThursdayCandle)
         return(false);
        
   
   if (d == 6)
      if (h >= SaturdayStopTradingHour)
         return(false);
  
   //Sunday candle
   if (d == 0)
      if (!TradeSundayCandle)
         return(false);
         
   //Monday start hour
   if (d == 1)
      if (h < MondayStartHour)      
         return(false);
         
   //Got this far, so we are in a trading period
   return(true);      
   
}//End bool  sundayMondayFridayStuff()

bool biggerPictureSellOnlyPairs(string symbol)
{
   //Returns 'true' if the pair is in the SellOnlyPairs list
   //else returns 'false'

   //No pairs in the list
   if (PairsToTradeShortOnly == "")
      return(false);

   for (int cc = 0; cc < noOfSellOnlyPairs; cc++)
   {
      if (shortOnlyPairs[cc] == symbol)
         return(true);
   }//for (int cc = 0; cc < noOfSellOnlyPairs; cc++)
   
   
   //Got this far, so the pair is not in the list
   return(false);

}//bool biggerPictureSellOnlyPairs(string symbol)

bool biggerPictureBuyOnlyPairs(string symbol)
{
   //Returns 'true' if the pair is in the BuyOnlyPairs list
   //else returns 'false'

   //No pairs in the list
   if (PairsToTradeLongOnly == "")
      return(false);

   for (int cc = 0; cc < noOfLongOnlyPairs; cc++)
   {
      if (longOnlyPairs[cc] == symbol)
         return(true);
   }//for (int cc = 0; cc < noOfLongOnlyPairs; cc++)
   
   
   //Got this far, so the pair is not in the list
   return(false);

}//bool biggerPictureBuyOnlyPairs(string symbol)

bool checkBrokerMaxTradesOnPlatform(int noOfTrades)
{

   int maxAllowedByBroker = (int) AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
   
   if (maxAllowedByBroker == 0)
      return(true);//0 = no limnit
      
   //Check for exceeding the limit
   if ((OrdersTotal() + noOfTrades) > maxAllowedByBroker)
      return(false);
      
   //Got here, so okay to send the order(s)
   return(true);      

}//End bool checkBrokerMaxTradesOnPlatform(int noOfTrades)


bool isTradingAllowed(string symbol, int pairIndex)
{
   //Returns false if any of the filters should cancel trading, else returns true to allow trading.
   //This function is applied to individual trades and to trades within the rolling grid. This
   //may prevent a full rolling grid from being sent.

   //Max trades allowed by broker check.
   if (!checkBrokerMaxTradesOnPlatform(1) )
      return(false);

   
   getBasics(symbol);
   
   
   if (buySignal[pairIndex] )
   {
      //Min distance between trades check.
      //Not used yet but leav in place for possible use later.
      //if (!checkDistanceBetweenTrades(symbol, ask, OP_BUY))
        // return(false);
      //User choice of direction. Function returns 'true' if the pair is in the sell only list
      if (biggerPictureSellOnlyPairs(symbol) )
         return(false);   
   }//if (buySignal[pairIndex])
   
   if (sellSignal[pairIndex])
   {
      //Min distance between trades check
      //if (!checkDistanceBetweenTrades(symbol, bid, OP_SELL))
        // return(false);
      //User choice of direction. Function returns 'true' if the pair is in the buy only list
      if (biggerPictureBuyOnlyPairs(symbol) )
         return(false);   
   }//if (sellSignal)

      
   //Maximum spread. We do not want any trading operations  during a wide spread period
   if (!spreadCheck(pairIndex) ) 
      return(false);
   
   //Margin level
   if (!closeEnough(AccountMargin(), 0) )
   {
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < DeletePendingsBelowThisMarginLevelPercent || ml < CloseDeleteAllBelowThisMarginLevelPercent)
         return(false);   
   }//if (!closeEnough(AccountMargin(), 0) )
   
    
   //An individual currency can only be traded twice, so check for this
   canTradeThisPair = true;
   if (OnlyTradeCurrencyTwice && openTrades > 0)
   {
      isThisPairTradable(symbol);      
   }//if (OnlyTradeCurrencyTwice)
   if (!canTradeThisPair) return(false);
   
   //Order close time safety feature
   if (tooClose(symbol)) return(false);

   //Swap filter
   if (openTrades == 0) tradeDirectionBySwap(symbol);
   
   return(true);


}//End bool isTradingAllowed()

bool isThisPairTradable(string symbol)
{
   //Checks to see if either of the currencies in the pair is already being traded twice.
   //If not, then return true to show that the pair can be traded, else return false
   
   string c1 = stringSubstrOld(symbol, 0, 3);//First currency in the pair
   string c2 = stringSubstrOld(symbol, 3, 3);//Second currency in the pair
   int c1open = 0, c2open = 0;
   canTradeThisPair = true;
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!betterOrderSelect(cc, SELECT_BY_POS) ) continue;
////////if (OrderSymbol() != symbol ) continue;
      if (OrderSymbol() == symbol ) continue;//We can allow multiple trades on the same symbol
      if (OrderMagicNumber() != MagicNumber) continue;
      int index = StringFind(OrderSymbol(), c1);
      if (index > -1)
      {
         c1open++;         
      }//if (index > -1)
   
      index = StringFind(OrderSymbol(), c2);
      if (index > -1)
      {
         c2open++;         
      }//if (index > -1)
   
////////if (c1open == 1 && c2open == 1) 
      if (c1open > 1 || c2open > 1) 
      {
         canTradeThisPair = false;
         return(false);   
      }//if (c1open > 1 || c2open > 1) 
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so ok to trade
   return(true);
   
}//End bool isThisPairTradable()

void tradeDirectionBySwap(string symbol)
{

   //Sets tradeLong & tradeShort according to the positive/negative swap it attracts

   //Swap is read in init() and whenever getBasics() is called
   
   getBasics(symbol);

   tradeLong = true;
   tradeShort = true;
   
   if (CadPairsPositiveOnly)
   {
      if (stringSubstrOld(symbol, 0, 3) == "CAD" || stringSubstrOld(symbol, 0, 3) == "cad" || stringSubstrOld(symbol, 3, 3) == "CAD" || stringSubstrOld(symbol, 3, 3) == "cad" )      
      {
         if (!closeEnough(longSwap, 0) && longSwap > 0) tradeLong = true;
         else tradeLong = false;
         if (!closeEnough(shortSwap, 0) && shortSwap > 0) tradeShort = true;
         else tradeShort = false;         
      }//if (stringSubstrOld()      
   }//if (CadPairsPositiveOnly)
   
   if (AudPairsPositiveOnly)
   {
      if (stringSubstrOld(symbol, 0, 3) == "AUD" || stringSubstrOld(symbol, 0, 3) == "aud" || stringSubstrOld(symbol, 3, 3) == "AUD" || stringSubstrOld(symbol, 3, 3) == "aud" )      
      {
         if (!closeEnough(longSwap, 0) && longSwap > 0) tradeLong = true;
         else tradeLong = false;
         if (!closeEnough(shortSwap, 0) && shortSwap > 0) tradeShort = true;
         else tradeShort = false;         
      }//if (stringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   
   if (NzdPairsPositiveOnly)
   {
      if (stringSubstrOld(symbol, 0, 3) == "NZD" || stringSubstrOld(symbol, 0, 3) == "nzd" || stringSubstrOld(symbol, 3, 3) == "NZD" || stringSubstrOld(symbol, 3, 3) == "nzd" )      
      {
         if (!closeEnough(longSwap, 0) && longSwap > 0) tradeLong = true;
         else tradeLong = false;
         if (!closeEnough(shortSwap, 0) && shortSwap > 0) tradeShort = true;
         else tradeShort = false;         
      }//if (stringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   //OnlyTradePositiveSwap filter
   if (OnlyTradePositiveSwap)
   {
      if (!closeEnough(longSwap, 0) && longSwap <= 0) tradeLong = false;
      if (!closeEnough(shortSwap, 0) && shortSwap <= 0) tradeShort = false;      
   }//if (OnlyTradePositiveSwap)
   
   //MaximumAcceptableNegativeSwap filter
   if (longSwap < MaximumAcceptableNegativeSwap) tradeLong = false;
   if (shortSwap < MaximumAcceptableNegativeSwap) tradeShort = false;      

   //Buy/sell only pairs.
   //Must not be in the sell only list
   if (checkSellOnlyPairs(symbol) )
      tradeLong = false;

   //Must not be in the buy only list
   if (checkBuyOnlyPairs(symbol) )
      tradeShort = false;

}//void tradeDirectionBySwap()

bool checkSellOnlyPairs(string symbol)
{
   //Returns 'true' if the pair is in the SellOnlyPairs list
   //else returns 'false'

   //No pairs in the list
   if (SellOnlyPairs == "")
      return(false);

   for (int cc = 0; cc < noOfSellOnlyPairs; cc++)
   {
      if (sellOnlyPairs[cc] == symbol)
         return(true);
   }//for (int cc = 0; cc < noOfSellOnlyPairs; cc++)
   
   
   //Got this far, so the pair is not in the list
   return(false);

}//bool checkSellOnlyPairs(string symbol)

bool checkBuyOnlyPairs(string symbol)
{
   //Returns 'true' if the pair is in the BuyOnlyPairs list
   //else returns 'false'

   //No pairs in the list
   if (BuyOnlyPairs == "")
      return(false);

   for (int cc = 0; cc < noOfBuyOnlyPairs; cc++)
   {
      if (buyOnlyPairs[cc] == symbol)
         return(true);
   }//for (int cc = 0; cc < noOfBuyOnlyPairs; cc++)
   
   
   //Got this far, so the pair is not in the list
   return(false);

}//bool checkBuyOnlyPairs(string symbol)

bool tooClose(string symbol)
{
   //Returns false if the previously closed trade and the proposed new trade are sufficiently far apart, else return true. Called from IsTradeAllowed().
   
   if (OrdersHistoryTotal() == 0) return(false);
   
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!betterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderType() > 1) continue;
      
      
      //Examine the OrderCloseTime to see if it closed far enought back in time.
      if (TimeCurrent() - OrderCloseTime() < (MinMinutesBetweenTrades * 60))
      {
         return(true);//Too close, so disallow the trade
      }//if (OrderCloseTime() - TimeCurrent() < (MinMinutesBetweenTrades * 60))
      break;      
   }//for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   
   //Got this far, so there is no disqualifying trade in the history
   return(false);
   
}//bool tooClose()

void runningSpreadCalculation(string symbol, int pairIndex)
{
   //Keeps a running total of each pair's average spread
 
   //Has there been a new tick since the last OnTimer() event?
   if (!closeEnough(spreadArray[pairIndex][previousask], ask) )
   {
      //Yes, so update the counters
      spreadArray[pairIndex][previousask] = ask;//Store the latest quote
      
      if (spread > spreadArray[pairIndex][biggestspread])
         spreadArray[pairIndex][biggestspread] = spread;//Reset the biggest spread
         
      spreadArray[pairIndex][spreadtotalsofar]+= spread;//Add the spread to the total of spreads
      spreadArray[pairIndex][tickscounted]++;//Update the spread calculation tick counter
      
      //Do we need to update the average spread?
      if (spreadArray[pairIndex][tickscounted] >= 5)
      {
         spreadArray[pairIndex][averagespread] = spreadArray[pairIndex][spreadtotalsofar] / 5;
         spreadArray[pairIndex][tickscounted] = 0;
         spreadArray[pairIndex][spreadtotalsofar] = 0;
         spreadGvName = symbol + " average spread";
         GlobalVariableSet(spreadGvName, spreadArray[pairIndex][averagespread]);
      }//if (spreadArray[pairIndex][tickscounted] >= 5)
      
      spreadArray[pairIndex][longtermspreadtotalsofar]+= spread;//Add the spread to the total of spreads
      spreadArray[pairIndex][longtermtickscounted]++;//Update the spread calculation tick counter
      
      //Do we need to update the longterm spread
      if (spreadArray[pairIndex][longtermtickscounted] >= 200)
      {
         spreadArray[pairIndex][longtermspread] = spreadArray[pairIndex][longtermspreadtotalsofar] / 200;
         spreadArray[pairIndex][longtermtickscounted] = 0;
         spreadArray[pairIndex][longtermspreadtotalsofar] = 0;
         spreadGvName = symbol + " longterm spread";
         GlobalVariableSet(spreadGvName, spreadArray[pairIndex][longtermspread]);
      }//if (spreadArray[pairIndex][tickscounted] >= 5)
      
         
   }//if (!closeEnough(spreadArray[pairIndex][previousask]), ask)
   

}//End void runningSpreadCalculation(int pairIndex)

bool spreadCheck(int pairIndex)
{
   //Returns 'false' if the check fails, else returns 'true'
   
   //Craptesting
   if (IsTesting() )
      return(true);//Spread is not relevant
      
   
   if (spread >= (MathMax(spreadArray[pairIndex][averagespread],0.1) * MultiplierToDetectStopHunt) )
      return(false);
   
   //Got this far, so ok to continue
   return(true);

}//End bool spreadCheck(int pairIndex)

void countOpenTrades(string symbol, int pairIndex)
{
   //Not all these will be needed. Which ones are depends on the individual EA.
   //Market Buy trades
   buyOpen=false;
   marketBuysCount=0;
   latestBuyPrice=0; earliestBuyPrice=0; highestBuyPrice=0; lowestBuyPrice=million;
   buyTicketNo=-1; highestbuyTicketNo=-1; lowestbuyTicketNo=-1; latestbuyTicketNo=-1; earliestbuyTicketNo=-1;
   latestBuytradeTime=0;
   earliestBuytradeTime=TimeCurrent();
   
   //Market Sell trades
   sellOpen=false;
   marketSellsCount=0;
   latestSellPrice=0; earliestSellPrice=0; highestSellPrice=0; lowestSellPrice=million;
   SellTicketNo=-1; highestSellTicketNo=-1; lowestSellTicketNo=-1; latestSellTicketNo=-1; earliestSellTicketNo=-1;;
   latestSelltradeTime=0;
   earliestSelltradeTime=TimeCurrent();
   
   //BuyStop trades
   buyStopOpen=false;
   buyStopsCount=0;
   latestBuyStopPrice=0; earliestBuyStopPrice=0; highestBuyStopPrice=0; lowestBuyStopPrice=million;
   buyStopTicketNo=-1; highestbuyStopTicketNo=-1; lowestbuyStopTicketNo=-1; latestbuyStopTicketNo=-1; earliestbuyStopTicketNo=-1;;
   latestBuyStoptradeTime=0;
   earliestBuyStoptradeTime=TimeCurrent();
   
   //BuyLimit trades
   buyLimitOpen=false;
   buyLimitsCount=0;
   latestBuyLimitPrice=0; earliestBuyLimitPrice=0; highestBuyLimitPrice=0; lowestBuyLimitPrice=million;
   buyLimitTicketNo=-1; highestBuyLimitTicketNo=-1; lowestBuyLimitTicketNo=-1; latestBuyLimitTicketNo=-1; earliestBuyLimitTicketNo=-1;;
   latestBuyLimittradeTime=0;
   earliestBuyLimittradeTime=TimeCurrent();
   
   /////SellStop trades
   sellStopOpen=false;
   sellStopsCount=0;
   latestSellStopPrice=0; earliestSellStopPrice=0; highestSellStopPrice=0; lowestSellStopPrice=million;
   sellStopTicketNo=-1; highestSellStopTicketNo=-1; lowestSellStopTicketNo=-1; latestSellStopTicketNo=-1; earliestSellStopTicketNo=-1;;
   latestSellStoptradeTime=0;
   earliestSellStoptradeTime=TimeCurrent();
   
   //SellLimit trades
   sellLimitOpen=false;
   sellLimitsCount=0;
   latestSellLimitPrice=0; earliestSellLimitPrice=0; highestSellLimitPrice=0; lowestSellLimitPrice=million;
   sellLimitTicketNo=-1; highestSellLimitTicketNo=-1; lowestSellLimitTicketNo=-1; latestSellLimitTicketNo=-1; earliestSellLimitTicketNo=-1;;
   latestSellLimittradeTime=0;
   earliestSellLimittradeTime=TimeCurrent();
   
   //Not related to specific order types
   marketTradesTotal = 0;
   pendingTradesTotal = 0;
   ticketNo=-1;openTrades=0;
   latesttradeTime=0; earliesttradeTime=TimeCurrent();//More specific times are in each individual section
   latestTradeTicketNo=-1; earliestTradeTicketNo=-1;
   pipsUpl[pairIndex]=0;//For keeping track of the pips pipsUpl of multi-trade/hedged positions
   cashUpl[pairIndex]=0;//For keeping track of the cash pipsUpl of multi-trade/hedged positions
   buyCashUpl[pairIndex] = 0;//Individual pairs
   sellCashUpl[pairIndex] = 0;//Individual pairs
   
   //Recovery
   ArrayResize(buyTickets, 0);
   ArrayInitialize(buyTickets, 0);
   ArrayResize(sellTickets, 0);
   ArrayInitialize(sellTickets, 0);
   buysInRecovery = false; sellsInRecovery = false;
   int BuyLoser = 0, SellLoser = 0;//For working out if the position is in Recovery.

   double pips = 0; 
   
   int type;//Saves the OrderType() for consulatation later in the function
   
   
   if (OrdersTotal() == 0) return;
   
   //Iterating backwards through the orders list caters more easily for closed trades than iterating forwards
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!betterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;

      
      //Ensure the EA 'owns' this trade
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      if (OrderSymbol() != symbol ) continue;
      
      //The time of the most recent trade
      if (OrderOpenTime() > latesttradeTime)
      {
         latesttradeTime = OrderOpenTime();
         latestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() > latesttradeTime)
      
      //The time of the earliest trade
      if (OrderOpenTime() < earliesttradeTime)
      {
         earliesttradeTime = OrderOpenTime();
         earliestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() < earliesttradeTime)
      
      //All conditions passed, so carry on
      type = OrderType();//Store the order type
      
      
      openTrades++;
      //Store the latest trade sent. Most of my EA's only need this final ticket number as either they are single trade
      //bots or the last trade in the sequence is the important one. Adapt this code for your own use.
      if (ticketNo  == -1) ticketNo = OrderTicket();
      
      
      
      //The next line of code calculates the pips upl of an open trade. As yet, I have done nothing with it.
      //something = calculateTradeProfitInPips()
      
      
      
      //Build up the position picture of market trades
      if (OrderType() < 2)
      {
         getBasics(OrderSymbol() );
         pips = calculateTradeProfitInPips(OrderType());
         pipsUpl[pairIndex]+= pips;
         cashUpl[pairIndex]+= (OrderProfit() + OrderSwap() + OrderCommission()); 
         marketTradesTotal++;

         
         //Buys
         if (OrderType() == OP_BUY)
         {
            buyOpen = true;
            buyTicketNo = OrderTicket();
            marketBuysCount++;
            buyCashUpl[pairIndex]+= (OrderProfit() + OrderSwap() + OrderCommission()); 
            
            //Recovery
            ArrayResize(buyTickets, marketBuysCount + 1);
            buyTickets[marketBuysCount] = OrderTicket();
            //In case the position needs Recovery
            if ( (OrderProfit() + OrderSwap() + OrderCommission()) < 0 )
               BuyLoser++;
             
            //latest trade
            if (OrderOpenTime() > latestBuytradeTime)
            {
               latestBuytradeTime = OrderOpenTime();
               latestBuyPrice = OrderOpenPrice();
               latestbuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() > latestBuytradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < earliestBuytradeTime)
            {
               earliestBuytradeTime = OrderOpenTime();
               earliestBuyPrice = OrderOpenPrice();
               earliestbuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() < earliestBuytradeTime)
            
            //highest trade price
            if (OrderOpenPrice() > highestBuyPrice)
            {
               highestBuyPrice = OrderOpenPrice();
               highestbuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > highestBuyPrice)
            
            //lowest trade price
            if (OrderOpenPrice() < lowestBuyPrice)
            {
               lowestBuyPrice = OrderOpenPrice();
               lowestbuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > lowestBuyPrice)
              
         }//if (OrderType() == OP_BUY)
         
         //Sells
         if (OrderType() == OP_SELL)
         {
            sellOpen = true;
            SellTicketNo = OrderTicket();
            marketSellsCount++;
            sellCashUpl[pairIndex]+= (OrderProfit() + OrderSwap() + OrderCommission()); 
            
            //Recovery
            ArrayResize(sellTickets, marketSellsCount + 1);
            sellTickets[marketSellsCount] = OrderTicket();
            //In case the position needs Recovery
            if ( (OrderProfit() + OrderSwap() + OrderCommission()) < 0 )
               SellLoser++;
            
            //latest trade
            if (OrderOpenTime() > latestSelltradeTime)
            {
               latestSelltradeTime = OrderOpenTime();
               latestSellPrice = OrderOpenPrice();
               latestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() > latestSelltradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < earliestSelltradeTime)
            {
               earliestSelltradeTime = OrderOpenTime();
               earliestSellPrice = OrderOpenPrice();
               earliestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() < earliestSelltradeTime)
            
            //highest trade price
            if (OrderOpenPrice() > highestSellPrice)
            {
               highestSellPrice = OrderOpenPrice();
               highestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > highestSellPrice)
            
            //lowest trade price
            if (OrderOpenPrice() < lowestSellPrice)
            {
               lowestSellPrice = OrderOpenPrice();
               lowestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > lowestSellPrice)
              
         }//if (OrderType() == OP_SELL)
         
         
      }//if (OrderType() < 2)
      
      
      //Build up the position details of stop/limit orders
      if (OrderType() > 1)
      {
         pendingTradesTotal++;

         
         //Buystops
         if (OrderType() == OP_BUYSTOP)
         {
            buyStopOpen = true;
            buyStopTicketNo = OrderTicket();
            buyStopsCount++;
            
            //latest trade
            if (OrderOpenTime() > latestBuyStoptradeTime)
            {
               latestBuyStoptradeTime = OrderOpenTime();
               latestBuyStopPrice = OrderOpenPrice();
               latestbuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > latestBuyStoptradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < earliestBuyStoptradeTime)
            {
               earliestBuyStoptradeTime = OrderOpenTime();
               earliestBuyStopPrice = OrderOpenPrice();
               earliestbuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < earliestBuyStoptradeTime)
            
            //highest trade price
            if (OrderOpenPrice() > highestBuyStopPrice)
            {
               highestBuyStopPrice = OrderOpenPrice();
               highestbuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > highestBuyStopPrice)
            
            //lowest trade price
            if (OrderOpenPrice() < lowestBuyStopPrice)
            {
               lowestBuyStopPrice = OrderOpenPrice();
               lowestbuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > lowestBuyStopPrice)
              
         }//if (OrderType() == OP_BUYSTOP)
         
         //Sellstops
         if (OrderType() == OP_SELLSTOP)
         {
            sellStopOpen = true;
            sellStopTicketNo = OrderTicket();
            sellStopsCount++;
            
            //latest trade
            if (OrderOpenTime() > latestSellStoptradeTime)
            {
               latestSellStoptradeTime = OrderOpenTime();
               latestSellStopPrice = OrderOpenPrice();
               latestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > latestSellStoptradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < earliestSellStoptradeTime)
            {
               earliestSellStoptradeTime = OrderOpenTime();
               earliestSellStopPrice = OrderOpenPrice();
               earliestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < earliestSellStoptradeTime)
            
            //highest trade price
            if (OrderOpenPrice() > highestSellStopPrice)
            {
               highestSellStopPrice = OrderOpenPrice();
               highestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > highestSellStopPrice)
            
            //lowest trade price
            if (OrderOpenPrice() < lowestSellStopPrice)
            {
               lowestSellStopPrice = OrderOpenPrice();
               lowestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > lowestSellStopPrice)
              
         }//if (OrderType() == OP_SELLSTOP)
         
         //Buy limits
         if (OrderType() == OP_BUYLIMIT)
         {
            buyLimitOpen = true;
            buyLimitTicketNo = OrderTicket();
            buyLimitsCount++;
            
            //latest trade
            if (OrderOpenTime() > latestBuyLimittradeTime)
            {
               latestBuyLimittradeTime = OrderOpenTime();
               latestBuyLimitPrice = OrderOpenPrice();
               latestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > latestBuyLimittradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < earliestBuyLimittradeTime)
            {
               earliestBuyLimittradeTime = OrderOpenTime();
               earliestBuyLimitPrice = OrderOpenPrice();
               earliestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < earliestBuyLimittradeTime)
            
            //highest trade price
            if (OrderOpenPrice() > highestBuyLimitPrice)
            {
               highestBuyLimitPrice = OrderOpenPrice();
               highestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > highestBuyLimitPrice)
            
            //lowest trade price
            if (OrderOpenPrice() < lowestBuyLimitPrice)
            {
               lowestBuyLimitPrice = OrderOpenPrice();
               lowestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > lowestBuyLimitPrice)
              
         }//if (OrderType() == OP_BUYLIMIT)
         
         //Sell limits
         if (OrderType() == OP_SELLLIMIT)
         {
            sellLimitOpen = true;
            sellLimitTicketNo = OrderTicket();
            sellLimitsCount++;
            
            //latest trade
            if (OrderOpenTime() > latestSellLimittradeTime)
            {
               latestSellLimittradeTime = OrderOpenTime();
               latestSellLimitPrice = OrderOpenPrice();
               latestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > latestSellLimittradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < earliestSellLimittradeTime)
            {
               earliestSellLimittradeTime = OrderOpenTime();
               earliestSellLimitPrice = OrderOpenPrice();
               earliestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < earliestSellLimittradeTime)
            
            //highest trade price
            if (OrderOpenPrice() > highestSellLimitPrice)
            {
               highestSellLimitPrice = OrderOpenPrice();
               highestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > highestSellLimitPrice)
            
            //lowest trade price
            if (OrderOpenPrice() < lowestSellLimitPrice)
            {
               lowestSellLimitPrice = OrderOpenPrice();
               lowestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > lowestSellLimitPrice)
              
         }//if (OrderType() == OP_SELLLIMIT)
         
      
      }//if (OrderType() > 1)
      
      
      //Maximum spread. We do not want any trading operations  during a wide spread period
      if (!spreadCheck(pairIndex) ) 
         continue;
      
      
      if (closeEnough(OrderStopLoss(), 0) && !closeEnough(stopLoss, 0)) insertStopLoss(OrderTicket());
      if (closeEnough(OrderTakeProfit(), 0) && !closeEnough(takeProfit, 0)) insertTakeProfit(OrderTicket() );
      
      
      TradeWasClosed = false;
      if (!areWeAtRollover())
         TradeWasClosed = lookForTradeClosure(OrderTicket(), pairIndex);
      if (TradeWasClosed) 
      {
         if (type == OP_BUY) buyOpen = false;//Will be reset if subsequent trades are buys that are not closed
         if (type == OP_SELL) sellOpen = false;//Will be reset if subsequent trades are sells that are not closed
         cc++;
         continue;
      }//if (TradeWasClosed)

      //Profitable trade management
      if (OrderProfit() > 0) 
      {
         tradeManagementModule(OrderTicket() );
      }//if (OrderProfit() > 0) 
      
      //Scale out stop loss. The function is in Slopey Peaky Bob.mqh
      if (OrderType() < 2)
      {
         if (UseScaleOutStopLoss)
            if (scaleOutStopLoss(OrderTicket()) )
            {
               cc = OrdersTotal();//Restart the loop as the original ticket number has changed
            }//if (scaleOutStopLoss(OrderTicket()) )
         
         //Hidden sltp without scale back in
         if (HideStopLossAndTakeProfit)
            if (!UseScaleBackIn)
               if (lookForTradeClosure(OrderTicket(), pairIndex) )
                  cc++;
            
         //Scale back in sltp correction
         //Hidden sltp with scale back in
         if (HideStopLossAndTakeProfit)
            if (UseScaleBackIn)
            {
               if (hasScaleInTradeHitSlTP(OrderTicket(), symbol) )
               {
                  cc++;
                  continue;
               }//if (hasScaleInTradeHitSlTP(OrderTicket(), symbol) )
            
            }//if (UseScaleBackIn)
               
         
         
         
      }//if (OrderType() < 2)
      
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
   //Are we in Recovery?
   if (UseRecovery)
   {
      if (marketBuysCount >= TradesToStartLookingForRecovery)//Minimum trades to constitute Recovery
         if (BuyLoser >= MinimumLosersToTriggerRecovery)//Minimum must be losers or we do not need Recovery
            buysInRecovery = true;
            
      if (marketSellsCount >= TradesToStartLookingForRecovery)//Minimum trades to constitute Recovery
         if (SellLoser >= MinimumLosersToTriggerRecovery)//Minimum must be losers or we do not need Recovery
            sellsInRecovery = true;
            
   }//if (UseRecovery[index] )

   //Scale back in sltp correction
   //Scaling back in will leave stop orders behind if a trade hits SL,
   //so they need deleting.
   if (UseScaleBackIn)
   {
      if (buyStopOpen)
         if (marketBuysCount == 0)
            deleteOrphanedStopOrders(symbol, OP_BUYSTOP, pairIndex);
   
      if (sellStopOpen)
         if (marketSellsCount == 0)
            deleteOrphanedStopOrders(symbol, OP_SELLSTOP, pairIndex);
   
   }//if (UseScaleBackIn)
   
   //Scale back in sltp correction
   //There are global variables holding the hidden tpsl. Delete them if the orders are no longer open
   //if (UseScaleBackIn)
     // if (HideStopLossAndTakeProfit)
         if (openTrades == 0)
         {
            string gvFileName = symbol + stopLossGvName;
            if (GlobalVariableCheck(gvFileName) )
               GlobalVariableDel(gvFileName);
               
            gvFileName = symbol + takeProfitGvName;
            if (GlobalVariableCheck(gvFileName) )
               GlobalVariableDel(gvFileName);
         
         }//if (openTrades == 0)



   //Sort the ticket arrays
   if (ArraySize(buyTickets) > 0)
      ArraySort(buyTickets,WHOLE_ARRAY,0,MODE_ASCEND);//We need the buys in ascending order for Recovery 
      
   if (ArraySize(sellTickets) > 0)
      ArraySort(sellTickets,WHOLE_ARRAY,0,MODE_DESCEND);//We need the sells in descending order for Recovery 
      
   
      
}//End void countOpenTrades();
//+------------------------------------------------------------------+

//Scale back in sltp correction
bool hasScaleInTradeHitSlTP(int ticket, string symbol)
{
   //Closes a hidden stops market order if the market has reached the
   //hidden stops.
   //Returns 'true' if there is a successful closure
   //else returns 'false'
   
   //Make sure the order has not already closed
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES) )
      return(false);
      
   double stop = 0, take = 0;   
      
   string gvFileName = symbol + stopLossGvName; 
   if (GlobalVariableCheck(gvFileName) )
      stop = GlobalVariableGet(gvFileName);
   
   gvFileName = OrderSymbol() + takeProfitGvName;
   if (GlobalVariableCheck(gvFileName) )
      take = GlobalVariableGet(gvFileName);
   
   bool closeTrade = false;
   
   getBasics(symbol);
   
   //Buy order
   if (OrderType() == OP_BUY)
   {
      //Check TP
      if (!closeEnough(take, 0) )
         if (bid >= take)
            closeTrade = true;
            
      //Check SL
      if (!closeTrade)
         if (!closeEnough(stop, 0) )
            if (bid <= stop)
               closeTrade = true;
   
   }//if (OrderType() == OP_BUY)
   
   //Sell order
   if (OrderType() == OP_SELL)
   {
      //Check TP
      if (!closeEnough(take, 0) )
         if (ask <= take)
            closeTrade = true;
         
      //Check SL
      if (!closeTrade)
         if (!closeEnough(stop, 0) )
            if (bid >= stop)
               closeTrade = true;
   
   }//if (OrderType() == OP_SELL)
   
   //Should the trade be closed
   if (closeTrade)
   {
      bool result = closeOrder(ticket);
      if (result)
         return(true);
   
   }//if (closeTrade)
   

   //Got this far, so no order closure
   return(false);

}//End bool hasScaleInTradeHitSlTP(int ticket, string symbol)



void deleteOrphanedStopOrders(string symbol, int type, int pairIndex)
{

   //This function deletes pending orders when they are no longer required  
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!betterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;

      
      //Ensure the EA 'owns' this trade
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() != type) continue; 
      if (OrderSymbol() != symbol ) continue;

      bool result = OrderDelete(OrderTicket(), clrNONE);
      if (result)
      {
         cc++;
      }//if (result)

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   
   //Rebuild a picture of the position
   countOpenTrades(symbol, pairIndex);
   
}//Endvoid deleteOrphanedStopOrders(string symbol, int type, int pairIndex)



//This code by tomele. Thank you Thomas. Wonderful stuff.
bool areWeAtRollover()
{

   double time;
   int hours,minutes,rstart,rend,ltime;
   
   time=StrToDouble(RollOverStarts);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rstart=60*hours+minutes;
      
   time=StrToDouble(RollOverEnds);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rend=60*hours+minutes;
   
   ltime=TimeHour(TimeCurrent())*60+TimeMinute(TimeCurrent());

   if (rend>rstart)
     if(ltime>=rstart && ltime<rend)
       return(true);
   if (rend<rstart) //Over midnight
     if(ltime>=rstart || ltime<rend)
       return(true);

   //Got here, so not at rollover
   return(false);

}//End bool areWeAtRollover()



void calculateLotAsAmountPerCashDollops()
{

   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   int decimal = 0;
   if (closeEnough(lotstep, 0.1) )
      decimal = 1;
   if (closeEnough(lotstep, 0.01) )
      decimal = 2;
      
   double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double DoshDollop = AccountInfoDouble(ACCOUNT_BALANCE); 
   
   if (UseEquity)
      DoshDollop = AccountInfoDouble(ACCOUNT_EQUITY); 


   
   //Calculate the no of dollops in DoshDollop
   int NoOfDollops = (int) DoshDollop / SizeOfDollop;


   //Initial lot size
   //This equation provided by DygitalCrypto. Thanks David.
   Lot = NormalizeDouble((MathFloor(((DoshDollop / SizeOfDollop) * LotsPerDollopOfCash) * 100) / 100), decimal);
    
   //Min/max size check
   if (Lot > maxlot)
      Lot = maxlot;
      
   if (Lot < minlot)
      Lot = minlot;      

//For testing
//Alert(DoubleToStr(Lot, decimal));


}//void calculateLotAsAmountPerCashDollops()

int extractPairIndexFromOrderSymbol(string symbol)
{

   //Returns the index in the tradePair array that corresponds
   //to the order symbol.
   
   for (int cc = 0; cc < ArraySize(tradePair); cc++)
   {
      if (tradePair[cc] == symbol)
         return(cc);   
   }//for (int cc = 0; cc < ArraySize(tradePair) - 1; cc++)
   
   
   //Symbol not found, so return a dummy
   return(-1);

}//End int extractPairIndexFromOrderSymbol(string symbol)


void countTotalsForDisplay()
{
   //Makes a tally of all trades belonging to the EA, regardless of their order symbol

   totalPipsUpl = 0;
   totalCashUpl = 0;
   totalOpenTrades = 0;
   
   ArrayInitialize(buyTradeTotals, 0);
   ArrayInitialize(sellTradeTotals, 0);

   //FIFO ticket resize
   ArrayFree(fifoTicket);

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      //Ensure the trade is still open
      if (!betterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;

      
      //Ensure the EA 'owns' this trade
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
      //Store ticket numbers for FIFO.
      //This is here so that it can be used to close trades FIFO
      //in basket equity closure
      ArrayResize(fifoTicket, totalOpenTrades + 1);
      fifoTicket[totalOpenTrades] = OrderTicket();

      getBasics(OrderSymbol());
      
      double pips = calculateTradeProfitInPips(OrderType() );

      totalPipsUpl+= pips;
      double profit = (OrderProfit() + OrderSwap() + OrderCommission()); 
      totalCashUpl+= profit;
      totalOpenTrades++;
      
      double swap = OrderSwap();

      //Total cash/pips for chart display
      int pairIndex = extractPairIndexFromOrderSymbol(OrderSymbol() );
      if (pairIndex == -1)
         continue;//Something is wrong
         
      if (OrderType() == OP_BUY)
      {
         buyTradeTotals[pairIndex][pipst]+= pips;
         buyTradeTotals[pairIndex][casht]+= profit;
         buyTradeTotals[pairIndex][swapt]+= swap;
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL)
      {
         sellTradeTotals[pairIndex][pipst]+= pips;
         sellTradeTotals[pairIndex][casht]+= profit;
         sellTradeTotals[pairIndex][swapt]+= swap;
      }//if (OrderType() == OP_SELL)
      
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   //Sort ticket numbers for FIFO
   if (ArraySize(fifoTicket) > 0)
      ArraySort(fifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);

}//End void countTotalsForDisplay()




void updateTradeArrows()
{
   //No update cycle
   if(timerCount>0)
      return;
      
   //Cycle through charts
   long nextchart=ChartFirst();
   do
   {
      string symbol=ChartSymbol(nextchart);
      if(symbol!=ReservedPair && nextchart!=ChartID())
         drawTradeArrows(symbol,nextchart);
   }
   while((nextchart=ChartNext(nextchart))!=-1);
   
   return;
}//void updateTradearrows()


void calculateClosedProfits()
{
   //Adds up all the closed trades in the history tab.
   
   totalClosedCashPl = 0;
   totalClosedPipsPl = 0;
   totalClosedTrades = 0;
   winners = 0;
   losers = 0;
   
   ArrayInitialize(closedBuyTradeTotals, 0);
   ArrayInitialize(closedSellTradeTotals, 0);

   if (OrdersHistoryTotal() == 0)
      return;
      
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!betterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() < 0 || OrderType() > 1) continue;
      if (OrderCloseTime() == 0) continue; 
      
      totalClosedTrades++;
      
      getBasics(OrderSymbol());

      double profit = OrderSwap() + OrderCommission() + OrderProfit();
      if (profit > 0)
         winners++;
      else
         losers++;
         
      totalClosedCashPl += profit;
      
      double pips=0;
      if (OrderType() == OP_BUY)
         pips = ( OrderClosePrice() - OrderOpenPrice() ) * factor;
      if (OrderType() == OP_SELL)
         pips = ( OrderOpenPrice() - OrderClosePrice() ) * factor;
         
      totalClosedPipsPl += pips;
      
      double swap=OrderSwap();

      //Total cash/pips for chart display
      int pairIndex = extractPairIndexFromOrderSymbol(OrderSymbol() );
      if (pairIndex == -1)
         continue;//Something is wrong
         
      if (OrderType() == OP_BUY)
      {
         closedBuyTradeTotals[pairIndex][pipst]+= pips;
         closedBuyTradeTotals[pairIndex][casht]+= profit;
         closedBuyTradeTotals[pairIndex][swapt]+= swap;
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL)
      {
         closedSellTradeTotals[pairIndex][pipst]+= pips;
         closedSellTradeTotals[pairIndex][casht]+= profit;
         closedSellTradeTotals[pairIndex][swapt]+= swap;
      }//if (OrderType() == OP_SELL)
   }//for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)

}//End void calculateClosedProfits()

bool canIndividualPairBasketBeClosed(string symbol, int pairIndex)
{

/*
extern bool    UseAtrForBasketTP=false;
extern ENUM_TIMEFRAMES TpAtrTimeFrame=PERIOD_H4;
extern double  TpPercentOfAtrToUse=100;
extern int     TpAtrPeriod=14;
*/


   //Using ATR for individual pairs as a basket TP
   if (UseAtrForBasketTP)
   {
      double atrVal = getAtr(symbol, TpAtrTimeFrame, TpAtrPeriod, 0);
      IndividualBasketTargetPips = (int) ((atrVal * factor) * (TpPercentOfAtrToUse / 100) );
   }//if (UseAtrForBasketTP)
   

   //Pips target
   if (IndividualBasketTargetPips > 0)
      if (pipsUpl[pairIndex] >= IndividualBasketTargetPips)
      {
         deletePendings = true;
         closeAllTrades(symbol, AllTrades);
         if (forceTradeClosure)
         {
            closeAllTrades(symbol, AllTrades);
            if (forceTradeClosure)
            {
               closeAllTrades(symbol, AllTrades);
               if (forceTradeClosure)
               {
                  return(false);
               }//if (forceTradeClosure)                     
            }//if (forceTradeClosure)         
         }//if (forceTradeClosure)    
         
         if (!forceTradeClosure)
            return(true);//Closure target reached and closure successful
      }//if (pipsUpl >= IndividualBasketTargetPips)
   
      
   //Cash target
   if (!closeEnough(IndividualBasketTargetCash,0) )
   {
      if (UseDynamicCashTPIndividualPair) 
      {
         IndividualBasketTargetCash = NormalizeDouble(CashTakeProfitIndividualePairPerLot * Lot, 2);
      } // if (UseDynamicCashTPIndividualPair) 
      if (cashUpl[pairIndex] >= IndividualBasketTargetCash)
      {
         deletePendings = true;
         closeAllTrades(symbol, AllTrades);
         if (forceTradeClosure)
         {
            closeAllTrades(symbol, AllTrades);
            if (forceTradeClosure)
            {
               closeAllTrades(symbol, AllTrades);
               if (forceTradeClosure)
               {
                  return(false);
               }//if (forceTradeClosure)                     
            }//if (forceTradeClosure)         
         }//if (forceTradeClosure)    
         
         if (!forceTradeClosure)
            return(true);//Closure target reached and closure successful
      }//if (cashUpl[pairIndex] >= IndividualBasketTargetCash)
   }//if (!closeEnough(IndividualBasketTargetCash,0) )
   
   
      

   //Got here, so no closure or closure part-failed
   return(false);

}//bool canIndividualPairBasketBeClosed(string symbol, int pairIndex)

bool canEntirePositionClose()
{

 
   //Calculate the trail as a percentage of balance
   if (UseBasketTrailingStopPercentage)
      if (closeEnough(BasketTrailingStopStartValueCash, 0) )
      {
         BasketTrailingStopStartValueCash = (AccountBalance() * BasketTrailingStopStartValuePercent) / 100;
         BasketTrailingStopgapValueCash = (AccountBalance() * BasketTrailingStopgapValuePercent) / 100;    
      }//if (closeEnough(BasketTrailingStopStartValueCash, 0) )
      
   
   //Basket cash trailing stop.
   //The basket trailing stop feature was added by 1of3. Fabulous contributin John; many thanks.
   if(TreatAllPairsAsBasket && (UseBasketTrailingStopCash || UseBasketTrailingStopPercentage) )
   {
      if(bTSActivatedCash)
      {
         if(totalCashUpl > bTSHighValueCash)
         {
            bTSHighValueCash = totalCashUpl;
            bTSStopLossCash = NormalizeDouble(bTSHighValueCash - BasketTrailingStopgapValueCash, 2);
         }//if(totalCashUpl > bTSHighValueCash)

         if(totalCashUpl <= bTSStopLossCash)
         {
            bTSActivatedCash=false;
            Print("Basket stopLoss closing trades at "+DoubleToStr(totalCashUpl,2)+". highest Value:"+DoubleToStr(bTSHighValueCash,2)+" initial Basket SL Value £"+DoubleToStr(bTSStopLossCash,2));
            bTSHighValueCash = 0;
            bTSStopLossCash = 0;
            closeAllTrades(AllSymbols, AllTrades);
            if (forceTradeClosure)
            {
               closeAllTrades(AllSymbols, AllTrades);
               //Addition to John's code
               GlobalVariableDel(bTSTrailingStopCashGV);
               if (forceTradeClosure)
               {
                  closeAllTrades(AllSymbols, AllTrades);
                  if (forceTradeClosure)
                  {
                     forceWholePositionClosure = true;
                     return(false);
                  }//if (forceTradeClosure)
               }//if (forceTradeClosure)
            }//if (forceTradeClosure)

            if (!forceTradeClosure)
               return(true);//Closure target reached and closure successful
         }//if(totalCashUpl <= bTSStopLossCash)
      }//if(bTSActivatedCash)
      else
      {
         if (!closeEnough(BasketTrailingStopStartValueCash,0) )
            if (totalCashUpl >= BasketTrailingStopStartValueCash)
            {
               bTSHighValueCash = totalCashUpl;
               bTSStopLossCash = NormalizeDouble(totalCashUpl - BasketTrailingStopgapValueCash, 2);
               bTSActivatedCash = true;
               Print("Basket cash stopLoss Triggered at £"+DoubleToStr(totalCashUpl,2)+". High Value:£"+DoubleToStr(bTSHighValueCash,2)+" initial Basket SL Value £"+DoubleToStr(bTSStopLossCash,2));
               //Addition to John's code
               //Save bTSStopLossCash in a global variable so the trail can resume following a restart.
               GlobalVariableSet(bTSTrailingStopCashGV, bTSStopLossCash);
            }//if (totalCashUpl >= BasketTrailingStopStartValueCash)
      }//else
      //return(false); This would prevent the rest of the function being tested.
   }//if(TreatAllPairsAsBasket && (UseBasketTrailingStopCash || UseBasketTrailingStopPercentage) )


   //Basket pips trailing stop.
   //This is John's code adapted.
   if(TreatAllPairsAsBasket && UseBaskettrailingStopPips)
   {
      if(bTSActivatedPips)
      {
         if(totalPipsUpl > bTSHighValuePips)
         {
            bTSHighValuePips = totalPipsUpl;
            bTSStopLossPips = NormalizeDouble(bTSHighValuePips - BasketTrailingStopgapValuePips, 0);
         }//if(totalPipsUpl > bTSHighValuePips)

         if(totalPipsUpl <= bTSStopLossPips)
         {
            bTSActivatedPips=false;
            Print("Basket pips stopLoss closing trades at "+DoubleToStr(totalPipsUpl,0)+". highest Value:"
            +DoubleToStr(bTSHighValuePips,0)+" initial Basket SL Value £"+DoubleToStr(bTSStopLossPips,0));
            bTSHighValuePips = 0;
            bTSStopLossPips = 0;
            closeAllTrades(AllSymbols, AllTrades);
               //Addition to John's code
               GlobalVariableDel(bTStrailingStopPipsGV);
            if (forceTradeClosure)
            {
               closeAllTrades(AllSymbols, AllTrades);
               if (forceTradeClosure)
               {
                  closeAllTrades(AllSymbols, AllTrades);
                  if (forceTradeClosure)
                  {
                     forceWholePositionClosure = true;
                     return(false);
                  }//if (forceTradeClosure)
               }//if (forceTradeClosure)
            }//if (forceTradeClosure)

            if (!forceTradeClosure)
               return(true);//Closure target reached and closure successful
         }//if(totalPipsUpl <= bTSStopLossPips)
      }//if(bTSActivatedPips)
      else
      {
         if (BasketTrailingStopStartValuePips > 0 )
            if (totalPipsUpl >= BasketTrailingStopStartValuePips)
            {
               bTSHighValuePips = totalPipsUpl;
               bTSStopLossPips = NormalizeDouble(totalPipsUpl - BasketTrailingStopgapValuePips, 0);
               bTSActivatedPips = true;
               Print("Basket pips stopLoss Triggered at £"+DoubleToStr(totalPipsUpl,0)+". High Value: "
                     +DoubleToStr(bTSHighValuePips,0)+" initial Basket SL Value £"+DoubleToStr(bTSStopLossPips,0));
               //Addition to John's code
               //Save bTSStopLossPips in a global variable so the trail can resume following a restart.
               GlobalVariableSet(bTStrailingStopPipsGV, bTSStopLossPips);
            }//if (totalPipsUpl >= BasketTrailingStopStartValuePips)
      }//else
      //return(false); This would prevent the rest of the function being tested.
   }//if(TreatAllPairsAsBasket && UseBaskettrailingStopPips)



   //Pips target
   if (BasketTargetPips > 0)
      if (totalPipsUpl >= BasketTargetPips)
      {
         closeAllTrades(AllSymbols, AllTrades);
         if (forceTradeClosure)
         {
            closeAllTrades(AllSymbols, AllTrades);
            if (forceTradeClosure)
            {
               closeAllTrades(AllSymbols, AllTrades);
               if (forceTradeClosure)
               {
                  return(false);
               }//if (forceTradeClosure)                     
            }//if (forceTradeClosure)         
         }//if (forceTradeClosure)    
         
         if (!forceTradeClosure)
            return(true);//Closure target reached and closure successful
      }//if (totalPipsUpl >= BasketTargetPips)
   
      
   //Cash target
   if (!closeEnough(BasketTargetCash,0) )
      if (totalCashUpl >= BasketTargetCash)
      {
         closeAllTrades(AllSymbols, AllTrades);
         if (forceTradeClosure)
         {
            closeAllTrades(AllSymbols, AllTrades);
            if (forceTradeClosure)
            {
               closeAllTrades(AllSymbols, AllTrades);
               if (forceTradeClosure)
               {
                  return(false);
               }//if (forceTradeClosure)                     
            }//if (forceTradeClosure)         
         }//if (forceTradeClosure)    
         
         if (!forceTradeClosure)
            return(true);//Closure target reached and closure successful
      }//if (totalCashUpl >= BasketTargetCash)

   //Got this far, so no closure or closure part-failed
   return(false);

}//End bool canEntirePositionClose()

void canPendingsBeDeleted()
{
   //Delete pendings that are not yet part of a market position
   //if the margin level drops below our minimum. This function 
   //is called if the margin level has dropped below this minimum.
   
   for (int pairIndex = 0; pairIndex < ArraySize(tradePair); pairIndex++)
   {
      string symbol = tradePair[pairIndex];
      getBasics(symbol);
      countOpenTrades(symbol, pairIndex);
      
      //Only delete the pendings if there are no market trades already open
      if (marketTradesTotal == 0)
         if (pendingTradesTotal > 0)//and there are still pending orders
            closeAllTrades(symbol, AllTrades);
            
      
   }//for (int pairIndex = 0; pairIndex < ArraySize(tradePair); pairIndex++)
   
   
}//End void canPendingsBeDeleted()

void calculateDynamicBasketCashTP(double lots)
{

   //Calculates a basket cash TB calculated by lot size
   
   BasketTargetCash = NormalizeDouble(CashTakeProfitPerLot * lots, 2);

}//End void calculateDynamicBasketCashTP(double lots)

//Trading done for the week stuff
void haveWeDoneForTheWeek()
{

   //Examine all market trades closed this week and set doneForTheWeek accordingly.
   
   doneForTheWeek = false;
   
   closedTradesCash = 0;
   closedTradesPips = 0;
   
   //Are we at our target day?
   if (TimeDayOfWeek(TimeLocal() ) < TargetDay)
      return;
      
   //Nothing to do if there are no trades in the history tab.
   if (OrdersHistoryTotal() == 0)
      return;
   
   //Calculate the targets
   double CashSlippage = 0, PipsSlippage = 0;

   //Cash target
   if (UseDynamicWeeklyTargetCash)
   {
      WeeklyCashTarget = (int) BasketTargetCash * WeeklyTargetBasketTpMultiplier;
      CashSlippage = WeeklyCashTarget * (SlippageTolerancePercent / 100);
   }//if (UseDynamicWeeklyTargetCash)
   
   //Pips target
   if (UseDynamicWeeklyTargetPips)
   {
      WeeklyPipsTarget = BasketTargetPips * WeeklyTargetBasketTpMultiplier;
      PipsSlippage = WeeklyPipsTarget * (SlippageTolerancePercent / 100);
   }//if (UseDynamicWeeklyTargetPips)
   
   //Cycle through the trades in our history tab to make the calculations
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!betterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if (OrderType() > 1)
         continue;//We are not interested an stop orders.
      if (OrderMagicNumber() != MagicNumber)
         continue;
      if (OrderCloseTime() < iTime(OrderSymbol(), PERIOD_W1, 0) )
         continue;//Needs to have closed this week
            
      //Update the running totals
      if (WeeklyCashTarget > 0)
         closedTradesCash+= (OrderProfit() + OrderSwap() + OrderCommission() );         
   
      if (WeeklyPipsTarget > 0)
      {
         getBasics(OrderSymbol() );//We need to know the factor
         double pips = MathAbs(OrderOpenPrice() - OrderClosePrice() );
         pips*= factor;
         closedTradesPips+= pips;
      }//if (WeeklyPipsTarget > 0)
      
   }//for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)

   
   //Can we stop for the week?
   //Cash target
   if (WeeklyCashTarget > 0)
      if (closedTradesCash >= (WeeklyCashTarget - CashSlippage) )
         doneForTheWeek = true;
         
   if (WeeklyPipsTarget > 0)
      if (closedTradesPips >= (WeeklyPipsTarget - PipsSlippage) )
         doneForTheWeek = true;
         
   //Set the global variable if we have reached our profit target
   if (doneForTheWeek)
   {         
      GlobalVariableSet(DoneForTheWeekGV, iTime(Symbol(), PERIOD_W1, 0));
   }//if (doneForTheWeek)
   

}//End void haveWeDoneForTheWeek()

void setFridayBasketTP()
{
//This function added by John (SHF 1of3). Thanks John.
   ushort u_sep=StringGetCharacter(",",0);
   string resultc[];
   string resultp[];
   int tc=StringSplit(BasketFridayCashTargets,u_sep,resultc);
   int tp=StringSplit(BasketFridayPipsTargets,u_sep,resultp);
   bool houractive=false;
   int d = TimeDayOfWeek(TimeLocal());
   int h = TimeHour(TimeLocal());
   
   if (d==5||d==6)
   {
      if(tc>0)
      {
         double ttc=BasketTargetCash;
         for(int i=0;i<tc;i++)
         {
            if((i % 2) == 1)
            {
               if(houractive == true)
               {
                  ttc = StrToDouble(resultc[i]);
                  houractive=false;
               }
            }
            else
            {
              if(h>=StrToDouble(resultc[i])) houractive=true;
            }
         }
         if(BasketTargetCash!=ttc) BasketTargetCash = ttc;
     }
     if(tp>0)
     {
         houractive=false;
         double ttp=BasketTargetPips;
         for(int i=0;i<tp;i++)
         {
            if((i % 2) == 1)
            {
               if(houractive == true)
               {
                  ttp = (int) StrToDouble(resultp[i]);
                  houractive=false;
               }
            }
            else
            {
              if(h>=StrToDouble(resultp[i])) houractive=true;
            }
         }
         if(BasketTargetPips!=ttp) BasketTargetPips = (int) ttp;
     }
   }
   else
   {
      BasketTargetCash = originalBasketTargetCash;//reset on sunday
      BasketTargetPips = (int) originalBasketTargetPips;//reset on sunday
   }
}//End void setFridayBasketTP()

bool shirtProtection()
{
   
   if (closeEnough(AccountMargin(), 0) )
      return(false);//No margin being used, so nothing to do.
      
   if (OrdersTotal() == 0)
      return(false);   
      
   if (totalOpenTrades == 0)//Counted in countTotalsForDisplay()
      return(false);   
   
   //Calculate the current margin level percent
   double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
         
   //Delete all outstanding pending orders if the margin level drops below
   //our comfort zone.
   if (DeletePendingsBelowThisMarginLevelPercent > 0)
   {
      if (ml < DeletePendingsBelowThisMarginLevelPercent)
      {
         closeAllTrades(AllSymbols, OP_BUYSTOP);
         closeAllTrades(AllSymbols, OP_SELLSTOP);
         return(true);            
      }//if (ml < DeletePendingsBelowThisMarginLevelPercent)
   }//if (DeletePendingsBelowThisMarginLevelPercent > 0)
   

   //Close the entire position if we are in danger of a margin call.
   if (CloseDeleteAllBelowThisMarginLevelPercent > 0)
   {
      if (ml < CloseDeleteAllBelowThisMarginLevelPercent)
      {
         closeAllTrades(AllSymbols, AllTrades);
         if (forceWholePositionClosure)
         {
            closeAllTrades(AllSymbols, AllTrades);
            if (forceWholePositionClosure)
            {
               closeAllTrades(AllSymbols, AllTrades);
               if (forceWholePositionClosure)
               {
                  return(true);//Still failed, so try again at the next timer event
               }//if (forceWholePositionClosure)                     
            }//if (forceWholePositionClosure)  
            forceWholePositionClosure = false;//Closure succeeded      
            return(true); 
         }//if (forceWholePositionClosure)    
      }//if (ml < CloseDeleteAllBelowThisMarginLevelPercent)
   }//if (CloseDeleteAllBelowThisMarginLevelPercent > 0)

   //Got here, so no closures
   return(false);
   
}//void shirtProtection()

bool haveWeHitRecoveryTarget(string symbol, int type, int pairIndex)
{
   //Calculate the Recovery target and close the trades if the target price is reached.
   //I am not sure that we need separate buy and sell routines but they 
   //were a part of the original (faulty) code, so I leave them in place in case
   //this construct proves useful in the future.
   
   //getBasics(symbol);//Probably not needed, but no harm to check.
   
   double recoveryTarget = RecoveryProfitCash;
   
   if (type == OP_BUY)
   {
      
      //Has the market reached this target? Using bid because buys close at the Bid
      if (buyCashUpl[pairIndex] >= recoveryTarget)
         return(true);
   
   }//if (type == OP_BUY)

   if (type == OP_SELL)
   {
      //Has the market reached this target? Using bid because buys close at the Bid
      if (sellCashUpl[pairIndex] >= recoveryTarget)
         return(true);
 
   }//if (type == OP_SELL)
   

   //Got this far, so no closure
   return(false);

}//bool haveWeHitRecoveryTarget(string symbol, int type)

void doRollingGridStuff(string symbol, int pairIndex)
{

   //Margin level check
   if (!marginCheck() )
      return;
   
 
   getBasics(symbol);
   
   //Make the peaky status equation easier to read
   string ps = untradable;
   if (peakyStatus[pairIndex] == peakylongtradable || peakyStatus[pairIndex] == peakylonguntradable)
      ps = tradablelong;
   if (peakyStatus[pairIndex] == peakyshorttradable || peakyStatus[pairIndex] == peakyshortuntradable)
      ps = tradableshort;
   
   //Rolling grid.
   if (RollingGrid)//Are we using this feature?
      if (isTradingAllowed(symbol, pairIndex) )//Make sure there is nothing to stop us trading eg spread
         if (marketTradesTotal > 0)//There are open trades
            if (marketTradesTotal + GridSize <= (MaxRolledTrades - GridSize) )//A new grid will not exceed our maximum allowed
            {   
               //Buy grid
               if (buyOpen && ps == tradablelong)//There are market buy trades and peaky has not changed direction
                  if (!UseHtfSs || !HtfDeletePendingTradesOnOppositeSignal || htfSsStatus[pairIndex] == blue)
                     if (!UseMtfSs || !MtfDeletePendingTradesOnOppositeSignal || mtfSsStatus[pairIndex] == blue)
                        if (!UseLtfSs || !LtfDeletePendingTradesOnOppositeSignal || ltfSsStatus[pairIndex] == blue)
                           if (buyStopsCount == 0)
                           {
                              sendBuyGrid(symbol, OP_BUYSTOP, ask, Lot, TradeComment); 
                           }//if (buyStopsCount == 0)
                        
               //Sell grid
               if (sellOpen && ps == tradableshort)//There are market sell trades and peaky has not changed direction
                  if (!UseHtfSs || !HtfDeletePendingTradesOnOppositeSignal || htfSsStatus[pairIndex] == red)
                     if (!UseMtfSs || !MtfDeletePendingTradesOnOppositeSignal || mtfSsStatus[pairIndex] == red)
                        if (!UseLtfSs || !LtfDeletePendingTradesOnOppositeSignal || ltfSsStatus[pairIndex] == red)
                           if (sellStopsCount == 0)
                           {
                              sendSellGrid(symbol, OP_SELLSTOP, bid, Lot, TradeComment); 
                           }//if (sellStopsCount == 0)
               
            }//if (marketTradesTotal + GridSize <= MaxRolledTrades)//A new grid will not exceed our maximum allowed

}//End void doRollingGridStuff(string symbol, int pairIndex)

void doRollingGridClosure(string symbol, int pairIndex)
{

   int type = OP_BUY;
   if (sellOpen)
      type = OP_SELL;
   
   canWeCloseTheRollingGrid(symbol, pairIndex, type);

}//void doRollingGridClosure(string symbol, int pairIndex)


void canWeCloseTheRollingGrid(string symbol, int pairIndex, int type)
{
   //Close a rolling grid when the market reaches MaxRolledTrades + distanceBetweenTrades
   
   if (marketTradesTotal < MaxRolledTrades)
      return;//Nothing to do
   
   getBasics(symbol);
      
   //Buy grid
   if (type == OP_BUY)
   {
      if (bid >= (highestBuyPrice + (distanceBetweenTrades / factor) ) )
      {
         closeAllTrades(symbol, OP_BUY);
         return;
      }//if (bid >= (highestBuyPrice + (distanceBetweenTrades / factor) ) )
   }//if (type == OP_BUY)
   
   //Sell grid
   if (type == OP_SELL)
   {
      if (ask <= (lowestSellPrice - (distanceBetweenTrades / factor) ) )
      {
         closeAllTrades(symbol, AllTrades);
         return;
      }//if (ask <= (lowestSellPrice - (distanceBetweenTrades / factor) ) )
   }//if (type == OP_SELL)
   
   
}//End void canWeCloseTheRollingGrid(string symbol, int pairIndex, int type)

void doRecoveryClosure(string symbol, int pairIndex)
{

         if (buysInRecovery)
            if (haveWeHitRecoveryTarget(symbol, OP_BUY, pairIndex) )
            {
               deletePendings = true;
               Alert(symbol, " ", TradeComment, " buy trades Recovery target reached. All ", symbol, " ", 
                     TradeComment, " buy trades should have closed.");
               closeAllTrades(symbol, AllTrades);
               if (forceTradeClosure)//In case a trade close/delete failed
               {
                  closeAllTrades(symbol, AllTrades);
                  if (forceTradeClosure)
                  {
                     closeAllTrades(symbol, AllTrades);
                     if (forceTradeClosure)
                     {
                        closeAllTrades(symbol, AllTrades);
                        if (forceTradeClosure)
                        {
                           Alert(symbol, " Magic number ", IntegerToString(MagicNumber), " Order comment ", 
                                 TradeComment, " buy trades Recovery profit target hit but trades failed to close.");
                        }//if (forceTradeClosure)                        
                     }//if (forceTradeClosure)                     
                  }//if (forceTradeClosure)         
               }//if (forceTradeClosure)      
               
               //Re-build a picture of the trade position.
               countOpenTrades(symbol, pairIndex);
      
            }//if (HaveWeHitRecoveryTarget() )
            
         if (sellsInRecovery)
            if (haveWeHitRecoveryTarget(symbol, OP_SELL, pairIndex) )
            {
               deletePendings = true;
               Alert(symbol, " ", TradeComment, " sell trades Recovery target reached. All ", symbol, " ", 
                     TradeComment, " sell trades should have closed.");
               closeAllTrades(symbol, AllTrades);
               if (forceTradeClosure)//In case a trade close/delete failed
               {
                  closeAllTrades(symbol, AllTrades);
                  if (forceTradeClosure)
                  {
                     closeAllTrades(symbol, AllTrades);
                     if (forceTradeClosure)
                     {
                        closeAllTrades(symbol, AllTrades);
                        if (forceTradeClosure)
                        {
                           Alert(symbol, " Magic number ", IntegerToString(MagicNumber), " Order comment ", 
                                 TradeComment, " sell trades Recovery profit target hit but trades failed to close.");
                        }//if (forceTradeClosure)                        
                     }//if (forceTradeClosure)                     
                  }//if (forceTradeClosure)         
               }//if (forceTradeClosure)      
               
               //Re-build a picture of the trade position.
               countOpenTrades(symbol, pairIndex);
               
            }//if (HaveWeHitRecoveryTarget() )
                           


}//End void doRecoveryClosure(string symbol, int pairIndex)


double getDifferentialLotSize(string symbol)
{

   //Returns a lot size that will ensure that pips movements will
   //generate equal profits/losses across all pairs.
   //This is a hack of Rene' code at http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?p=167116#p167116 - no 
   //idea how he came up with the calculation.
   //Thanks Rene. You are a star as well as a genius.
   
   lotSizeMultiplier = 1.0;
   
   double lotSize = Lot;
   double dailyATR = 0;
   string atrSymbol = "";
   
   int    numATR = 0;
   double totalATRProfit = 0.0;

   //Calculate the average daily ATR of all pairs
   for (int pairIndex = 0; pairIndex < ArraySize(tradePair); pairIndex++)
   {
      atrSymbol = tradePair[pairIndex];
      getBasics(atrSymbol);//We need factor
      
      dailyATR = iATR( atrSymbol, PERIOD_D1, AtrPeriod, 1 );
      if ( !closeEnough(dailyATR, 0 ) )// Only add to totalATRProfit if dailyATR > 0.0
      {                   
         totalATRProfit += dailyATR * factor * MarketInfo( atrSymbol, MODE_TICKVALUE );
         numATR++;
      }//if ( !closeEnough(dailyATR, 0 )
   }//for (int pairIndex = 0; pairIndex < ArraySize(tradePair); pairIndex++) 
   
   //Calculate the lot size multiplier. 
   if ( numATR > 0 ) 
   {
      getBasics(symbol);
      dailyATR = iATR( symbol, PERIOD_D1, AtrPeriod, 1 );
      double averageATR = totalATRProfit / numATR;
      if ( !closeEnough(dailyATR, 0 ) )
            lotSizeMultiplier = averageATR / ( dailyATR * factor * MarketInfo( symbol, MODE_TICKVALUE ) );

   }//if ( numATR > 0 )   


   //Calculate the decimal points for the NormalizeDouble()
   int decimal = 1;
   if (MarketInfo(symbol, MODE_LOTSTEP) == 0.1 )
      decimal = 1;
   if (MarketInfo(symbol, MODE_LOTSTEP) == 0.01 )
      decimal = 2;
   if (MarketInfo(symbol, MODE_LOTSTEP) == 0.001 )
      decimal = 3;
   
   //Lot size calculation
   lotSize = NormalizeDouble((lotSize * lotSizeMultiplier), decimal );
      
   //Min/max checks
   if ( lotSize < MarketInfo( symbol, MODE_MINLOT ) ) 
   {
      lotSize = MarketInfo( symbol, MODE_MINLOT );
   }//if ( lotSize < MarketInfo( symbol, MODE_MINLOT ) )
   
   if ( lotSize > MarketInfo( symbol, MODE_MAXLOT ) ) 
   {
      lotSize = MarketInfo( symbol, MODE_MAXLOT );
   }//if ( lotSize > MarketInfo( symbol, MODE_MAXLOT ) ) 
   
   
   
   return(lotSize);

}//End double getDifferentialLotSize(string symbol)

bool scaleOutStopLoss(int ticket)
{

   /*
   Called from countOpenTrades()
   
   This function examines an open trade to see if the phased stop loss should be used.
   Returns 'true' if there is a part-closure, else false.
   
   This cannot be applied to hedged trades.
   
   The function also handles scaling back in
   */
   
   //Check the order is still open
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return(false);
      
   //Cannot work this function if there is no stop loss
   //if (closeEnough(OrderStopLoss(), 0) ) 
   //   return(false); 

   //Save stuff for easier typing
   int type = OrderType();
   string symbol = OrderSymbol();
   double price = OrderOpenPrice();
   double stop = OrderStopLoss();
   double take = OrderTakeProfit();
   
   if (HideStopLossAndTakeProfit)
      stop = calculateStopLoss(type, price);
      
   getBasics(symbol);//Always good to include this in a function

   //No further action needed if the trade is in profit
   if (type == OP_BUY)
      if (bid > price)
      {
         return(false);
      }//if (bid > price)
      
   if (type == OP_SELL)
      if (ask < price)
      {
         return(false);
      }//if (ask < price)
      
   
   //We have a trade and it is a loser. Calculate the distance
   //in between the order open price and the stop loss. The order open price
   //does not change following a partial closure. Not when tested on a GP demo, at least. Fuck
   //only knows what happens with the criminal element masquerading as 'brokers'.
   double slpips = MathAbs(price - stop);
   //Calculate the sl levels at which to partially close the trade.
   double slLevel = slpips / NoOfLevels;
   
   //A variable to tell the code that part-closure is needed.
   bool closeNeeded = false;
   //A variable to hold the calculated price at each level.
   double calculatedLevel = price;
   //A variable to hold the amount to part-close
   double lotsToClose = normalizeLots(symbol, Lot / NoOfLevels);
   //Alert(lotsToClose);
   double targetLots = 0;
   
   //Loop through the levels and set the closeNeeded bool if the market has moved to
   //the calculatedLevel price
   for (int cc = 1; cc <= NoOfLevels; cc++)
   {
            
      //Buy trade
      if (type == OP_BUY)
      {
         //The trade is losing by at least one level
         calculatedLevel-= slLevel;
         if (bid <= calculatedLevel)
         {
            //We need to know if there has already been a partial close at this stop level
            targetLots = Lot - (lotsToClose * cc);            
            if (OrderLots() > targetLots)
            {
               closeNeeded = true;
               break;
            }//if (OrderLots() > targetLots)
               
         }//if (bid <= calculatedLevel)
            
      }//if (type == OP_BUY)
      
      
      //Sell trade
      if (type == OP_SELL)
      {
         //The trade is losing by at least one level
         calculatedLevel+= slLevel;
         if (ask >= calculatedLevel)
         {
            //We need to know if there has already been a partial close at this stop level
            targetLots = Lot - (lotsToClose * cc);            
            if (OrderLots() > targetLots)
            {
               closeNeeded = true;
               break;
            }//if (OrderLots() > targetLots)
         }//if (ask <= calculatedLevel)
            
      }//if (type == OP_SELL)
      
      
      //Alert(calculatedLevel);
   }//for (int cc = 1; cc <= NoOfLevels; cc++)
   
   //Should part of the trade be closed:
   if (closeNeeded)
   {
      bool result = OrderClose(ticket, lotsToClose, OrderClosePrice(), 5, clrNONE);
      if (result)
      {
         //Replace the trade with a stop order if scaling back in
         if (UseScaleBackIn)
         {
            int tries = 0;//To exit an endless loop because something went wrong
            double newPrice = 0;
            if (HideStopLossAndTakeProfit)
            {
               stop = 0;
               take = 0;
            }//if (HideStopLossAndTakeProfit)
               

            //Buy stop
            if (type == OP_BUY)
            {
               //Calculate the price for the stop order
               newPrice = NormalizeDouble(calculatedLevel + slLevel, digits);
               
               //We must have the order sent
               result = false;
               while (!result)
               {
                  if (IsTradeContextBusy() )
                     Sleep(2000);

                  result = sendSingleTrade(symbol, OP_BUYSTOP, ScaleBackInTradeComment, lotsToClose, newPrice, stop, take);
                  
                  //Exit an endless loop if something went wrong
                  if (!result)
                  {
                     tries++;
                     if (tries >= 100)
                        break;
                     Sleep(1000);   
                  }//if (!result)
               }//while (!result)
            }//if (type == OP_BUY)
            
         
            //Sell stop
            if (type == OP_SELL)
            {
               //Calculate the price for the stop order
               newPrice = NormalizeDouble(calculatedLevel - slLevel, digits);

               //We must have the order sent
               result = false;
               while (!result)
               {
                  if (IsTradeContextBusy() )
                     Sleep(2000);

                  result = sendSingleTrade(symbol, OP_SELLSTOP, ScaleBackInTradeComment, lotsToClose, newPrice, stop, take);
                  //Exit an endless loop if something went wrong
                  if (!result)
                  {
                     tries++;
                     if (tries >= 100)
                        break;
                     Sleep(1000);   
                  }//if (!result)
               }//while (!result)
            }//if (type == OP_SELL)
            
         
         }//if (UseScaleBackIn)
         
         
         return(true);
      }//if (result)
      
   }//if (closeNeeded)
   

   //Got here, so no closure
   return(false);

}//End bool scaleOutStopLoss(int ticket)



