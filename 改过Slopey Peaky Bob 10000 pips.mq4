//+------------------------------------------------------------------+
//|                                             Slopey Peaky Bob.mq4 |
//|                                                 Steve and Tomele |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property strict
#define version "Version 1o"

/*
The dashboard code is provided by Thomas. Thanks Thomas; you are a star. 
This EA is Thomas' dashboard with automated 
trading added by me. 

*/

//#include <WinUser32.mqh>
#include <stdlib.mqh>

//Code to minimise charts provided by Rene. Many thanks again, Rene.
#import "user32.dll"
int GetParent(int hWnd);
bool ShowWindow(int hWnd, int nCmdShow);
#import

#define  AllTrades 10 //Tells CloseAllTrades() to close/delete everything belonging to the passed symbol
#define  AllSymbols "All symbols"//Tells CloseAllTrades() to close/delete everything on the platform, regardless of pair
#define  million 1000000;
//Define the FifoBuy/SellTicket fields for offsetting
#define  TradeTicket 1

#define  SW_FORCEMINIMIZE   11
#define  SW_MAXIMIZE         3

#define  up "Up"
#define  down "Down"
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



string  cau="---- Chart automation ----";
//These inputs tell the ea to automate opening/closing of charts and
//what to load onto them
bool             AutomateChartOpeningAndClosing      =false;
bool             MinimiseChartsAfterOpening          =false;
string           ReservedPair                        ="XAUUSD";
string           TemplateName                        ="SPB";
string           tra                                 ="-- Trade arrows --";
bool             DrawTradeArrows                     = True;
ArrowPlaces      WhereToDrawArrows                   = CandleHighLow;
color            TradeLongColor                      = Blue;
color            TradeShortColor                     = Blue;
int              TradeArrowSize                      = 5;
string           lin                                 ="-- Trade lines --";
bool             DrawTradeLines                      = True;
LineColoring     HowToColorLines                     = LongShort;
color            TradeLineLongOrProfitableColor      = Lime;
color            TradeLineShortOrUnprofitableColor   = Red;
int              TradeLineSize                       = 1;
ENUM_LINE_STYLE  TradeLineStyle                      = STYLE_DOT;

string           s1="================================================================";
string           oad               ="---- Other stuff ----";
string           PairsToTrade   = "AUDCAD,AUDCHF,AUDNZD,AUDJPY,AUDUSD,CADCHF,CADJPY,CHFJPY,EURAUD,EURCAD,EURCHF,EURGBP,EURNZD,EURJPY,EURUSD,GBPCHF,GBPJPY,GBPUSD,NZDUSD,NZDJPY,USDCAD,USDCHF,USDJPY";
ENUM_TIMEFRAMES  ChartTimeFrame=PERIOD_H1;
int              EventTimerIntervalSeconds=1;
int              ChartCloseTimerMultiple=15;
bool             WriteFileForTestDatabase=false;
////////////////////////////////////////////////////////////////////////////////
int            NoOfPairs;// Holds the number of pairs passed by the user via the inputs screen
string         TradePair[]; //Array to hold the pairs traded by the user
datetime       ttfCandleTime[];
double         ask=0, bid=0, spread=0;//Replaces Ask. Bid, Digits. factor replaces Point
int            digits;//Replaces Digits.
double         longSwap=0, shortSwap=0;
int            OpenLongTrades=0, OpenShortTrades=0;
int            ClosedLongTrades=0, ClosedShortTrades=0;
bool           BuySignal[], SellSignal[];
string         TradingTimeFrameDisplay="";
int            TimerCount=0;//Count timer events for closing charts
bool           ForceTradeClosure=false;
datetime       OldHtfIndiReadBarTime[];//Read the indis at the open of each HTF bar
datetime       OldTtfIndiReadBarTime[];//Read the indis at the open of each trading time frame bar
double         BuyTradeTotals[][3];//Total pips and cash for each pair's buy trades
double         SellTradeTotals[][3];//Total pips and cash for each pair's sell trades
double         ClosedBuyTradeTotals[][3];//Total pips and cash for each pair's closed buy trades
double         ClosedSellTradeTotals[][3];//Total pips and cash for each pair's closed sell trades
//Variables for closed trades
int            Winners=0, Losers=0;
double         ClosedPipsPL=0, ClosedCashPL=0;
////////////////////////////////////////////////////////////////////////////////

string  tsep1="================================================================";
string  tsep2="================================================================";
string  tsep3="================================================================";
string  aut="---- Using the dashboard as an auto-trader ----";
bool    AutoTradingEnabled=true;
//One for our friends in the US
bool    MustObeyFIFO=false;
extern  double  Lot=0.1;
//Set RiskPercent to zero to disable and use Lot
double  RiskPercent=0;
//LotsPerDollopOfCash over rides Lot. Zero input to cancel.
double  LotsPerDollopOfCash=0.01;
int     SizeOfDollop=5000;
bool    UseBalance=false;
bool    UseEquity=true;
bool    StopTrading=false;
bool    TradeLong=true;//Not needed as an here
bool    TradeShort=true;//Not needed as an here
int     TakeProfitPips=0;
int     StopLossPips=0;
extern int      MagicNumber=0;
string  TradeComment="SPB 10000";
bool    IsGlobalPrimeOrECNCriminal=false;
int     MaxSlippagePips=5;
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitSeconds seconds, whether OR detects a receipt return or not.
int     PostTradeAttemptWaitSeconds=60;
////////////////////////////////////////////////////////////////////////////////////////
datetime       TimeToStartTrading[];//Re-start calling LookForTradingOpportunities() at this time.
double         TakeProfit, StopLoss;
string         GvName="Under management flag";//The name of the GV that tells the EA not to send trades whilst the manager is closing them.
//'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
string         LocalGvName = "Local closure in operation " + Symbol();
//'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
string         NuclearGvName = "Nuclear option closure in operation " + Symbol();
//For FIFO
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.
//An array to store ticket numbers of trades that need closing, should an offsetting OrderClose fail
int            ForceCloseTickets[];
bool           RemoveExpert=false;
double         MinDistanceBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////

string  sep1a="================================================================";
string  ssl="---- Trend time frame Super Slope ----";
 bool    TakeTrendTrades=true;
ENUM_TIMEFRAMES HtfSsTimeFrame=PERIOD_D1;
double  HtfSsDifferenceThreshold  = 1.0;
 double  HtfSsLevelCrossValue      = 2.0;
int     HtfSsSlopeMAPeriod        = 7; 
int     HtfSsSlopeATRPeriod       = 50; 
string  cch="-- Colour change --";
bool    CloseMarketTradesOnOppositeSignal=false;
bool    DeletePendingTradesOnOppositeSignal=true;
////////////////////////////////////////////////////////////////////////////////////////
string         HtfSsStatus[];//Colours defined at top of file
////////////////////////////////////////////////////////////////////////////////////////

string  sep1e="================================================================";
string  pea="---- Peaky inputs ----";
ENUM_TIMEFRAMES PeakyTimeFrame=PERIOD_H1;
int     NoOfBarsOnChart=1682;
////////////////////////////////////////////////////////////////////////////////////////
string         PeakyStatus[];//Up or down 
////////////////////////////////////////////////////////////////////////////////////////

string  sep1b="================================================================";
string  gri="---- Grid inputs ----";
//Send a market trade as soon as there is a signal
bool    SendImmediateMarketTrade=false;
int     GridSize=5;
int     DistanceBetweenTradesPips=50;
bool    UseAtrForGrid=false;
ENUM_TIMEFRAMES GridAtrTimeFrame=PERIOD_D1;
int     GridAtrPeriod=20;
double  GridAtrMultiplier=1;
////////////////////////////////////////////////////////////////////////////////////////
double         DistanceBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////

string  sep1c="================================================================";
string  bas="---- Basket trading ----";
//Pips and cash inputs will not be considered when = 0
string  ind="-- Individual pairs --";
bool    TreatIndividualPairsAsBasket=false;
int     IndividualBasketTargetPips=0;
double  IndividualBasketTargetCash=0;
string  dbi="-- Dynamic individual pair basket take profit --";
//Individual Pair Basket cash TP based on lot size. Lucky64 added this function. Many thanks Luciano.
bool    UseDynamicCashTPIndividualPair=false;
double  CashTakeProfitIndividualePairPerLot=1000;

string  all="-- All trades belong to a single basket --";
bool    TreatAllPairsAsBasket=true;

enum targetPips{tp50=50,tp100=100,tp250=250,tp500=500,tp1000=1000,tp2500=2500,tp5000=5000,tp10000=10000};
extern targetPips BasketTargetPips=10000;

double  BasketTargetCash=0;
string  dbt="-- Dynamic basket take profit --";
//Basket cash TP based on lot size
bool    UseDynamicCashTP=false;
double  CashTakeProfitPerLot=3000;
//The basket trailing stop feature was added by 1of3. Fabulous contributin John; many thanks.
string  dts="-- Basket Trailing Stop --";
bool    UseBasketTrailingStop=false;
double  BasketTrailingStopStartValue=16;
double  BasketTrailingStopGapValue=10;
double BTSStopLoss = 0;// Basket Trailing Stop Stop Loss Monetary Value
double BTSHighValue = 0;// Basket Trailing Stop high money value to drag stop loss up this amount
int BTSActivated = false;//Basket Trailing Stop is currently in operation
//Trailing stop based on a percentage of balance
extern string  pets="-- Basket Percentage of Balance Trailing Stop --";
extern bool    UseBasketTrailingStopPercentage=true;
//The profit percentage of balance to start the trail.
extern double  BasketTrailingStopStartValuePercent=0.5;
//The percentage of balance to use as the trail
extern double  BasketTrailingStopgapValuePercent=0.1;
//No associated variable - use the bTSStopLossCash etc variables
////////////////////////////////////////////////////////////////////////////////////////
bool           ForceWholePositionClosure=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1g="================================================================";
extern string  rec1="---- Recovery ----";
extern bool    UseRecovery=true;
extern int     TradesToStartLookingForRecovery=6;//The number of trades that must be open for Recovery to be needed
extern int     MinimumLosersToTriggerRecovery=2;//The number of losers to try to close out at the breakeven point
extern int     RecoveryProfitCash=10;
////////////////////////////////////////////////////////////////////////////////////////
int            buyTickets[], sellTickets[];
bool           buysInRecovery=false, sellsInRecovery=false;

string  sep1d="================================================================";
string  sfs="----SafetyFeature----";
//Minimum time to pass after a trade closes, until the ea can open another.
int     MinMinutesBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////
bool           SafetyViolation;//For chart display
bool           RobotSuspended=false;
////////////////////////////////////////////////////////////////////////////////////////

string  sep7c="================================================================";
//CheckTradingTimes. Baluda has provided all the code for this. Mny thanks Paul; you are a star.
string  trh            = "----Trading hours----";
string  tr1            = "tradingHours is a comma delimited list";
string  tr1a="of start and stop times.";
string  tr2="Prefix start with '+', stop with '-'";
string  tr2a="Use 24H format, local time.";
string  tr3="Example: '+07.00,-10.30,+14.15,-16.00'";
string  tr3a="Do not leave spaces";
string  tr4="Blank input means 24 hour trading.";
string  tradingHours="";
////////////////////////////////////////////////////////////////////////////////////////
double         TradeTimeOn[];
double         TradeTimeOff[];
// trading hours variables
int            tradeHours[];
string         tradingHoursDisplay;//tradingHours is reduced to "" on initTradingHours, so this variable saves it for screen display.
bool           TradeTimeOk;
////////////////////////////////////////////////////////////////////////////////////////

string  sep1de="================================================================";
string  fssmt="---- Inputs applied to individual days ----";
//Ignore signals at and after this time on Friday.
//Local time input. >23 to disable.
int     FridayStopTradingHour=14;
//Friday time to close all open trades/delete stop orders for the weekend.
//Local time input. >23 to disable.
int     FridayCloseAllHour=24;
//For those in Upside Down Land.  
int     SaturdayStopTradingHour=24;
//For those in Upside Down Land.
//Local time input. >23 to disable.
int     SaturdayCloseAllHour=24;  
//Only close all trades when the negative cash upl is less than this.
//Converted into a negative value in OnInit()
int     MaxAllowableCashLoss=-20;
bool    TradeSundayCandle=false;
//24h local time     
int     MondayStartHour=8;
//Thursday tends to be a reversal day, so avoid it. Not relevant here, so turned off but left in place in case we need it.                         
 bool    TradeThursdayCandle=true;

//This code by tomele. Thank you Thomas. Wonderful stuff.
string  sep7b="================================================================";
string  roll="---- Rollover time ----";
bool    DisableEaDuringRollover=true;
string  ro1 = "Use 24H format, SERVER time.";
string  ro2 = "Example: '23.55'";
string  RollOverStarts="23.55";
string  RollOverEnds="00.15";
////////////////////////////////////////////////////////////////////////////////////////
bool           RolloverInProgress=false;//Tells DisplayUserFeedback() to display the rollover message
////////////////////////////////////////////////////////////////////////////////////////

string  sep8="================================================================";
string  bf="----Trading balance filters----";
bool    UseZeljko=false;
bool    OnlyTradeCurrencyTwice=false;
////////////////////////////////////////////////////////////////////////////////////////
bool           CanTradeThisPair;
////////////////////////////////////////////////////////////////////////////////////////

string  sep9="================================================================";
string  pts="----Swap filter----";
bool    CadPairsPositiveOnly=false;
bool    AudPairsPositiveOnly=false;
bool    NzdPairsPositiveOnly=false;
bool    OnlyTradePositiveSwap=false;
//Rhis next input allows users to trade negative swap pairs but sets a maximum negative swap.
double  MaximumAcceptableNegativeSwap=-1000000;
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

string  sep10="================================================================";
string  amc="----Available Margin checks----";
string  sco="Scoobs";
bool    UseScoobsMarginCheck=false;
string  fk="ForexKiwi";
bool    UseForexKiwi=true;
int     FkMinimumMarginPercent=1000;
////////////////////////////////////////////////////////////////////////////////////////
bool           EnoughMargin;
string         MarginMessage;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1f="================================================================";
extern string  shi="---- Shirt Protection ----";
//This attempts to protect tiny starter accounts from a margin call.
//Delete stop orders when the margin level percent drops below a certain level.
//Use a zero value to disable this feature.
extern int     DeletePendingsBelowThisMarginLevelPercent=300;
//Close the entire position when we are in danger of a margin call.
//Zero value to disable this.
extern int     CloseDeleteAllBelowThisMarginLevelPercent=125;
////////////////////////////////////////////////////////////////////////////////////////

string  sep11="================================================================";
string  asi="----Average spread inputs----";
bool    RunInSpreadDetectionMode=false;
//The ticks to count whilst canculating the av spread
//int     TicksToCount=5;
double  MultiplierToDetectStopHunt=10;
////////////////////////////////////////////////////////////////////////////////////////
double         SpreadArray[][9];
string         SpreadGvName;//A GV will hold the calculated average spread
////////////////////////////////////////////////////////////////////////////////////////

string  sep13="================================================================";
string  tmm="----Trade management module----";
//Breakeven has to be enabled for JS and TS to work.
string  BE="Break even settings";
bool    BreakEven=true;
int     BreakEvenTargetPips=15;
int     BreakEvenTargetProfit=5;
bool    PartCloseEnabled=false;
//Percentage of the trade lots to close
double  PartClosePercent=50;
////////////////////////////////////////////////////////////////////////////////////////
double         BreakEvenPips,BreakEvenProfit;
bool           TradeHasPartClosed=false;
////////////////////////////////////////////////////////////////////////////////////////

string  sep14="================================================================";
string  JSL="Jumping stop loss settings";
bool    JumpingStop=true;
int     JumpingStopTargetPips=2;
////////////////////////////////////////////////////////////////////////////////////////
double         JumpingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

string  sep15="================================================================";
string  cts="----Candlestick jumping stop----";
bool    UseCandlestickTrailingStop=false;
//Defaults to current chart
int     CstTimeFrame=0;
//Defaults to previous candle
int     CstTrailCandles=1;
bool    TrailMustLockInProfit=true;
////////////////////////////////////////////////////////////////////////////////////////
int            OldCstBars;//For candlestick ts
////////////////////////////////////////////////////////////////////////////////////////

string  sep16="================================================================";
string  TSL="Trailing stop loss settings";
bool    TrailingStop=false;
int     TrailingStopTargetPips=20;
////////////////////////////////////////////////////////////////////////////////////////
double         TrailingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

string  sep17="================================================================";
//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
string  chf               ="---- Chart feedback display ----";
int     ChartRefreshDelaySeconds=0;
// if using Comments
int     DisplayGapSize    = 30; 
// ****************************** added to make screen Text more readable
// replaces Comment() with OBJ_LABEL text
bool    DisplayAsText     = true;  
//Disable the chart in foreground CrapTx setting so the candles do not obscure the textbool    KeepTextOnTop     = true;
extern int     DisplayX          = 50;
extern int     DisplayY          = 0;
extern double  ScaleX            = 1.0;
extern double  ScaleY            = 1.0;
extern int     fontSize          = 10;
string  fontName          = "Arial";
color   colour            = Yellow;

string  dad               ="---- Dashboard display ----";

extern bool    HidePipsDetails  = false;
extern bool    HideCashDetails  = false;
extern bool    HideSwapDetails  = false;
extern bool    HideSpreadDetails= false;

color   UpSignalColor    = Lime;
color   DnSignalColor    = Red;
color   NoSignalColor    = Silver;
color   ButtonColor      = Cyan;

string  cdb               ="---- Alternative multi-color dashboard ----";
bool    ColoredDashboard = true;
//Values below are only applicated if ColoredDashboard is "true"
color   HeadColor        = 0x404040;
color   RowColor1        = 0x202020;
color   RowColor2        = 0x303030;
color   TitleColor       = White;
color   TradePairColor   = Yellow;
color   TextColor        = Gray;
color   SpreadAlertColor = Yellow;
color   StopHuntColor    = Orange;
color   PosNumberColor   = SeaGreen;
color   NegNumberColor   = DarkGoldenrod;
color   PosSumColor      = SpringGreen;
color   NegSumColor      = Gold;

////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage,WhatToShow="AllPairs";

////////////////////////////////////////////////////////////////////////////////////////

//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Tommaso for coding the function.
double         factor;//For pips/points stuff.

//Matt's O-R stuff
int            O_R_Setting_max_retries=10;
double         O_R_Setting_sleep_time=4.0; /* seconds */
double         O_R_Setting_sleep_max=15.0; /* seconds */
int            RetryCount=10;//Will make this number of attempts to get around the trade context busy error.



//Variables for building a picture of the open position
int            MarketTradesTotal=0;//Total of open market trades
int            PendingTradesTotal=0;//Total of pending orders
//Market Buy trades
bool           BuyOpen=false;
int            MarketBuysCount=0;
double         LatestBuyPrice=0, EarliestBuyPrice=0, HighestBuyPrice=0, LowestBuyPrice=0;
int            BuyTicketNo=-1, HighestBuyTicketNo=-1, LowestBuyTicketNo=-1, LatestBuyTicketNo=-1, EarliestBuyTicketNo=-1;
//double         BuyPipsUpl=0;
//double         BuyCashUpl=0;
datetime       LatestBuyTradeTime=0;
datetime       EarliestBuyTradeTime=0;

//Market Sell trades
bool           SellOpen=false;
int            MarketSellsCount=0;
double         LatestSellPrice=0, EarliestSellPrice=0, HighestSellPrice=0, LowestSellPrice=0;
int            SellTicketNo=-1, HighestSellTicketNo=-1, LowestSellTicketNo=-1, LatestSellTicketNo=-1, EarliestSellTicketNo=-1;;
//double         SellPipsUpl=0;
//double         SellCashUpl=0;
datetime       LatestSellTradeTime=0;
datetime       EarliestSellTradeTime=0;

//BuyStop trades
bool           BuyStopOpen=false;
int            BuyStopsCount=0;
double         LatestBuyStopPrice=0, EarliestBuyStopPrice=0, HighestBuyStopPrice=0, LowestBuyStopPrice=0;
int            BuyStopTicketNo=-1, HighestBuyStopTicketNo=-1, LowestBuyStopTicketNo=-1, LatestBuyStopTicketNo=-1, EarliestBuyStopTicketNo=-1;;
datetime       LatestBuyStopTradeTime=0;
datetime       EarliestBuyStopTradeTime=0;

//BuyLimit trades
bool           BuyLimitOpen=false;
int            BuyLimitsCount=0;
double         LatestBuyLimitPrice=0, EarliestBuyLimitPrice=0, HighestBuyLimitPrice=0, LowestBuyLimitPrice=0;
int            BuyLimitTicketNo=-1, HighestBuyLimitTicketNo=-1, LowestBuyLimitTicketNo=-1, LatestBuyLimitTicketNo=-1, EarliestBuyLimitTicketNo=-1;;
datetime       LatestBuyLimitTradeTime=0;
datetime       EarliestBuyLimitTradeTime=0;

/////SellStop trades
bool           SellStopOpen=false;
int            SellStopsCount=0;
double         LatestSellStopPrice=0, EarliestSellStopPrice=0, HighestSellStopPrice=0, LowestSellStopPrice=0;
int            SellStopTicketNo=-1, HighestSellStopTicketNo=-1, LowestSellStopTicketNo=-1, LatestSellStopTicketNo=-1, EarliestSellStopTicketNo=-1;;
datetime       LatestSellStopTradeTime=0;
datetime       EarliestSellStopTradeTime=0;

//SellLimit trades
bool           SellLimitOpen=false;
int            SellLimitsCount=0;
double         LatestSellLimitPrice=0, EarliestSellLimitPrice=0, HighestSellLimitPrice=0, LowestSellLimitPrice=0;
int            SellLimitTicketNo=-1, HighestSellLimitTicketNo=-1, LowestSellLimitTicketNo=-1, LatestSellLimitTicketNo=-1, EarliestSellLimitTicketNo=-1;;
datetime       LatestSellLimitTradeTime=0;
datetime       EarliestSellLimitTradeTime=0;

//Not related to specific order types
int            TicketNo=-1,OpenTrades,OldOpenTrades,ClosedTrades;
//Variables for storing market trade ticket numbers
datetime       LatestTradeTime=0, EarliestTradeTime=0;//More specific times are in each individual section
int            LatestTradeTicketNo=-1, EarliestTradeTicketNo=-1;
//We need to know the UPL values
double         PipsUpl[];//For keeping track of the pips PipsUpl of multi-trade positions. Aplies to the individual pair.
double         CashUpl[];//For keeping track of the cash PipsUpl of multi-trade positions. Aplies to the individual pair.
double         TotalPipsUpl=0;//Whole position
double         TotalCashUpl=0;//Whole position
double         TotalClosedPipsPl=0;//Whole position
double         TotalClosedCashPl=0;//Whole position
int            TotalOpenTrades=0;//Whole position
int            TotalClosedTrades=0;//Whole position

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

   if(WriteFileForTestDatabase) 
      ChartSaveTemplate(0,StringFormat("ZZT2MTPL-%s-%s-%s-%d-%d-%d-%d","FXT","SPB1","MULSYM",Period(),AccountNumber(),TimeCurrent(),MagicNumber));

   //Missing indi check
   /*
   if (!indiExists( "IndiName" ))
   {
      Alert("");
      Alert("Download the indi from the thread.");//Follow this with a link to the thread.
      Alert("The required indicator " + "IndiName" + " does not exist on your platform. I am removing myself from your chart.");
      RemoveExpert = true;
      ExpertRemove();
      return(0);
   }//if (! indiExists( "IndiName" ))
   */
   
   //create timer
   EventSetTimer(EventTimerIntervalSeconds);

   StopLoss=StopLossPips;
   TakeProfit=TakeProfitPips;
   BreakEvenPips=BreakEvenTargetPips;
   BreakEvenProfit = BreakEvenTargetProfit;
   JumpingStopPips = JumpingStopTargetPips;
   TrailingStopPips = TrailingStopTargetPips;
   DistanceBetweenTrades = DistanceBetweenTradesPips;
   
   //Extract the pairs traded by the user
   ExtractPairs();

   Gap="";
   if (DisplayGapSize >0)
   {
      for (int cc=0; cc< DisplayGapSize; cc++)
      {
         Gap = StringConcatenate(Gap, " ");
      }   
   }//if (DisplayGapSize >0)

   
   ReadIndicatorValues();//Initial read

   //Lot size based on account size
   if (!CloseEnough(LotsPerDollopOfCash, 0))
      CalculateLotAsAmountPerCashDollops();


   //Calculate a dynamic whole basket TP for initial display
   if (UseDynamicCashTP)
   {
      //Applied to a fixed lot size
      if (CloseEnough(LotsPerDollopOfCash, 0))
         if (CloseEnough(RiskPercent, 0))
            CalculateDynamicBasketCashTP(Lot);
   
      //LotsPerDollop
      if (!CloseEnough(LotsPerDollopOfCash, 0))
      {
         CalculateLotAsAmountPerCashDollops();
         CalculateDynamicBasketCashTP(Lot);
      }//if (!CloseEnough(LotsPerDollopOfCash, 0))
         
      //RiskPercent   
      if (!CloseEnough(RiskPercent, 0))
      {
         //Simulate a trade to calculate the lot size for a RiskPercent-based trade.
         double stop = 0, price = 0;
         string symbol = TradePair[0];
         price = MarketInfo(symbol, MODE_ASK);
         stop = CalculateStopLoss(OP_BUY, price);
         double SendLots = CalculateLotSize(symbol, price, stop);
      
         CalculateDynamicBasketCashTP(SendLots);
      
      }//if (!CloseEnough(RiskPercent, 0))
      
      
   }//if (UseDynamicCashTP)
      

   if (MinimiseChartsAfterOpening)
      ShrinkCharts();

   
   //Set up the trading hours
   tradingHoursDisplay=tradingHours;//For display
   initTradingHours();//Sets up the trading hours array


   

   DisplayUserFeedback();

   
   return(INIT_SUCCEEDED);
}

void ExtractPairs()
{
   
   StringSplit(PairsToTrade,',',TradePair);
   NoOfPairs = ArraySize(TradePair);
   
   
   string AddChar = StringSubstr(Symbol(),6,4);
   
   // Resize the arrays appropriately
   ArrayResize(TradePair, NoOfPairs);
   ArrayResize(ttfCandleTime, NoOfPairs);
   ArrayResize(HtfSsStatus, NoOfPairs);
   ArrayResize(BuySignal, NoOfPairs);
   ArrayResize(SellSignal, NoOfPairs);
   ArrayResize(TimeToStartTrading, NoOfPairs);
   ArrayResize(OldHtfIndiReadBarTime, NoOfPairs);
   ArrayResize(OldTtfIndiReadBarTime, NoOfPairs);
   ArrayResize(SpreadArray, NoOfPairs);
   ArrayInitialize(SpreadArray, 0);
   ArrayResize(PipsUpl, NoOfPairs);
   ArrayInitialize(PipsUpl, 0);
   ArrayResize(CashUpl, NoOfPairs);
   ArrayInitialize(CashUpl, 0);
   ArrayResize(BuyTradeTotals, NoOfPairs);
   ArrayInitialize(BuyTradeTotals, 0);
   ArrayResize(SellTradeTotals, NoOfPairs);
   ArrayInitialize(SellTradeTotals, 0);
   ArrayResize(ClosedBuyTradeTotals, NoOfPairs);
   ArrayInitialize(ClosedBuyTradeTotals, 0);
   ArrayResize(ClosedSellTradeTotals, NoOfPairs);
   ArrayInitialize(ClosedSellTradeTotals, 0);
   ArrayResize(PeakyStatus, NoOfPairs);
   

   
   for (int cc = 0; cc < NoOfPairs; cc ++)
   {
      TradePair[cc] = StringTrimLeft(TradePair[cc]);
      TradePair[cc] = StringTrimRight(TradePair[cc]);
      TradePair[cc] = StringConcatenate(TradePair[cc], AddChar);
      //Ensure the ea waits for the new candle to open before trading
      TimeToStartTrading[cc] = 0;
      OldHtfIndiReadBarTime[cc] = 0;
      OldTtfIndiReadBarTime[cc] = 0;
      
      //Average spread
      SpreadGvName=TradePair[cc] + " average spread";
      SpreadArray[cc][averagespread]=GlobalVariableGet(SpreadGvName);//If no gv, then the value will be left at zero.
      //Create a Global Variable with the current spread if this does not already exist
      if (CloseEnough(SpreadArray[cc][averagespread], 0))
      {
         GetBasics(TradePair[cc]);//Includes the current spread
         SpreadArray[cc][averagespread] = NormalizeDouble(spread, 2);
         GlobalVariableSet(SpreadGvName, spread);
      }//if (CloseEnough(SpreadArray[cc][averagespread], 0))
      
      //Longterm spread
      SpreadGvName=TradePair[cc] + " longterm spread";
      SpreadArray[cc][longtermspread]=GlobalVariableGet(SpreadGvName);//If no gv, then the value will be left at zero.
      //Create a Global Variable with the current spread if this does not already exist
      if (CloseEnough(SpreadArray[cc][longtermspread], 0))
      {
         GetBasics(TradePair[cc]);//Includes the current spread
         SpreadArray[cc][longtermspread] = NormalizeDouble(spread, 2);
         GlobalVariableSet(SpreadGvName, spread);
      }//if (CloseEnough(SpreadArray[cc][averagespread], 0))
      
      SpreadArray[cc][previousask] = 0;//Used to update the tick counter when there is a price change
      
   }//for (int cc; cc<NoOfPairs; cc ++)

}//End void ExtractPairs()


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    
   ArrayFree(TradePair);
   ArrayFree(ttfCandleTime);
   ArrayFree(OldHtfIndiReadBarTime);
   ArrayFree(OldTtfIndiReadBarTime);
   ArrayFree(HtfSsStatus);
   ArrayFree(BuySignal);
   ArrayFree(SellSignal);
   ArrayFree(TimeToStartTrading);
   ArrayFree(PipsUpl);
   ArrayFree(CashUpl);
   ArrayFree(BuyTradeTotals);
   ArrayFree(SellTradeTotals);
   ArrayFree(ClosedBuyTradeTotals);
   ArrayFree(ClosedSellTradeTotals);
   ArrayFree(PeakyStatus);
   

   removeAllObjects();
   
   //--- destroy timer
   EventKillTimer();
       
}

//For OrderSelect() Craptrader documentation states:
//   The pool parameter is ignored if the order is selected by the ticket number. The ticket number is a unique order identifier. 
//   To find out from what list the order has been selected, its close time must be analyzed. If the order close time equals to 0, 
//   the order is open or pending and taken from the terminal open orders list.
//This function heals this and allows use of pool parameter when selecting orders by ticket number.
//Tomele provided this code. Thanks Thomas.
bool BetterOrderSelect(int index,int select,int pool=-1)
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
}//End bool BetterOrderSelect(int index,int select,int pool=-1)



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   
}

string GetTimeFrameDisplay(int tf)
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

}//string GetTimeFrameDisplay()

//+--------------------------------------------------------------------+
//| Paul Bachelor's (lifesys) text display module to replace Comment()|
//+--------------------------------------------------------------------+
void SM(string message)
{
   if (DisplayAsText) 
   {
      DisplayCount++;
      Display(message);
   }
   else
      ScreenMessage = StringConcatenate(ScreenMessage,Gap, message);
      
}//End void SM()

//   ************************* added for OBJ_LABEL
void removeAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   if (StringFind(ObjectName(i),"OAM-",0) > -1) 
      ObjectDelete(ObjectName(i));
}//End void removeAllObjects()
//   ************************* added for OBJ_LABEL

void Display(string text)
{
   string lab_str = "OAM-" + IntegerToString(DisplayCount);  
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
         ObjectSet(lab_str, OBJPROP_XDISTANCE, DisplayX + ofset);
         ObjectSet(lab_str, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(int)(ScaleY*fontSize*1.5));
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

void DisplayUserFeedback()
{
   //Update all values
   CountTotalsForDisplay();
   CalculateClosedProfits();
   
   string text = "";
   //int cc = 0;
   
 
   //   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   //removeAllObjects();
   //   *************************

 
   ScreenMessage = "";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   //SM(NL);
   
   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);
   SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   SM(version + " mod FXT-SPB-1" + NL);
   
   if (AutoTradingEnabled)
      if(RolloverInProgress)
      {
         SM(NL);
         SM("---------- ROLLOVER IN PROGRESS. I am taking no action until "+RollOverEnds+" ----------"+NL);
      }//if (RolloverInProgress)
   
   SM(NL);
   //if (TreatAllPairsAsBasket)
     // SM("Lot size = " + DoubleToStr(Lot, 2) + ": Basket cash take profit = " + AccountCurrency() + " " + DoubleToStr(BasketTargetCash, 2) + NL);
   
   string sizingInfo = "Lot size = " + DoubleToStr(Lot, 2);
   if (TreatIndividualPairsAsBasket) 
   {
      if (UseDynamicCashTPIndividualPair) 
      {
         IndividualBasketTargetCash = NormalizeDouble(CashTakeProfitIndividualePairPerLot * Lot, 2);
      } // if (UseDynamicCashTPIndividualPair) 
      sizingInfo += " , Individual pair basket cash take profit = " + AccountCurrency() + " " + DoubleToStr(IndividualBasketTargetCash, 2);
   }//if (TreatIndividualPairsAsBasket) 
   
   //The basket trailing stop feature was added by 1of3. Fabulous contributin John; many thanks.
   if(TreatAllPairsAsBasket && UseBasketTrailingStop)
   {
      string descr = "Basket Trailing Stop active";
      if(BTSActivated)
         descr += ": Basket Stoploss Value: " + DoubleToStr(BTSStopLoss, 2) + " Current Proft: " + DoubleToStr(TotalCashUpl, 2);
      else
         descr += ": Distance to target ("+DoubleToStr(BasketTrailingStopStartValue,2)+") = " + DoubleToStr(BasketTrailingStopStartValue - TotalCashUpl, 2);
      SM(descr + NL);
   }
   
   if (TreatAllPairsAsBasket)
      //sizingInfo +=  " , Basket cash take profit = " + AccountCurrency() + " " + DoubleToStr(BasketTargetCash, 2) ;
      sizingInfo +=  " , All pairs basket target pips = " +(string)BasketTargetPips ;
   
   SM(sizingInfo + NL);
   SM(NL);
      
   SM("Click a pair to open its chart, the table name to switch between views, the headers to show/hide details, the labels at the bottom to let them do what they offer."+NL);
   
   DisplayMatrix();
 
   //Comment(ScreenMessage);


}//End void DisplayUserFeedback()

void DisplayMatrix()
{
   string name;
   
   //Variables for text labels
   double ActValue;
   color  ActColor;
   string ActString;
   
   double FactorX=ScaleX*fontSize;
   double FactorY=ScaleY*fontSize;
   
   //Select the colors for the header
   color ActTextColor=TextColor;
   color ActTitleColor=TitleColor;
   color ActTradePairColor=TradePairColor;
   color ActSpreadAlertColor=SpreadAlertColor;
   color ActStopHuntColor=StopHuntColor;
   color ActPosNumberColor=PosNumberColor;
   color ActNegNumberColor=NegNumberColor;
   color ActPosSumColor=PosSumColor;
   color ActNegSumColor=NegSumColor;
   if(!ColoredDashboard)
   {
      ActTextColor=colour;
      ActTitleColor=colour;
      ActTradePairColor=colour;
      ActSpreadAlertColor=DnSignalColor;
      ActStopHuntColor=DnSignalColor;
      ActPosNumberColor=UpSignalColor;
      ActNegNumberColor=DnSignalColor;
      ActPosSumColor=UpSignalColor;
      ActNegSumColor=DnSignalColor;
   }
   
   //Calculate the starting point
   int TextXPos=0;
   int TextYPos=DisplayY+DisplayCount*(int)(FactorY*1.5)+(int)(FactorY*3);
   
   //Detect need for deleting and redrawing the matrix at different y-position
   string PosMarker="OAM-DisplayStart"+IntegerToString(TextYPos);
   if(ObjectFind(0,PosMarker)<0)
   {
      removeAllObjects();
      ObjectCreate(PosMarker,OBJ_LABEL,0,0,0);
      ObjectSetText(PosMarker,"");
      DisplayUserFeedback();
      return;
   }

   //These are the sizes of the different columns
   int TPLength=(int)(FactorX*7); //Tradepair column
   int SSLength=(int)(FactorX*4); //SuperSlope columns
   int TSLength=(int)(FactorX*4); //TradeStatus column
   int TRLength=(int)(FactorX*6); //Trades column
   int PPLength=(int)(FactorX*7); //Profit/Loss in pips columns
   int PCLength=(int)(FactorX*7); //Profit/Loss in cash columns
   int SWLength=(int)(FactorX*6); //Swap columns
   int SPLength=(int)(FactorX*7); //Spread columns
   
   int GDLength=(int)(FactorX*2);   //Group divider (empty space)
   int TTLength=(int)(FactorX*122); //Table total (all columns and dividers +1 for the margins)
   
   if(HidePipsDetails)
      TTLength-=2*PPLength;
   if(HideCashDetails)
      TTLength-=2*PCLength;
   if(HideSwapDetails)
      TTLength-=2*SWLength;
   if(HideSpreadDetails)
      TTLength-=3*SPLength;
      
   //Display Headers
   
   TextXPos=DisplayX;
   
   //Draw the background
   if(ColoredDashboard)
   {
      name="OAM-ROW-0";
      if(ObjectFind(0,name)<0)
      {
         ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0,0);
         ObjectSet(name,OBJPROP_XDISTANCE,TextXPos); 
         ObjectSet(name,OBJPROP_YDISTANCE,TextYPos); 
         ObjectSet(name,OBJPROP_XSIZE,TTLength); 
         ObjectSet(name,OBJPROP_YSIZE,(int)(FactorY*4.5)); 
         ObjectSet(name,OBJPROP_BGCOLOR,HeadColor); 
         ObjectSet(name,OBJPROP_COLOR,HeadColor); 
         ObjectSet(name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      }
      
      //Give text a little margin
      TextXPos+=(int)(FactorX*0.5);
      TextYPos+=(int)(FactorY*0.6);
   }
   
   //Draw the table names
   string text1,text2;
   string PLString;
   
   if (WhatToShow=="AllPairs")
   {
      text1="All Pairs";
      text2="Unrealized P/L";
      PLString="UPL";
   }
   else if (WhatToShow=="TradablePairs")
   {
      text1="Tradable Pairs";
      text2="Unrealized P/L";
      PLString="UPL";
   }
   else if (WhatToShow=="OpenTrades")
   {
      text1="Open Trades";
      text2="Unrealized P/L";
      PLString="UPL";
   }
   else if (WhatToShow=="ClosedTrades")
   {
      text1="Closed Trades";
      text2="Realized P/L";
      PLString="RPL";
   }
   else if (WhatToShow=="AllTrades")
   {
      text1="All Trades";
      text2="Total P/L";
      PLString="TPL";
   }
   
   DisplayTextLabel(text1,TextXPos,TextYPos,ANCHOR_LEFT_UPPER,"SWITCH", 0, ButtonColor);
   DisplayTextLabel(text2,TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_LEFT_UPPER,"SWITCH", 0, ButtonColor);
   TextXPos+=TPLength;
   
   //Now draw all the column headers
   
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=SSLength;
   text1 = GetTimeFrameDisplay(HtfSsTimeFrame);
   DisplayTextLabel(text1,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   DisplayTextLabel("SS",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   
   TextXPos+=SSLength;
   text1 = GetTimeFrameDisplay(PeakyTimeFrame);
   DisplayTextLabel(text1,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   DisplayTextLabel("PK",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   
   
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=TRLength;
   DisplayTextLabel("Open",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   DisplayTextLabel("Trades",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=PPLength;
   DisplayTextLabel("Sum "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"HIDEPIPS", 0, ButtonColor);
   DisplayTextLabel("in pips",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"HIDEPIPS", 0, ButtonColor);

   if(!HidePipsDetails)
   {
      TextXPos+=PPLength;
      DisplayTextLabel("Buy "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      DisplayTextLabel("in pips",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   
      TextXPos+=PPLength;
      DisplayTextLabel("Sell "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      DisplayTextLabel("in pips",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }   
   
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=PCLength;
   DisplayTextLabel("Sum "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"HIDECASH", 0, ButtonColor);
   DisplayTextLabel("in " + AccountCurrency(),TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"HIDECASH", 0, ButtonColor);

   if(!HideCashDetails)
   {
      TextXPos+=PCLength;
      DisplayTextLabel("Buy "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      DisplayTextLabel("in " + AccountCurrency(),TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   
      TextXPos+=PCLength;
      DisplayTextLabel("Sell "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      DisplayTextLabel("in " + AccountCurrency(),TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }
      
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=SWLength;
   DisplayTextLabel("Trades",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"HIDESWAP", 0, ButtonColor);
   DisplayTextLabel("Swap",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"HIDESWAP", 0, ButtonColor);
   
   if(!HideSwapDetails)
   {
      TextXPos+=SWLength;
      DisplayTextLabel(" Long",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      DisplayTextLabel("Swap",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      
      TextXPos+=SWLength;
      DisplayTextLabel(" Short",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      DisplayTextLabel("Swap",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }
   
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=SPLength;
   DisplayTextLabel("Actual",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"HIDESPREAD", 0, ButtonColor);
   DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"HIDESPREAD", 0, ButtonColor);
   
   if(!HideSpreadDetails)
   {
      TextXPos+=SPLength;
      DisplayTextLabel("Average",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      
      TextXPos+=SPLength;
      DisplayTextLabel("Longterm",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      
      TextXPos+=SPLength;
      DisplayTextLabel("Biggest",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      DisplayTextLabel("Spread",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }
   
   //Point to the next YPos
   TextYPos+=(int)(FactorY*3.9);
   
   if(!ColoredDashboard)
      TextYPos+=(int)(FactorY*0.5);
      
   //Counter for alternating line color
   int row=0;
   
   //Variables for summary line
   int    SumPairs=0;
   int    SumLongTrades=0;
   int    SumShortTrades=0;
   int    SumSpreadAlerts=0;
   int    SumStopHuntAlerts=0;
   double SumLongPips=0;
   double SumShortPips=0;
   double SumLongCash=0;
   double SumShortCash=0;
   double SumTradeSwap=0;
  
   //Draw the tradepairlines
   for (int PairIndex = 0; PairIndex <= ArraySize(TradePair) - 1; PairIndex++)
   {
      CountTradesForDashboard(TradePair[PairIndex]);
      CountClosedTradesForDashboard(TradePair[PairIndex]);
      
      //Apply the filter      
      if (WhatToShow=="TradablePairs" && (PeakyStatus[PairIndex]==peakylonguntradable || PeakyStatus[PairIndex]==peakyshortuntradable
          || HtfSsStatus[PairIndex] == white))
            continue;
      if (WhatToShow=="OpenTrades" && OpenTrades==0)
           continue;
      if (WhatToShow=="ClosedTrades" && ClosedTrades==0)
           continue;
      if (WhatToShow=="AllTrades" && OpenTrades+ClosedTrades==0)
           continue;

      GetBasics(TradePair[PairIndex]);
      
      int ActLongTrades=OpenLongTrades;
      int ActShortTrades=OpenShortTrades;
      double ActBuyTradeTotalsPips=BuyTradeTotals[PairIndex][pipst];
      double ActSellTradeTotalsPips=SellTradeTotals[PairIndex][pipst];
      double ActBuyTradeTotalsCash=BuyTradeTotals[PairIndex][casht];
      double ActSellTradeTotalsCash=SellTradeTotals[PairIndex][casht];
      double ActBuyTradeTotalsSwap=BuyTradeTotals[PairIndex][swapt];
      double ActSellTradeTotalsSwap=SellTradeTotals[PairIndex][swapt];
      
      if (WhatToShow=="ClosedTrades")
      {
         ActLongTrades=ClosedLongTrades;
         ActShortTrades=ClosedShortTrades;
         ActBuyTradeTotalsPips=ClosedBuyTradeTotals[PairIndex][pipst];
         ActSellTradeTotalsPips=ClosedSellTradeTotals[PairIndex][pipst];
         ActBuyTradeTotalsCash=ClosedBuyTradeTotals[PairIndex][casht];
         ActSellTradeTotalsCash=ClosedSellTradeTotals[PairIndex][casht];
         ActBuyTradeTotalsSwap=ClosedBuyTradeTotals[PairIndex][swapt];
         ActSellTradeTotalsSwap=ClosedSellTradeTotals[PairIndex][swapt];
      }
      else if (WhatToShow=="AllTrades")
      {
         ActLongTrades=OpenLongTrades+ClosedLongTrades;
         ActShortTrades=OpenShortTrades+ClosedShortTrades;;
         ActBuyTradeTotalsPips=BuyTradeTotals[PairIndex][pipst]+ClosedBuyTradeTotals[PairIndex][pipst];
         ActSellTradeTotalsPips=SellTradeTotals[PairIndex][pipst]+ClosedSellTradeTotals[PairIndex][pipst];
         ActBuyTradeTotalsCash=BuyTradeTotals[PairIndex][casht]+ClosedBuyTradeTotals[PairIndex][casht];
         ActSellTradeTotalsCash=SellTradeTotals[PairIndex][casht]+ClosedSellTradeTotals[PairIndex][casht];
         ActBuyTradeTotalsSwap=BuyTradeTotals[PairIndex][swapt]+ClosedBuyTradeTotals[PairIndex][swapt];
         ActSellTradeTotalsSwap=SellTradeTotals[PairIndex][swapt]+ClosedSellTradeTotals[PairIndex][swapt];
      }
   
      //Start the line
      TextXPos=DisplayX;
      
      //Select the alternating color for this line and draw the background
      if(ColoredDashboard)
      {
         row+=1;
         int rcolor=RowColor1;
         if(MathMod(row,2)==0)
            rcolor=RowColor2;

         name="OAM-ROW-"+IntegerToString(row);
         if(ObjectFind(0,name)<0)
         {
            ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0,0);
            ObjectSet(name,OBJPROP_XDISTANCE,TextXPos); 
            ObjectSet(name,OBJPROP_YDISTANCE,TextYPos); 
            ObjectSet(name,OBJPROP_XSIZE,TTLength); 
            ObjectSet(name,OBJPROP_YSIZE,(int)(FactorY*2)); 
            ObjectSet(name,OBJPROP_BGCOLOR,rcolor); 
            ObjectSet(name,OBJPROP_COLOR,rcolor); 
            ObjectSet(name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
         }
         
         //Give text a little margin
         TextXPos+=(int)(FactorX*0.5);
         TextYPos+=(int)(FactorY*0.2);
      }

      // Draw the tradepair and its data in one line
      
      DisplayTextLabel(TradePair[PairIndex],TextXPos,TextYPos, ANCHOR_LEFT_UPPER, TradePair[PairIndex], 0, ActTradePairColor);
      SumPairs+=1;
      TextXPos+=TPLength;

      TextXPos+=GDLength; //Group divider
      
      TextXPos+=SSLength;
      DisplayTextLabel(HtfSsStatus[PairIndex],TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      
      TextXPos+=SSLength;
      DisplayTextLabel(PeakyStatus[PairIndex],TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      
      
      TextXPos+=GDLength; //Group divider
      
      TextXPos+=TRLength;
      string trades="";
      if (ActLongTrades==0 && ActShortTrades==0)
         trades="";
      else if (ActLongTrades>0 && ActShortTrades>0)
         trades=StringConcatenate(IntegerToString(ActLongTrades),"B,",IntegerToString(ActShortTrades),"S");
      else if (ActLongTrades>0)
         trades=StringConcatenate(IntegerToString(ActLongTrades),"B");
      else if (ActShortTrades>0)
         trades=StringConcatenate(IntegerToString(ActShortTrades),"S");
      color tcolor=NoSignalColor;
      if (ActLongTrades>ActShortTrades)
         tcolor=UpSignalColor;
      else if (ActLongTrades<ActShortTrades)
         tcolor=DnSignalColor;
      DisplayTextLabel(trades,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, tcolor);
      SumLongTrades+=ActLongTrades;
      SumShortTrades+=ActShortTrades;

      TextXPos+=GDLength; //Group divider
      
      TextXPos+=PPLength;
      ActValue=ActBuyTradeTotalsPips+ActSellTradeTotalsPips;
      if(ActValue>0)
         ActColor=ActPosSumColor;
      else
         ActColor=ActNegSumColor;
      if (ActLongTrades+ActShortTrades>0)
         DisplayTextLabel(DoubleToStr(ActValue, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"",0,ActColor);
      else
         DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      
      if(!HidePipsDetails)
      {
         TextXPos+=PPLength;
         if (ActLongTrades>0)
            DisplayTextLabel(DoubleToStr(ActBuyTradeTotalsPips, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         else
            DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

         TextXPos+=PPLength;
         if (ActShortTrades>0)
            DisplayTextLabel(DoubleToStr(ActSellTradeTotalsPips, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         else
            DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      }
      SumLongPips+=ActBuyTradeTotalsPips;
      SumShortPips+=ActSellTradeTotalsPips;
      
      TextXPos+=GDLength; //Group divider
      
      TextXPos+=PCLength;
      ActValue=ActBuyTradeTotalsCash+ActSellTradeTotalsCash;
      if(ActValue>0)
         ActColor=ActPosSumColor;
      else
         ActColor=ActNegSumColor;
      if (ActLongTrades+ActShortTrades>0)
         DisplayTextLabel(DoubleToStr(ActValue, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"",0,ActColor);
      else
         DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      
      if(!HideCashDetails)
      {
         TextXPos+=PCLength;
         if (ActLongTrades>0)
            DisplayTextLabel(DoubleToStr(ActBuyTradeTotalsCash, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         else
            DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         
         TextXPos+=PCLength;
         if (ActShortTrades>0)
            DisplayTextLabel(DoubleToStr(ActSellTradeTotalsCash, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         else
            DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      }
      SumLongCash+=ActBuyTradeTotalsCash;
      SumShortCash+=ActSellTradeTotalsCash;

      TextXPos+=GDLength; //Group divider
      
      TextXPos+=SWLength;
      ActValue=ActBuyTradeTotalsSwap+ActSellTradeTotalsSwap;
      if(ActValue>0)
         ActColor=ActPosSumColor;
      else
         ActColor=ActNegSumColor;
      if (ActLongTrades+ActShortTrades>0)
         DisplayTextLabel(DoubleToStr(ActValue, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"",0,ActColor);
      else
         DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      SumTradeSwap+=ActBuyTradeTotalsSwap+ActSellTradeTotalsSwap;
      
      if(!HideSwapDetails)
      {
         TextXPos+=SWLength;
         DisplayTextLabel(DoubleToStr(longSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         
         TextXPos+=SWLength;
         DisplayTextLabel(DoubleToStr(shortSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      }
      
      TextXPos+=GDLength; //Group divider
      
      //Highlight the spreads if unusual (higher than double the average or higher than biggest)
      ActColor=ActTextColor;
      if (!SpreadCheck(PairIndex) )
      {   
         ActColor=ActStopHuntColor;
         SumStopHuntAlerts+=1;
      }
      else if(NormalizeDouble(SpreadArray[PairIndex][averagespread],1)>MathMax(NormalizeDouble(SpreadArray[PairIndex][longtermspread],1),0.1)*3)
      {
         ActColor=ActSpreadAlertColor;
         SumSpreadAlerts+=1;
      }

      TextXPos+=SPLength;
      DisplayTextLabel(DoubleToStr(spread, 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
      
      if(!HideSpreadDetails)
      {
         TextXPos+=SPLength;
         DisplayTextLabel(DoubleToStr(SpreadArray[PairIndex][averagespread], 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
         
         TextXPos+=SPLength;
         DisplayTextLabel(DoubleToStr(SpreadArray[PairIndex][longtermspread], 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
         
         TextXPos+=SPLength;
         DisplayTextLabel(DoubleToStr(SpreadArray[PairIndex][biggestspread], 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
      }
             
      //Point to the next YPos to start a new line
      TextYPos+=(int)(FactorY*1.8);
        
   }//for (PairIndex = 0; PairIndex <= ArraySize(TradePair) -1; PairIndex++)
   
   //Display summary line
   
   TextXPos=DisplayX;
   
   //Draw the background
   if(ColoredDashboard)
   {
      name="OAM-ROW-S";
      if(ObjectFind(0,name)<0)
      {
         ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0,0);
         ObjectSet(name,OBJPROP_XDISTANCE,TextXPos); 
         ObjectSet(name,OBJPROP_YDISTANCE,TextYPos); 
         ObjectSet(name,OBJPROP_XSIZE,TTLength); 
         ObjectSet(name,OBJPROP_YSIZE,(int)(FactorY*3)); 
         ObjectSet(name,OBJPROP_BGCOLOR,HeadColor); 
         ObjectSet(name,OBJPROP_COLOR,HeadColor); 
         ObjectSet(name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      }
      
      //Give text a little margin
      TextXPos+=(int)(FactorX*0.5);
      TextYPos+=(int)(FactorY*0.6);
   }
   else
      TextYPos+=(int)(FactorY);
         
   ActValue=SumPairs;
   if(ActValue>0)
      DisplayTextLabel(IntegerToString((int)ActValue)+" pairs",TextXPos,TextYPos,ANCHOR_LEFT_UPPER,"", 0, ActTitleColor);
   else
      DisplayTextLabel("No matching pairs",TextXPos,TextYPos,ANCHOR_LEFT_UPPER,"", 0, ActTitleColor);
   TextXPos+=TPLength;
   
   TextXPos+=GDLength; //Group divider
      
   //Empty fields
   TextXPos+=SSLength;
   TextXPos+=SSLength;
   //TextXPos+=TSLength;
   
   TextXPos+=GDLength; //Group divider

   //ActString="";
   //if (SumLongTrades==0 && SumShortTrades==0)
   //   ActString="";
   //else if (SumLongTrades>0 && SumShortTrades>0)
   //   ActString=IntegerToString(SumLongTrades)+"B,"+IntegerToString(SumShortTrades)+"S";
   //else if (SumLongTrades>0)
   //   ActString=IntegerToString(SumLongTrades)+"B";
   //else if (SumShortTrades>0)
   //   ActString=IntegerToString(SumShortTrades)+"S";
   TextXPos+=TRLength;
   int ActTrades=SumLongTrades+SumShortTrades;
   ActString=IntegerToString(ActTrades)+" trades";
   if(ColoredDashboard)
      ActColor=ActTitleColor;
   else
      ActColor=NoSignalColor;
   if(ActTrades>0)
      DisplayTextLabel(ActString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
   else
      DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   
   TextXPos+=GDLength; //Group divider

   TextXPos+=PPLength;
   ActValue=SumLongPips+SumShortPips;
   if(ActValue>0)
      ActColor=ActPosSumColor;
   else
      ActColor=ActNegSumColor;
   if(ActTrades>0)
      DisplayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
   else
      DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

   if(!HidePipsDetails)
   {
      TextXPos+=PPLength;
      ActValue=SumLongPips;
      if(ActValue>0)
         ActColor=ActPosNumberColor;
      else
         ActColor=ActNegNumberColor;
      if(ActTrades>0)
         DisplayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
      else
         DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   
      TextXPos+=PPLength;
      ActValue=SumShortPips;
      if(ActValue>0)
         ActColor=ActPosNumberColor;
      else
         ActColor=ActNegNumberColor;
      if(ActTrades>0)
         DisplayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
      else
         DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   }
   
   TextXPos+=GDLength; //Group divider
      
   TextXPos+=PCLength;
   ActValue=SumLongCash+SumShortCash;
   if(ActValue>0)
      ActColor=ActPosSumColor;
   else
      ActColor=ActNegSumColor;
   if(ActTrades>0)
      DisplayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
   else
      DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

   if(!HideCashDetails)
   {
      TextXPos+=PCLength;
      ActValue=SumLongCash;
      if(ActValue>0)
         ActColor=ActPosNumberColor;
      else
         ActColor=ActNegNumberColor;
      if(ActTrades>0)
         DisplayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
      else
         DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   
      TextXPos+=PCLength;
      ActValue=SumShortCash;
      if(ActValue>0)
         ActColor=ActPosNumberColor;
      else
         ActColor=ActNegNumberColor;
      if(ActTrades>0)
         DisplayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
      else
         DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   }
   
   TextXPos+=GDLength; //Group divider
      
   TextXPos+=SWLength;
   ActValue=SumTradeSwap;
   if(ActValue>0)
      ActColor=ActPosSumColor;
   else
      ActColor=ActNegSumColor;
   if(ActTrades>0)
      DisplayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
   else
      DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   
   //Empty fields
   if(!HideSwapDetails)
   {
      TextXPos+=SWLength;
      TextXPos+=SWLength;
   }
   
   TextXPos+=GDLength; //Group divider
   
   //Empty fields
   TextXPos+=SPLength;

   if(!HideSpreadDetails)
   {
      TextXPos+=SPLength;
      TextXPos+=SPLength;
      TextXPos+=SPLength;
   }
   
   if(SumPairs>0)
   {
      if(SumStopHuntAlerts>0)
      {
         ActColor=ActStopHuntColor;
         if(HideSpreadDetails&&HideSwapDetails)
            ActString="Stop Hunt";
         else 
            ActString="POSSIBLE STOP HUNT";
      }
      else if(SumSpreadAlerts>(int)(ArraySize(TradePair)/3))
      {
         ActColor=ActSpreadAlertColor;
         if(HideSpreadDetails&&HideSwapDetails)
            ActString="Abnormal";
         else 
            ActString="ABNORMAL SPREADS";
      }
      else
      {
         ActColor=ActTitleColor;
         if(HideSpreadDetails&&HideSwapDetails)
            ActString="Normal";
         else 
            ActString="Normal spreads";
      }
      DisplayTextLabel(ActString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
   }
   else
      DisplayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

   //Draw the buttons below the table
   TextYPos+=(int)(FactorY*4);

   DisplayTextLabel("Open all charts in alphabetical order",DisplayX,TextYPos,ANCHOR_LEFT_UPPER,"OPENALL", 0, ButtonColor);
   DisplayTextLabel("Open all trades in alphabetical order",DisplayX+(int)(FactorX*25),TextYPos,ANCHOR_LEFT_UPPER,"OPENTRADES", 0, ButtonColor);
   DisplayTextLabel("Touch all charts for CTRL-F6 browsing",DisplayX+(int)(FactorX*50),TextYPos,ANCHOR_LEFT_UPPER,"TOUCH", 0, ButtonColor);
   DisplayTextLabel("Close all charts",(int)(DisplayX+FactorX*76),TextYPos,ANCHOR_LEFT_UPPER,"CLOSE", 0, ButtonColor);

   
}//End void DisplayMatrix()


void DisplayTextLabel(string text, int xpos, int ypos, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, string pair="", int tf=0, color scol=clrNONE)
{

   //Decide which colors to use for the data in the dashboard
   color ActTextColor=TextColor;
   color ActPosNumberColor=PosNumberColor;
   color ActNegNumberColor=NegNumberColor;
   if(!ColoredDashboard)
   {
      ActTextColor=colour;
      ActPosNumberColor=UpSignalColor;
      ActNegNumberColor=DnSignalColor;
   }
   
   if (scol==clrNONE)
   {
      if(StringFind(text,"pips")>0)
         scol=ActTextColor;
      else if(StringToDouble(text)>0)
         scol=ActPosNumberColor;
      else if(StringToDouble(text)<0)
         scol=ActNegNumberColor;
   }
   
   //Select the color for the actual signal
   if (text=="Long"||text=="Blue"||text=="Up arrow"||text=="Up wave"||text=="Up"||text=="Tradable long"||text==peakylongtradable) scol=UpSignalColor;
   else if (text=="Short"||text=="Red"||text=="Dn arrow"||text=="Dn wave"||text=="Down"||text=="Tradable short"||text==peakyshorttradable) scol=DnSignalColor;
   else if (text=="No signal"||text=="White"||text=="Not tradable"||text==peakylonguntradable||text==peakyshortuntradable)scol=NoSignalColor;
   else if (text=="Yellow range wave")scol=Yellow;
   
   //Select the symbol for the actual signal
   if (text=="Long"||text=="Blue"||text=="Up arrow"||text=="Up"||text==peakylongtradable||text==peakylonguntradable) text="á";
   else if (text=="Short"||text=="Red"||text=="Dn arrow"||text=="Down"||text==peakyshorttradable||text==peakyshortuntradable) text="â";
   else if (text=="Up wave"||text=="Dn wave"||text=="Yellow range wave") text="h";
   else if (text=="Tradable long"||text=="Tradable short") text="ü";
   else if (text=="No signal"||text=="White"||text=="Not tradable"||text==nocross)text="û";
   
   //Select font and font size for the actual symbol
   string font=fontName;
   int sise=fontSize;
   if (text=="á"||text=="â"||text=="h"||text=="ü")
   {
      font="Wingdings";
      sise=(int)MathRound(fontSize*1.2);
   }
   if (text=="û")
   {
      font="Wingdings";
      sise=(int)MathRound(fontSize*1.5);
   }
   
   //Define the name for the actual label
   string lab_str;
   if (pair=="") 
      //Text label
      lab_str = "OAM-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="OPENALL") 
      //Open all charts button
      lab_str = "OAM-OPENALL-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="OPENTRADES") 
      //Open all trades button
      lab_str = "OAM-OPENTRADES-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="TOUCH") 
      //Touch all charts button
      lab_str = "OAM-TOUCH-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="CLOSE") 
      //Close other charts button
      lab_str = "OAM-CLOSE-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="SWITCH") 
      //Switch displays button
      lab_str = "OAM-SWITCH-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="HIDEPIPS") 
      //Hide pips button
      lab_str = "OAM-HIDEPIPS-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="HIDECASH") 
      //Hide cash button
      lab_str = "OAM-HIDECASH-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="HIDESWAP") 
      //Hide swap button
      lab_str = "OAM-HIDESWAP-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else if (pair=="HIDESPREAD") 
      //Hide spread button
      lab_str = "OAM-HIDESPREAD-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   
   else 
      //Clickable label needs pair and timeframe for OpenChart()
      lab_str = "OAM-BTN-" + pair + "-" + IntegerToString(tf)+"-X" + IntegerToString(xpos) + "Y" + IntegerToString(ypos);   

   //Create the label if it doesnt exist
   if(ObjectFind(0,lab_str)<0)
   {
      ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0);
      ObjectSet(lab_str, OBJPROP_CORNER, 0);
      ObjectSet(lab_str, OBJPROP_XDISTANCE, xpos); 
      ObjectSet(lab_str, OBJPROP_YDISTANCE, ypos); 
      ObjectSet(lab_str, OBJPROP_BACK, false);
      ObjectSetInteger(0,lab_str,OBJPROP_ANCHOR,anchor); 
   }
   
   //Update the text in the label
   ObjectSetText(lab_str, text, sise, font, scol);
   
}//End void DisplayTextLabel(string text, int xpos, int ypos, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)



void GetBasics(string symbol)
{
   //Sets up bid, ask, digits, factor for the passed pair
   bid = MarketInfo(symbol, MODE_BID);
   ask = MarketInfo(symbol, MODE_ASK);
   digits = (int)MarketInfo(symbol, MODE_DIGITS);
   factor = GetPipFactor(symbol);
   spread = (ask - bid) * factor;
   longSwap = MarketInfo(symbol, MODE_SWAPLONG);
   shortSwap = MarketInfo(symbol, MODE_SWAPSHORT);
   
      
}//End void GetBasics(string symbol)

int GetPipFactor(string Xsymbol)
{
   //Code from Tommaso's APTM
   
   static const string factor1000[]={"SEK","TRY","ZAR","MXN"};
   static const string factor100[]         = {"JPY","XAG","SILVER","BRENT","WTI"};
   static const string factor10[]          = {"XAU","GOLD","SP500","US500Cash","US500","Bund"};
   static const string factor1[]           = {"UK100","WS30","DAX30","NAS100","CAC40","FRA40","GER30","ITA40","EUSTX50","JPN225","US30Cash","US30"};
   int j = 0;
   
   int xFactor=10000;       // correct xFactor for most pairs
   if(MarketInfo(Xsymbol,MODE_DIGITS)<=1) xFactor=1;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==2) xFactor=10;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==3) xFactor=100;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==4) xFactor=1000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==5) xFactor=10000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==6) xFactor=100000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==7) xFactor=1000000;
   for(j=0; j<ArraySize(factor1000); j++)
   {
      if(StringFind(Xsymbol,factor1000[j])!=-1) xFactor=1000;
   }
   for(j=0; j<ArraySize(factor100); j++)
   {
      if(StringFind(Xsymbol,factor100[j])!=-1) xFactor=100;
   }
   for(j=0; j<ArraySize(factor10); j++)
   {
      if(StringFind(Xsymbol,factor10[j])!=-1) xFactor=10;
   }
   for(j=0; j<ArraySize(factor1); j++)
   {
      if(StringFind(Xsymbol,factor1[j])!=-1) xFactor=1;
   }

   return (xFactor);
}//End int GetPipFactor(string Xsymbol)


void ChartAutomation(string symbol, int index)
{
   long currChart = 0, prevChart = ChartFirst();
   int cc = 0, limit = ArraySize(TradePair) -1;
   
   //We want to close charts that are not tradable
   if (TimerCount==0)//We do this only every ChartCloseTimerMultiple cycle
      if (PeakyStatus[index] == untradable)
      {
         //We cannot close charts with open trades
         CountTradesForDashboard(symbol);
         if (OpenTrades > 0)
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
   if (PeakyStatus[index] == untradable)
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
   
   
}//End void ChartAutomation(string symbol)


void DrawTradeArrows(string symbol, long chartid)
{
   //Find the bar shift of open trades and draw an arrow to show where they opened.
   if (OrdersTotal() == 0)
      return;//Nothing to do
      
   //Delete eventual prior symbols
   ObjectsDeleteAll(chartid,"SCB");
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      
      //Ensure the trade is still open
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      
      //Ensure the EA 'owns' this trade
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      if (OrderSymbol() != symbol ) continue;
      
      GetBasics(OrderSymbol());
      
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
         
         if(DrawTradeArrows)
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
         
         if(DrawTradeArrows)
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

}//End void DrawTradeArrows(string symbol)

double GetSuperSlope(string symbol, int tf, int maperiod, int atrperiod, int pShift )
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
   
}//GetSuperSlope(}

double GetAtr(string symbol, int tf, int period, int shift)
{
   //Returns the value of atr
   
   return(iATR(symbol, tf, period, shift) );   

}//End double GetAtr()

void GetPeaky(string symbol, int PairIndex)
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
   PeakyStatus[PairIndex] = peakylongtradable;
   if (currentPeakHighBar < currentPeakLowBar)
      PeakyStatus[PairIndex] = peakyshorttradable;

   //Cannot be beyond the half way price between highest and lowest
   //Long
   if (PeakyStatus[PairIndex] == peakylongtradable)
      if (ask > HalfWay)
         PeakyStatus[PairIndex] = peakylonguntradable;
         
   //Short
   if (PeakyStatus[PairIndex] == peakyshorttradable)
      if (bid < HalfWay)
         PeakyStatus[PairIndex] = peakyshortuntradable;
         
  
}//End void GetPeaky(string symbol, int PairIndex)


void ReadIndicatorValues()
{

   
   for (int PairIndex = 0; PairIndex <= ArraySize(TradePair) - 1; PairIndex++)
   {
      double val = 0;
      int cc = 0;
      
      string symbol = TradePair[PairIndex];//Makes typing easier
      GetBasics(symbol);//Bid etc
  
      CountOpenTrades(symbol, PairIndex);
      //Prevent multiple trades
      BuySignal[PairIndex] = false;
      SellSignal[PairIndex] = false;

      
      //Read the HTF SS at the open of each candle
      if (OldHtfIndiReadBarTime[PairIndex] != iTime(symbol, HtfSsTimeFrame, 0) )
      { 
         OldHtfIndiReadBarTime[PairIndex] = iTime(symbol, HtfSsTimeFrame, 0);
         
         
         //Read SuperSlope at the open of each new trading time frame candle
         val = GetSuperSlope(symbol, HtfSsTimeFrame,HtfSsSlopeMAPeriod,HtfSsSlopeATRPeriod,1);
               
         //Changed by tomele. Many thanks Thomas.
         //Set the colours
         HtfSsStatus[PairIndex] = white;
         
         if (val > 0)  //buy
            if (val - HtfSsDifferenceThreshold/2 > 0) //blue
               HtfSsStatus[PairIndex] = blue;

         if (val < 0)  //sell
            if (val + HtfSsDifferenceThreshold/2 < 0) //red
               HtfSsStatus[PairIndex] = red;
   
      }//if (OldHtfIndiReadBarTime != iTime(symbol, HtfSsTimeFrame, 0) )
      
      //Peaky
      GetPeaky(symbol, PairIndex);
          
         //Make the initial trading decision
                  
         //Buy
         if (HtfSsStatus[PairIndex] == blue)
            if (PeakyStatus[PairIndex] == peakylongtradable)   
               if (MarketBuysCount == 0)
                  if (BuyStopsCount == 0)
                     BuySignal[PairIndex] = true;
                        
         //Sell
         if (HtfSsStatus[PairIndex] == red)
            if (PeakyStatus[PairIndex] == peakyshorttradable)
               if (MarketSellsCount == 0)
                  if (SellStopsCount == 0)
                     SellSignal[PairIndex] = true;
                  
         //Fill in gaps if the market is moving in the wrong direction.
         //This is only needed if we are grid trading.
         if (GridSize > 0)
         {
            double price = 0, target = 0, SendPrice = 0;
            double stop = 0, take = 0, SendLots = 0;
            bool result = true;
            
            //Examine buys
            //if (BuyStopsCount > 0 || MarketBuysCount > 0 )
            if ((BuyStopsCount > 0 || MarketBuysCount > 0) && (!DeletePendingTradesOnOppositeSignal || HtfSsStatus[PairIndex] != red))
            {
               //Is the market lower than the lowest buy/stop price
               price = MathMin(LowestBuyPrice, LowestBuyStopPrice);
               if (ask < price)
               {
                  //Atr for grid size
                  if (UseAtrForGrid)
                  {
                     val = GetAtr(symbol, GridAtrTimeFrame, GridAtrPeriod, 0);
                     DistanceBetweenTrades = (val * factor) * GridAtrMultiplier;
                  }//if (UseAtrForGrid)
                  target = price - ((DistanceBetweenTrades * 2) / factor);
                  
                  //Is there a gap to fill?
                  if (ask <= target)
                  {
                     SendPrice = NormalizeDouble(price - (DistanceBetweenTrades / factor), digits);
                     //Yes, so set the parameters and send a trade
                     stop = CalculateStopLoss(OP_BUY, SendPrice);
                     take = CalculateTakeProfit(OP_BUY, SendPrice);
                     SendLots = Lot;
                     //Lot size calculated by risk
                     if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(symbol, SendPrice, stop );
                     //Lot size calculated by lots per dollop dollop
                     if (CloseEnough(RiskPercent, 0))
                        if (!CloseEnough(LotsPerDollopOfCash, 0) )
                        {
                           CalculateLotAsAmountPerCashDollops();
                           SendLots = Lot;
                        }//if (!CloseEnough(LotsPerDollopOfCash, 0) )
                        
                     result = SendSingleTrade(symbol, OP_BUYSTOP, TradeComment, SendLots, SendPrice, stop, take);
                  }//if (ask <= target)
                  
               }//if (ask < price)
            
            }//if (BuyStopsCount > 0 || MarketBuysCount > 0)
         
            //Examine sells
            //if (SellStopsCount > 0 || MarketSellsCount > 0)
            if ((SellStopsCount > 0 || MarketSellsCount > 0) && (!DeletePendingTradesOnOppositeSignal || HtfSsStatus[PairIndex] != blue))
            {
               //Is the market lower than the lowest buy/stop price
               price = MathMax(HighestSellPrice, HighestSellStopPrice);
               if (bid > price)
               {
                  //Atr for grid size
                  if (UseAtrForGrid)
                  {
                     val = GetAtr(symbol, GridAtrTimeFrame, GridAtrPeriod, 0);
                     DistanceBetweenTrades = (val * factor) * GridAtrMultiplier;
                  }//if (UseAtrForGrid)
                  target = price + ((DistanceBetweenTrades * 2) / factor);
                  
                  //Is there a gap to fill?
                  if (bid >= target)
                  {
                     SendPrice = NormalizeDouble(price + (DistanceBetweenTrades / factor), digits);
                     //Yes, so set the parameters and send a trade
                     stop = CalculateStopLoss(OP_SELL, SendPrice);
                     take = CalculateTakeProfit(OP_SELL, SendPrice);
                     SendLots = Lot;
                     //Lot size calculated by risk
                     if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(symbol, SendPrice, stop );
                     //Lot size calculated by lots per dollop dollop
                     if (CloseEnough(RiskPercent, 0))
                        if (!CloseEnough(LotsPerDollopOfCash, 0) )
                        {
                           CalculateLotAsAmountPerCashDollops();
                           SendLots = Lot;
                        }//if (!CloseEnough(LotsPerDollopOfCash, 0) )
                        
                     result = SendSingleTrade(symbol, OP_SELLSTOP, TradeComment, SendLots, SendPrice, stop, take);
                  }//if (ask <= target)
                  
               }//if (bid >= target)
               
            
            }//if (SellStopsCount > 0 || MarketSellsCount > 0)
         
         
         
         }//if (GridSize > 0)
         
                        
         
         
     //Chart automation
     // if (tradingStatus[PairIndex] == tradablelong || tradingStatus[PairIndex] == tradableshort)
         if (AutomateChartOpeningAndClosing)
            ChartAutomation(symbol, PairIndex);
            
      
   }//for (int cc = 0; cc <= ArraySize(TradePair); cc++)

   Comment("");
   
}//void ReadIndicatorValues()

void CountOpenTrades(string symbol, int PairIndex)
{
   //Not all these will be needed. Which ones are depends on the individual EA.
   //Market Buy trades
   BuyOpen=false;
   MarketBuysCount=0;
   LatestBuyPrice=0; EarliestBuyPrice=0; HighestBuyPrice=0; LowestBuyPrice=million;
   BuyTicketNo=-1; HighestBuyTicketNo=-1; LowestBuyTicketNo=-1; LatestBuyTicketNo=-1; EarliestBuyTicketNo=-1;
   LatestBuyTradeTime=0;
   EarliestBuyTradeTime=TimeCurrent();
   
   //Market Sell trades
   SellOpen=false;
   MarketSellsCount=0;
   LatestSellPrice=0; EarliestSellPrice=0; HighestSellPrice=0; LowestSellPrice=million;
   SellTicketNo=-1; HighestSellTicketNo=-1; LowestSellTicketNo=-1; LatestSellTicketNo=-1; EarliestSellTicketNo=-1;;
   LatestSellTradeTime=0;
   EarliestSellTradeTime=TimeCurrent();
   
   //BuyStop trades
   BuyStopOpen=false;
   BuyStopsCount=0;
   LatestBuyStopPrice=0; EarliestBuyStopPrice=0; HighestBuyStopPrice=0; LowestBuyStopPrice=million;
   BuyStopTicketNo=-1; HighestBuyStopTicketNo=-1; LowestBuyStopTicketNo=-1; LatestBuyStopTicketNo=-1; EarliestBuyStopTicketNo=-1;;
   LatestBuyStopTradeTime=0;
   EarliestBuyStopTradeTime=TimeCurrent();
   
   //BuyLimit trades
   BuyLimitOpen=false;
   BuyLimitsCount=0;
   LatestBuyLimitPrice=0; EarliestBuyLimitPrice=0; HighestBuyLimitPrice=0; LowestBuyLimitPrice=million;
   BuyLimitTicketNo=-1; HighestBuyLimitTicketNo=-1; LowestBuyLimitTicketNo=-1; LatestBuyLimitTicketNo=-1; EarliestBuyLimitTicketNo=-1;;
   LatestBuyLimitTradeTime=0;
   EarliestBuyLimitTradeTime=TimeCurrent();
   
   /////SellStop trades
   SellStopOpen=false;
   SellStopsCount=0;
   LatestSellStopPrice=0; EarliestSellStopPrice=0; HighestSellStopPrice=0; LowestSellStopPrice=million;
   SellStopTicketNo=-1; HighestSellStopTicketNo=-1; LowestSellStopTicketNo=-1; LatestSellStopTicketNo=-1; EarliestSellStopTicketNo=-1;;
   LatestSellStopTradeTime=0;
   EarliestSellStopTradeTime=TimeCurrent();
   
   //SellLimit trades
   SellLimitOpen=false;
   SellLimitsCount=0;
   LatestSellLimitPrice=0; EarliestSellLimitPrice=0; HighestSellLimitPrice=0; LowestSellLimitPrice=million;
   SellLimitTicketNo=-1; HighestSellLimitTicketNo=-1; LowestSellLimitTicketNo=-1; LatestSellLimitTicketNo=-1; EarliestSellLimitTicketNo=-1;;
   LatestSellLimitTradeTime=0;
   EarliestSellLimitTradeTime=TimeCurrent();
   
   //Not related to specific order types
   MarketTradesTotal = 0;
   PendingTradesTotal = 0;
   TicketNo=-1;OpenTrades=0;
   LatestTradeTime=0; EarliestTradeTime=TimeCurrent();//More specific times are in each individual section
   LatestTradeTicketNo=-1; EarliestTradeTicketNo=-1;
   PipsUpl[PairIndex]=0;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
   CashUpl[PairIndex]=0;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
   
   
   double pips = 0; 
   
   int type;//Saves the OrderType() for consulatation later in the function
   
   
   if (OrdersTotal() == 0) return;
   
   //Iterating backwards through the orders list caters more easily for closed trades than iterating forwards
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;

      
      //Ensure the EA 'owns' this trade
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      if (OrderSymbol() != symbol ) continue;
      
      //The time of the most recent trade
      if (OrderOpenTime() > LatestTradeTime)
      {
         LatestTradeTime = OrderOpenTime();
         LatestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() > LatestTradeTime)
      
      //The time of the earliest trade
      if (OrderOpenTime() < EarliestTradeTime)
      {
         EarliestTradeTime = OrderOpenTime();
         EarliestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() < EarliestTradeTime)
      
      //All conditions passed, so carry on
      type = OrderType();//Store the order type
      
      
      OpenTrades++;
      //Store the latest trade sent. Most of my EA's only need this final ticket number as either they are single trade
      //bots or the last trade in the sequence is the important one. Adapt this code for your own use.
      if (TicketNo  == -1) TicketNo = OrderTicket();
      
      
      
      //The next line of code calculates the pips upl of an open trade. As yet, I have done nothing with it.
      //something = CalculateTradeProfitInPips()
      
      
      
      //Buile up the position picture of market trades
      if (OrderType() < 2)
      {
         GetBasics(OrderSymbol() );
         pips = CalculateTradeProfitInPips(OrderType());
         PipsUpl[PairIndex]+= pips;
         CashUpl[PairIndex]+= (OrderProfit() + OrderSwap() + OrderCommission()); 
         MarketTradesTotal++;
 
         //Buys
         if (OrderType() == OP_BUY)
         {
            BuyOpen = true;
            BuyTicketNo = OrderTicket();
            MarketBuysCount++;
            
             
            //Latest trade
            if (OrderOpenTime() > LatestBuyTradeTime)
            {
               LatestBuyTradeTime = OrderOpenTime();
               LatestBuyPrice = OrderOpenPrice();
               LatestBuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyTradeTime)
            {
               EarliestBuyTradeTime = OrderOpenTime();
               EarliestBuyPrice = OrderOpenPrice();
               EarliestBuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyPrice)
            {
               HighestBuyPrice = OrderOpenPrice();
               HighestBuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyPrice)
            {
               LowestBuyPrice = OrderOpenPrice();
               LowestBuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyPrice)
              
         }//if (OrderType() == OP_BUY)
         
         //Sells
         if (OrderType() == OP_SELL)
         {
            SellOpen = true;
            SellTicketNo = OrderTicket();
            MarketSellsCount++;
            
            
            //Latest trade
            if (OrderOpenTime() > LatestSellTradeTime)
            {
               LatestSellTradeTime = OrderOpenTime();
               LatestSellPrice = OrderOpenPrice();
               LatestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellTradeTime)
            {
               EarliestSellTradeTime = OrderOpenTime();
               EarliestSellPrice = OrderOpenPrice();
               EarliestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellPrice)
            {
               HighestSellPrice = OrderOpenPrice();
               HighestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellPrice)
            {
               LowestSellPrice = OrderOpenPrice();
               LowestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellPrice)
              
         }//if (OrderType() == OP_SELL)
         
         
      }//if (OrderType() < 2)
      
      
      //Build up the position details of stop/limit orders
      if (OrderType() > 1)
      {
         PendingTradesTotal++;
         //Buystops
         if (OrderType() == OP_BUYSTOP)
         {
            BuyStopOpen = true;
            BuyStopTicketNo = OrderTicket();
            BuyStopsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyStopTradeTime)
            {
               LatestBuyStopTradeTime = OrderOpenTime();
               LatestBuyStopPrice = OrderOpenPrice();
               LatestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyStopTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyStopTradeTime)
            {
               EarliestBuyStopTradeTime = OrderOpenTime();
               EarliestBuyStopPrice = OrderOpenPrice();
               EarliestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyStopTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyStopPrice)
            {
               HighestBuyStopPrice = OrderOpenPrice();
               HighestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyStopPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyStopPrice)
            {
               LowestBuyStopPrice = OrderOpenPrice();
               LowestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyStopPrice)
              
         }//if (OrderType() == OP_BUYSTOP)
         
         //Sellstops
         if (OrderType() == OP_SELLSTOP)
         {
            SellStopOpen = true;
            SellStopTicketNo = OrderTicket();
            SellStopsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestSellStopTradeTime)
            {
               LatestSellStopTradeTime = OrderOpenTime();
               LatestSellStopPrice = OrderOpenPrice();
               LatestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellStopTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellStopTradeTime)
            {
               EarliestSellStopTradeTime = OrderOpenTime();
               EarliestSellStopPrice = OrderOpenPrice();
               EarliestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellStopTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellStopPrice)
            {
               HighestSellStopPrice = OrderOpenPrice();
               HighestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellStopPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellStopPrice)
            {
               LowestSellStopPrice = OrderOpenPrice();
               LowestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellStopPrice)
              
         }//if (OrderType() == OP_SELLSTOP)
         
         //Buy limits
         if (OrderType() == OP_BUYLIMIT)
         {
            BuyLimitOpen = true;
            BuyLimitTicketNo = OrderTicket();
            BuyLimitsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyLimitTradeTime)
            {
               LatestBuyLimitTradeTime = OrderOpenTime();
               LatestBuyLimitPrice = OrderOpenPrice();
               LatestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyLimitTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyLimitTradeTime)
            {
               EarliestBuyLimitTradeTime = OrderOpenTime();
               EarliestBuyLimitPrice = OrderOpenPrice();
               EarliestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyLimitTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyLimitPrice)
            {
               HighestBuyLimitPrice = OrderOpenPrice();
               HighestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyLimitPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyLimitPrice)
            {
               LowestBuyLimitPrice = OrderOpenPrice();
               LowestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyLimitPrice)
              
         }//if (OrderType() == OP_BUYLIMIT)
         
         //Sell limits
         if (OrderType() == OP_SELLLIMIT)
         {
            SellLimitOpen = true;
            SellLimitTicketNo = OrderTicket();
            SellLimitsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestSellLimitTradeTime)
            {
               LatestSellLimitTradeTime = OrderOpenTime();
               LatestSellLimitPrice = OrderOpenPrice();
               LatestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellLimitTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellLimitTradeTime)
            {
               EarliestSellLimitTradeTime = OrderOpenTime();
               EarliestSellLimitPrice = OrderOpenPrice();
               EarliestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellLimitTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellLimitPrice)
            {
               HighestSellLimitPrice = OrderOpenPrice();
               HighestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellLimitPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellLimitPrice)
            {
               LowestSellLimitPrice = OrderOpenPrice();
               LowestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellLimitPrice)
              
         }//if (OrderType() == OP_SELLLIMIT)
         
      
      }//if (OrderType() > 1)
      
      
      //Maximum spread. We do not want any trading operations  during a wide spread period
      if (!SpreadCheck(PairIndex) ) 
         continue;
      
      
      if (CloseEnough(OrderStopLoss(), 0) && !CloseEnough(StopLoss, 0)) InsertStopLoss(OrderTicket());
      if (CloseEnough(OrderTakeProfit(), 0) && !CloseEnough(TakeProfit, 0)) InsertTakeProfit(OrderTicket() );
      
      
      TradeWasClosed = false;
      if (!AreWeAtRollover())
         TradeWasClosed = LookForTradeClosure(OrderTicket(), PairIndex);
      if (TradeWasClosed) 
      {
         if (type == OP_BUY) BuyOpen = false;//Will be reset if subsequent trades are buys that are not closed
         if (type == OP_SELL) SellOpen = false;//Will be reset if subsequent trades are sells that are not closed
         cc++;
         continue;
      }//if (TradeWasClosed)

      //Profitable trade management
      if (OrderProfit() > 0) 
      {
         TradeManagementModule(OrderTicket() );
      }//if (OrderProfit() > 0) 
      
               
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   

   
   
    
}//End void CountOpenTrades();
//+------------------------------------------------------------------+

void RemoveTakeProfits(string symbol)
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

      if (!CloseEnough(OrderTakeProfit(), 0) )
         ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), 0, 
                     OrderExpiration(), clrNONE, __FUNCTION__, tpm);
      
      
  
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

}//void RemoveTakeProfits()

void RemoveStopLosses(string symbol)
{

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

      if (!CloseEnough(OrderStopLoss(), 0) )
         ModifyOrder(OrderTicket(), OrderOpenPrice(), 0, OrderTakeProfit(), 
                     OrderExpiration(), clrNONE, __FUNCTION__, tpm);
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

}//void RemoveStopLosses()

void InsertStopLoss(int ticket)
{
   //Inserts a stop loss if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if StopLoss > 0 && OrderStopLoss() == 0.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (OrderStopLoss() > 0) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double stop = 0;
   
   if (OrderType() == OP_BUY)
   {
      stop = CalculateStopLoss(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      stop = CalculateStopLoss(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (CloseEnough(stop, 0) ) return;
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" InsertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" InsertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 

   
   if (!CloseEnough(stop, OrderStopLoss())) 
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!CloseEnough(stop, OrderStopLoss())) 

}//End void InsertStopLoss(int ticket)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InsertTakeProfit(int ticket)
{
   //Inserts a TP if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if TakeProfit > 0 && OrderTakeProfit() == 0.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (!CloseEnough(OrderTakeProfit(), 0) ) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double take = 0;
   
   if (OrderType() == OP_BUY)
   {
      take = CalculateTakeProfit(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      take = CalculateTakeProfit(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (CloseEnough(take, 0) ) return;
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice()  && !CloseEnough(take, 0) ) 
   {
      take = 0;
      ReportError(" InsertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      ReportError(" InsertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   
   if (!CloseEnough(take, OrderTakeProfit()) ) 
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!CloseEnough(take, OrderTakeProfit()) ) 

}//End void InsertTakeProfit(int ticket)

bool LookForTradeClosure(int ticket, int PairIndex)
{
   //Close the trade if the close conditions are met.
   //Called from within CountOpenTrades(). Returns true if a close is needed and succeeds, so that COT can increment cc,
   //else returns false


   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (BetterOrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   bool CloseThisTrade = false;
   
   //I have left the tpsl code in case non GP members need stealth
   double take = OrderTakeProfit();
   double stop = OrderStopLoss();
   
        
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (!CloseThisTrade)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         //TP
         if (bid >= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
         //SL
         if (bid <= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;
   
         //SS has closed red
         if (HtfSsStatus[PairIndex] == red)
         {
            //Complete opposite direction signal
            if (PeakyStatus[PairIndex] == peakyshorttradable)
               CloseThisTrade = true;
         
            //Market trade
            if (!CloseThisTrade)
               if (OrderType() < 2)
                  if (CloseMarketTradesOnOppositeSignal)
                     CloseThisTrade = true;
                     
            //Pending trade
            if (!CloseThisTrade)
               if (OrderType() > 1)
                  if (OrderType() < 6)
                     if (DeletePendingTradesOnOppositeSignal)
                        CloseThisTrade = true;
                        
               
         }//if (HtfSsStatus[PairIndex] == red)
         
         
         
           
      }//if (OrderType() == OP_BUY)
      
      
      ///////////////////////////////////////////////////////////////////////////////////////////////////////////
      if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
      {
         //TP
         if (bid <= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
         //SL
         if (bid >= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;
   
   
         //SS has closed blue
         if (HtfSsStatus[PairIndex] == blue)
         {
            //Complete opposite direction signal
            if (PeakyStatus[PairIndex] == peakylongtradable)
               CloseThisTrade = true;
         
            //Market trade
            if (!CloseThisTrade)
               if (OrderType() < 2)
                  if (CloseMarketTradesOnOppositeSignal)
                     CloseThisTrade = true;
                     
            //Pending trade
            if (!CloseThisTrade)
               if (OrderType() > 1)
                  if (OrderType() < 6)
                     if (DeletePendingTradesOnOppositeSignal)
                        CloseThisTrade = true;
                        
               
         }//if (HtfSsStatus[PairIndex] == blue)
         
         
            
      }//if (OrderType() == OP_SELL)
   }//if (!CloseThisTrade)
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (CloseThisTrade)
   {
      bool result = false;
      
      if (OrderType() < 2)//Market orders
         result = CloseOrder(ticket);
      else
         result = OrderDelete(ticket, clrNONE);
            
      //Actions when trade close succeeds
      if (result)
      {
         TicketNo = -1;//TicketNo is the most recently trade opened, so this might need editing in a multi-trade EA
         OpenTrades--;//Rather than OpenTrades = 0 to cater for multi-trade EA's
         return(true);//Makes CountOpenTrades increment cc to avoid missing out ccounting a trade
      }//if (result)
   
      //Actions when trade close fails
      if (!result)
      {
         return(false);//Do not increment cc
      }//if (!result)
   }//if (CloseThisTrade)
   
   //Got this far, so no trade closure
   return(false);//Do not increment cc
   
}//End bool LookForTradeClosure()

double CalculateStopLoss(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop = 0;

   RefreshRates();
   

   
   if (type == OP_BUY)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         stop = price - (StopLoss / factor);
         //HiddenStopLoss = stop;
      }//if (!CloseEnough(StopLoss, 0) ) 

      //if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop - (HiddenPips / factor), Digits);
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         stop = price + (StopLoss / factor);
         //HiddenStopLoss = stop;         
      }//if (!CloseEnough(StopLoss, 0) ) 
      
      //if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop + (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(stop);
   
}//End double CalculateStopLoss(int type)

double CalculateTakeProfit(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double take = 0;

   RefreshRates();
   
   
   if (type == OP_BUY)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         take = price + (TakeProfit / factor);
         //HiddenTakeProfit = take;
      }//if (!CloseEnough(TakeProfit, 0) )

               
      //if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take + (HiddenPips / factor), Digits);

   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         take = price - (TakeProfit / factor);
         //HiddenTakeProfit = take;         
      }//if (!CloseEnough(TakeProfit, 0) )
      
      
      //if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take - (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(take);
   
}//End double CalculateTakeProfit(int type)

bool CloseOrder(int ticket)
{   
   while(IsTradeContextBusy()) Sleep(100);
   bool orderselect=BetterOrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
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
      ReportError(" CloseOrder()", ocm);
      return(false);
   }//if (!result)
   
   return(false);
}//End bool CloseOrder(ticket)

//+------------------------------------------------------------------+
//| NormalizeLots(string symbol, double lots)                        |
//+------------------------------------------------------------------+
//function added by fxdaytrader
//Lot size must be adjusted to be a multiple of lotstep, which may not be a power of ten on some brokers
//see also the original function by WHRoeder, http://forum.mql4.com/45425#564188, fxdaytrader
double NormalizeLots(string symbol,double lots)
{
   if(MathAbs(lots)==0.0) return(0.0); //just in case ... otherwise it may happen that after rounding 0.0 the result is >0 and we have got a problem, fxdaytrader
   double ls=MarketInfo(symbol,MODE_LOTSTEP);
   lots=MathMin(MarketInfo(symbol,MODE_MAXLOT),MathMax(MarketInfo(symbol,MODE_MINLOT),lots)); //check if lots >= min. lots && <= max. lots, fxdaytrader
   return(MathRound(lots/ls)*ls);
}
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
//TRADE MANAGEMENT MODULE


void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   
}//void ReportError()

bool ModifyOrder(int ticket, double price, double stop, double take, datetime expiry, color col, string function, string reason)
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
      ReportError(function, reason);

   //Got this far, so modify failed
   return(false);
   
}// End bool ModifyOrder()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BreakEvenStopLoss(int ticket) // Move stop loss to breakeven
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
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
      if (bid >= OrderOpenPrice () + (BreakEvenPips / factor) )          
      {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()+(BreakEvenProfit / factor), digits);
         modify = true;   
      }//if (bid >= OrderOpenPrice () + (Point*BreakEvenPips) && 
   }//if (OrderType()==OP_BUY)               			         
    
   if (OrderType()==OP_SELL)
   {
     //if (HiddenPips > 0) target+= (HiddenPips / factor);
     if (OrderStopLoss() <= target && OrderStopLoss() > 0) return;
     if (ask <= OrderOpenPrice() - (BreakEvenPips / factor) ) 
     {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()-(BreakEvenProfit / factor), digits);
         modify = true;   
     }//if (ask <= OrderOpenPrice() - (Point*BreakEvenPips) && (OrderStopLoss()>OrderOpenPrice()|| OrderStopLoss()==0))     
   }//if (OrderType()==OP_SELL)

   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      if (NewStop == OrderStopLoss() ) return;
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (!result)
         Sleep(10000);//10 seconds before trying again
         
      while (IsTradeContextBusy() ) Sleep(100);
      if (PartCloseEnabled && OrderComment() == TradeComment) bool success = PartCloseOrder(OrderTicket() );
   }//if (modify)
   
} // End BreakevenStopLoss sub

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PartCloseOrder(int ticket)
{
   //Close PartClosePercent of the initial trade.
   //Return true if close succeeds, else false
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) return(true);//in case the trade closed
   
   bool Success = false;
   double CloseLots = NormalizeLots(OrderSymbol(),OrderLots() * (PartClosePercent / 100));
   
   Success = OrderClose(ticket, CloseLots, OrderClosePrice(), 1000, Blue); //fxdaytrader, NormalizeLots(...
   if (Success) TradeHasPartClosed = true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.
   if (!Success) 
   {
       //mod. fxdaytrader, orderclose-retry if failed with ordercloseprice(). Maybe very seldom, but it can happen, so it does not hurt to implement this:
       while(IsTradeContextBusy()) Sleep(100);
       RefreshRates();
       if (OrderType()==OP_BUY) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_BID), 5000, Blue);
       if (OrderType()==OP_SELL) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_ASK), 5000, Blue);
       //end mod.  
       //original:
       if (Success) TradeHasPartClosed = true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.
   
       if (!Success) 
       {
         ReportError(" PartCloseOrder()", pcm);
         return (false);
       } 
   }//if (!Success) 
      
   //Got this far, so closure succeeded
   return (true);   

}//bool PartCloseOrder(int ticket)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void JumpingStopLoss(int ticket)
{
  // Jump sl by pips and at intervals chosen by user .

   //Thomas substantially rewrote this function. Many thanks, Thomas.
   
  //Security check
  if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     return;

  //if (OrderProfit() < 0) return;//Nothing to do
  double sl = OrderStopLoss();
  
  //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
  double NewStop = 0;
  bool modify=false;
  bool result = false;
  
  double JSWidth=JumpingStopPips/factor;//Thomas
  int JSMultiple;//Thomas
  
   if (OrderType()==OP_BUY)
   {
      if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
      // Increment sl by sl + JumpingStopPips.
      // This will happen when market price >= (sl + JumpingStopPips)
      //if (Bid>= sl + ((JumpingStopPips*2) / factor) )
      if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
      if (bid >= sl + (JSWidth * 2))//Thomas
      {
         JSMultiple = (int)floor((bid-sl)/(JSWidth))-1;//Thomas
         NewStop = NormalizeDouble(sl + (JSMultiple*JSWidth), digits);//Thomas
         if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
      }// if (bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())    
   }//if (OrderType()==OP_BUY)
      
      if (OrderType()==OP_SELL)
      {
         if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
         // Decrement sl by sl - JumpingStopPips.
         // This will happen when market price <= (sl - JumpingStopPips)
         //if (bid<= sl - ((JumpingStopPips*2) / factor)) Original code
         if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
         if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
         if (bid <= sl - (JSWidth * 2))//Thomas
         {
            JSMultiple = (int)floor((sl-bid)/(JSWidth))-1;//Thomas
            NewStop = NormalizeDouble(sl - (JSMultiple*JSWidth), digits);//Thomas
            if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy  
         }// close if (bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())        
      }//if (OrderType()==OP_SELL)

  //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
  if (modify)
  {
     while (IsTradeContextBusy() ) Sleep(100);
     result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);      
  }//if (modify)

} //End of JumpingStopLoss
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStopLoss(int ticket)
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   if (OrderProfit() < 0) return;//Nothing to do
   double sl = OrderStopLoss();
   
   double NewStop = 0;
   bool modify=false;
   bool result = false;
   
    if (OrderType()==OP_BUY)
       {
          if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
          // Increment sl by sl + TrailingStopPips.
          // This will happen when market price >= (sl + JumpingStopPips)
          //if (bid>= sl + (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
          if (bid >= sl + (TrailingStopPips / factor) )//George
          {
             NewStop = NormalizeDouble(sl + (TrailingStopPips / factor), digits);
             if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
          }//if (bid >= MathMax(sl,OrderOpenPrice()) + (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - TrailingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (bid<= sl - (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (bid <= sl  - (TrailingStopPips / factor))//George
          {
             NewStop = NormalizeDouble(sl - (TrailingStopPips / factor), digits);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }//if (bid <= MathMin(sl, OrderOpenPrice() ) - (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_SELL)


   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
   }//if (modify)
      
} // End of TrailingStopLoss sub
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CandlestickTrailingStop(int ticket)
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   //Trails the stop at the hi/lo of the previous candle shifted by the user choice.
   //Only tries to do this once per bar, so an invalid stop error will only be generated once. I could code for
   //a too-close sl, but cannot be arsed. Coders, sort this out for yourselves.
   
   string symbol = OrderSymbol();
   
   if (OldCstBars == iBars(symbol, CstTimeFrame)) return;
   OldCstBars = iBars(symbol, CstTimeFrame);

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
         if (NewStop < OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
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
         if (NewStop > OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop > OrderOpenPrice() ) return;
         
         modify = true;   
      }//if (iHigh(symbol, CstTimeFrame, CstTrailCandles) < sl)
   }//if (OrderType() == OP_SELL)
   
   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (!result) 
      {
         OldCstBars = 0;
      }//if (!result) 
      
   }//if (modify)

}//End void CandlestickTrailingStop()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeManagementModule(int ticket)
{

     
   // Call the working subroutines one by one. 

   //Candlestick trailing stop
   if(UseCandlestickTrailingStop) CandlestickTrailingStop(ticket);

   // Breakeven
   if(BreakEven) BreakEvenStopLoss(ticket);

   // JumpingStop
   if(JumpingStop) JumpingStopLoss(ticket);

   //TrailingStop
   if(TrailingStop) TrailingStopLoss(ticket);


}//void TradeManagementModule()
//END TRADE MANAGEMENT MODULE
////////////////////////////////////////////////////////////////////////////////////////


void CountTradesForDashboard(string symbol)
{

   OpenTrades=0;
   OpenLongTrades=0;
   OpenShortTrades=0;
   
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
      
      OpenTrades++;
      
      if (OrderType()==OP_BUY)
         OpenLongTrades++;
         
      if (OrderType()==OP_SELL)
         OpenShortTrades++;
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
}//End void CountOpenTrades()


void CountClosedTradesForDashboard(string symbol)
{

   ClosedTrades=0;
   ClosedLongTrades=0;
   ClosedShortTrades=0;
   
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
      
      ClosedTrades++;
      
      if (OrderType()==OP_BUY)
         ClosedLongTrades++;
         
      if (OrderType()==OP_SELL)
         ClosedShortTrades++;
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
}//End void CountOpenTrades()


bool chartMinimize(long chartID = 0) 
{

   //This code was provided by Rene. Many thanks Rene.
   
   if (chartID == 0) chartID = ChartID();
   
   int chartHandle = (int)ChartGetInteger( chartID, CHART_WINDOW_HANDLE, 0 );
   int chartParent = GetParent(chartHandle);
   
   return( ShowWindow( chartParent, SW_FORCEMINIMIZE ) );
}//End bool chartMinimize(long chartID = 0) 

void ShrinkCharts()
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

}//End void ShrinkCharts()


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
         
         OpenChart(pair,tf);
         return;
      }
      
      else if(StringFind(sparam,"OAM-SWITCH")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         SwitchDisplays();
         return;
      }
      
      else if(StringFind(sparam,"OAM-HIDEPIPS")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         HidePipsDetails=!HidePipsDetails;
         removeAllObjects();
         DisplayUserFeedback();
         return;
      }
      
      
      else if(StringFind(sparam,"OAM-HIDECASH")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         HideCashDetails=!HideCashDetails;
         removeAllObjects();
         DisplayUserFeedback();
         return;
      }
      
      
      else if(StringFind(sparam,"OAM-HIDESWAP")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         HideSwapDetails=!HideSwapDetails;
         removeAllObjects();
         DisplayUserFeedback();
         return;
      }
      
      
      else if(StringFind(sparam,"OAM-HIDESPREAD")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         HideSpreadDetails=!HideSpreadDetails;
         removeAllObjects();
         DisplayUserFeedback();
         return;
      }
      
      
      else if(StringFind(sparam,"OAM-OPENALL")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         OpenCharts();
         return;
      }
      
      else if(StringFind(sparam,"OAM-OPENTRADES")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         OpenTrades();
         return;
      }
      
      else if(StringFind(sparam,"OAM-TOUCH")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         TouchCharts();
         return;
      }
      
      else if(StringFind(sparam,"OAM-CLOSE")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         CloseCharts();
         return;
      }

}//End void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)

void OpenChart(string pair,int tf)
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
         DrawTradeArrows(pair,nextchart);
         return;
      }
   }
   while((nextchart=ChartNext(nextchart))!=-1);
   
   //Chart not found, so open a new one
   long newchartid=ChartOpen(pair,tf);
   ChartApplyTemplate(newchartid,TemplateName);
   ChartRedraw(newchartid);
   ChartNavigate(newchartid,CHART_END,0);
   DrawTradeArrows(pair,newchartid);
   
   TimerCount=1;//Restart timer to keep it from closing too early
  
}//End void OpenChart(string pair,int tf)
 

void SwitchDisplays()
{
   if (WhatToShow=="AllPairs")
      WhatToShow="TradablePairs";
   else if (WhatToShow=="TradablePairs")
      WhatToShow="OpenTrades";
   else if (WhatToShow=="OpenTrades")
      WhatToShow="ClosedTrades";
   else if (WhatToShow=="ClosedTrades")
      WhatToShow="AllTrades";
   else if (WhatToShow=="AllTrades")
      WhatToShow="AllPairs";
   removeAllObjects();
   DisplayUserFeedback();
}//End void SwitchDisplays()


void OpenCharts()
{
   CloseCharts();

   //Open chart for each tradepair
   for (int cc=0;cc<=ArraySize(TradePair)-1;cc++)
   {
      OpenChart(TradePair[cc],ChartTimeFrame);
   }
   
   //Make the dashboard the active chart again
   ChartSetInteger(ChartID(),CHART_BRING_TO_TOP,true);
   
   return;
   
}//End void OpenCharts()


void OpenTrades()
{
   CloseCharts();

   //Open chart for each tradepair with open trades
   for (int cc=0;cc<=ArraySize(TradePair)-1;cc++)
   {
      CountTradesForDashboard(TradePair[cc]);
      if (OpenTrades>0)
         OpenChart(TradePair[cc],ChartTimeFrame);
   }
   
   //Make the dashboard the active chart again
   ChartSetInteger(ChartID(),CHART_BRING_TO_TOP,true);
   
   return;
   
}//End void OpenCharts()


void CloseCharts()
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
   
}//End void CloseCharts()


void TouchCharts()
{
   //Touch the charts backwards for proper CTRL-F6 chart browsing
   for (int cc=ArraySize(TradePair)-1; cc>=0; cc--)
   {
      long nextchart=ChartFirst();
      do
      {
         if(ChartSymbol(nextchart)==TradePair[cc] && nextchart!=ChartID())
         {
            ChartSetInteger(nextchart,CHART_BRING_TO_TOP,true);
            continue;
         }
      }
      while((nextchart=ChartNext(nextchart))!=-1);
   }
   
}//End void TouchCharts()


bool EnoughDistance(string symbol, int type, double price)
{
   //Returns false if the is < MinDistanceBetweenTradesPips
   //between the price and the nearest order open prices.
   
   double pips = 0;
   
   //No market order yet
   if (type == OP_BUY)
      if (!BuyOpen)
         return(true);
      
   if (type == OP_SELL)
      if (!SellOpen)
         return(true);
      
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      if (OrderSymbol() != symbol ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() != type) continue;

      pips = MathAbs(price - OrderOpenPrice() ) * factor;
      if (pips < MinDistanceBetweenTrades)
         return(false);
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

 
   //Got here, so OK to trade
   return(true);

   

}//End bool EnoughDistance(int type, double price)

double CalculateLotSize(string symbol, double price1,double price2)
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
         CalculateDynamicBasketCashTP(LotSize);
   
   
   return(LotSize);

}//double CalculateLotSize(double price1, double price1)

void LookForTradingOpportunities(string symbol, int PairIndex)
{
//return;//TEMPORARY. REMOVE LATER
   
   GetBasics(symbol);
   double take = 0, stop = 0, price = 0;
   int type = 0;
   bool SendTrade = false, result = false;

   double SendLots = Lot;
   //Check filters
   if (!IsTradingAllowed(symbol, PairIndex) ) return;
   
   /////////////////////////////////////////////////////////////////////////////////////
   
   //Trading decision.
   bool SendLong = false, SendShort = false;

   //Long trade
   
   //Specific system filters
   if (BuySignal[PairIndex]) 
      SendLong = true;
   
   //Usual filters
   if (SendLong)
   {
      //User choice of trade direction
      if (!TradeLong) return;

      if (UseZeljko && !BalancedPair(symbol, OP_BUY) ) return;
      
      //Change of market state - explanation at the end of start()
      //if (OldAsk <= some_condition) SendLong = false;   
   }//if (SendLong)
   
   /////////////////////////////////////////////////////////////////////////////////////

   if (!SendLong)
   {
      //Short trade
      //Specific system filters
      if (SellSignal[PairIndex]) 
         SendShort = true;
      
      if (SendShort)
      {      
         //Usual filters

         //User choice of trade direction
         if (!TradeShort) return;

         //Other filters
           
         if (UseZeljko && !BalancedPair(symbol, OP_SELL) ) return;
         
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
         
      stop = CalculateStopLoss(OP_BUY, price);
         
         
      take = CalculateTakeProfit(OP_BUY, price);
      
      
      //Lot size calculated by risk
      if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(symbol, price, stop );

               
      SendTrade = true;
      
   }//if (SendLong)
   
   //Short
   if (SendShort)
   {
      
      type=OP_SELL;
      price = NormalizeDouble(MarketInfo(symbol, MODE_BID), digits);

      stop = CalculateStopLoss(OP_SELL, price);
         
      take = CalculateTakeProfit(OP_SELL, price);
      
      
      //Lot size calculated by risk
      if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(symbol, price, stop);

      
         
      SendTrade = true;      
   
      
   }//if (SendShort)
   

   if (SendTrade)
   {
      
      result = true;//Allow sending the grid if not sending an immediate market trade
      
      if (SendImmediateMarketTrade)
         result = SendSingleTrade(symbol, type, TradeComment, SendLots, price, stop, take);
      
      if (result)
      {
         //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so tell the
         //ea not to trade for a while, to give time for the trade receipt to return from the server.
         TimeToStartTrading[PairIndex] = TimeCurrent() + PostTradeAttemptWaitSeconds;
        
              
         if (BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES) )
            CheckTpSlAreCorrect(type);
            
         if (GridSize > 0)
         {
            if (type == OP_BUY || type == OP_BUYSTOP)
               SendBuyGrid(symbol, OP_BUYSTOP, price, SendLots, TradeComment);
            else
               SendSellGrid(symbol, OP_SELLSTOP, price, SendLots, TradeComment);
               
         }//if (GridSize > 0)
         
      }//if (result)          
   

      
      //Actions when trade send fails
      if (SendTrade && !result)
      {
         OldTtfIndiReadBarTime[PairIndex] = 0;
      }//if (!result)
      
   }//if (SendTrade)   
   

}//End void LookForTradingOpportunities(string symbol, int PairIndex)

bool BalancedPair(string symbol, int type)
{

   //Only allow an individual currency to trade if it is a balanced trade
   //e.g. UJ Buy open, so only allow Sell xxxJPY.
   //The passed parameter is the proposed trade, so an existing one must balance that

   //This code courtesy of Zeljko (zkucera) who has my grateful appreciation.
   
   string BuyCcy1, SellCcy1, BuyCcy2, SellCcy2;

   if (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT)
   {
      BuyCcy1 = StringSubstrOld(symbol, 0, 3);
      SellCcy1 = StringSubstrOld(symbol, 3, 3);
   }//if (type == OP_BUY || type == OP_BUYSTOP)
   else
   {
      BuyCcy1 = StringSubstrOld(symbol, 3, 3);
      SellCcy1 = StringSubstrOld(symbol, 0, 3);
   }//else

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS)) continue;
      if (OrderSymbol() == symbol) continue;
      if (OrderMagicNumber() != MagicNumber) continue;      
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || type == OP_BUYLIMIT)
      {
         BuyCcy2 = StringSubstrOld(OrderSymbol(), 0, 3);
         SellCcy2 = StringSubstrOld(OrderSymbol(), 3, 3);
      }//if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      else
      {
         BuyCcy2 = StringSubstrOld(OrderSymbol(), 3, 3);
         SellCcy2 = StringSubstrOld(OrderSymbol(), 0, 3);
      }//else
      if (BuyCcy1 == BuyCcy2 || SellCcy1 == SellCcy2) return(false);
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so it is ok to send the trade
   return(true);

}//End bool BalancedPair(int type)

bool CloseEnough(double num1,double num2)
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

}//End bool CloseEnough(double num1, double num2)

double CalculateTradeProfitInPips(int type)
{
   //This code supplied by Lifesys. Many thanks Paul.
   
   //Returns the pips Upl of the currently selected trade. Called by CountOpenTrades()
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
}//double CalculateTradeProfitInPips(int type)

bool DoesTradeExist(string symbol, int type,double price)
{

   if(OrdersTotal()==0)
      return(false);
   if(OpenTrades==0)
      return(false);


   for(int cc=OrdersTotal()-1; cc>=0; cc--)
   {
      if(!OrderSelect(cc,SELECT_BY_POS)) continue;
      if(OrderSymbol()!=symbol) continue;
      if(OrderMagicNumber()!=MagicNumber) continue;
      if(OrderType()!=type) continue;
      if(!CloseEnough(OrderOpenPrice(),price)) continue;

      //Got to here, so we have found a trade
      return(true);

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

//Got this far, so no trade found
   return(false);

}//End bool DoesTradeExist(string symbol, int type,double price)

void SendBuyGrid(string symbol,int type,double price,double lot,string comment) //MJB
{
//Send a grid of stop orders using the passed parameters
   double stop = 0;
   double take = 0;
   bool result = false;

   
   GetBasics(symbol);//Just in case these have got scrambled.
   
   //Atr for grid size
   if (UseAtrForGrid)
   {
      double val = GetAtr(symbol, GridAtrTimeFrame, GridAtrPeriod, 0);
      DistanceBetweenTrades = (val * factor) * GridAtrMultiplier;
   }//if (UseAtrForGrid)
   
   //Set the initial trade price
   price=NormalizeDouble(price+(DistanceBetweenTrades/factor),digits);
   
   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<GridSize; cc++)
   {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      if(DoesTradeExist(symbol,type,price))
      {
         //Increment the price for the next pending
         if(type==OP_BUYSTOP)
            price=NormalizeDouble(price+(DistanceBetweenTrades/factor),digits);
         
         continue;
      }//if (DoesTradeExist(OP_BUYSTOP, price))

      stop = CalculateStopLoss(OP_BUY, price);
      take = CalculateTakeProfit(OP_BUY, price);

      if(!IsExpertEnabled())
      {
         Comment("                          EXPERTS DISABLED");
         return;
      }//if (!IsExpertEnabled() )

      result=true;
      //TradeComment is defined either in ReadIndicatorValues,
      //and subsequently in CountOpenTrades()
      result=SendSingleTrade(symbol,type,comment,lot,price,stop,take); //MJB

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

      price=NormalizeDouble(price+(DistanceBetweenTrades/factor),digits);
      
      Sleep(500);

   }//for (int cc = 0; cc < GridSize; cc++)


}//End void SendBuyGrid(string symbol, double price, double lot)

void SendSellGrid(string symbol,int type,double price,double lot,string comment) //MJB
{
   //Send a grid of stop orders using the passed parameters
   double stop = 0;
   double take = 0;
   bool result = false;

   GetBasics(symbol);//Just in case these have got scrambled.
   
   //Atr for grid size
   if (UseAtrForGrid)
   {
      double val = GetAtr(symbol, GridAtrTimeFrame, GridAtrPeriod, 0);
      DistanceBetweenTrades = (val * factor) * GridAtrMultiplier;
   }//if (UseAtrForGrid)

   //Set the initial trade price
   price = NormalizeDouble(bid - (DistanceBetweenTrades / factor), digits);
   
   int tries=0;//To break out of an infinite loop

   for(int cc=0; cc<GridSize; cc++)
   {
      tries++;
      if(tries>=100)
         break;

      //Check the trade has not already been sent
      if(DoesTradeExist(symbol,type,price))
      {
         //Increment the price for the next pending
         price=NormalizeDouble(price -(DistanceBetweenTrades/factor),digits);

         continue;
      }//if (DoesTradeExist(OP_SELLSTOP, price))

      stop = CalculateStopLoss(OP_SELL, price);
      take = CalculateTakeProfit(OP_SELL, price);

      if(!IsExpertEnabled())
      {
         Comment("                          EXPERTS DISABLED");
         return;
      }//if (!IsExpertEnabled() )

      result=true;
      //TradeComment is defined either in ReadIndicatorValues,
      //and subsequently in CountOpenTrades()
      result=SendSingleTrade(symbol,type,comment,lot,price,stop,take); //MJB

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
      price=NormalizeDouble(price -(DistanceBetweenTrades/factor),digits);

      Sleep(500);

     }//for (int cc = 0; cc < GridSize; cc++)



}//End void SendSellGrid(string symbol, double price, double lot)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendSingleTrade(string symbol,int type,string comment,double lotsize,double price,double stop,double take)
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
            ModifyOrderTpSl(ticket,stop,take);
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

   TicketNo=ticket;
   //Make sure the trade has appeared in the platform's history to avoid duplicate trades.
   //My mod of Matt's code attempts to overcome the bastard crim's attempts to overcome Matt's code.
   bool TradeReturnedFromCriminal=false;
   while(!TradeReturnedFromCriminal)
     {
      TradeReturnedFromCriminal=O_R_CheckForHistory(ticket);
      if(!TradeReturnedFromCriminal)
        {
         Alert(symbol," sent trade not in your trade history yet. Turn of this ea NOW.");
        }//if (!TradeReturnedFromCriminal)
     }//while (!TradeReturnedFromCriminal)

   //Got this far, so trade send succeeded
   return(true);

}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyOrderTpSl(int ticket, double stop, double take)
{
   //Modifies an order already sent if the crim is ECN.

   if (CloseEnough(stop, 0) && CloseEnough(take, 0) ) return; //nothing to do

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return;//Trade does not exist, so no mod needed
   
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice() && !CloseEnough(take, 0) ) 
   {
      take = 0;
      ReportError(" ModifyOrder()", " take profit < market ");
      return;
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      ReportError(" ModifyOrder()", " take profit < market ");
      return;
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" ModifyOrder()", " stop loss > market ");
      return;
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice()  && !CloseEnough(stop, 0) ) 
   {
      stop = 0;
      ReportError(" ModifyOrder()", " stop loss < market ");
      return;
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   string Reason;
   //RetryCount is declared as 10 in the Trading variables section at the top of this file   
   for (int cc = 0; cc < RetryCount; cc++)
   {
      for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);
        if (!CloseEnough(take, 0) && !CloseEnough(stop, 0) )
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), stop, take, OrderExpiration(), clrNONE, __FUNCTION__, tpsl)) return;
        }//if (take > 0 && stop > 0)
   
        if (!CloseEnough(take, 0) && CloseEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm)) return;
        }//if (take == 0 && stop != 0)

        if (CloseEnough(take, 0) && !CloseEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm)) return;
        }//if (take == 0 && stop != 0)
   }//for (int cc = 0; cc < RetryCount; cc++)
   
   
   
}//void ModifyOrderTpSl(int ticket, double tp, double sl)

//=============================================================================
//                           O_R_CheckForHistory()
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
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2010
//
//=============================================================================
bool O_R_CheckForHistory(int ticket)
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
         if(BetterOrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true) 
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
            if(BetterOrderSelect(c,SELECT_BY_POS,MODE_HISTORY)==true) 
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
      if(cnt>O_R_Setting_max_retries) 
        {
         exit_loop=true;
        }
      if(!(success || exit_loop)) 
        {
         Print("Did not find #"+IntegerToString(ticket)+" in history, sleeping, then doing retry #"+IntegerToString(cnt));
         O_R_Sleep(O_R_Setting_sleep_time,O_R_Setting_sleep_max);
        }
     }
// Select back the prior ticket num in case caller was using it.
   if(lastTicket>=0) 
     {
      bool s = BetterOrderSelect(lastTicket,SELECT_BY_TICKET,MODE_TRADES);
     }
   if(!success) 
     {
      Print("Never found #"+IntegerToString(ticket)+" in history! crap!");
     }
   return(success);
  }//End bool O_R_CheckForHistory(int ticket)
//=============================================================================
//                              O_R_Sleep()
//
//  This sleeps a random amount of time defined by an exponential
//  probability distribution. The mean time, in Seconds is given
//  in 'mean_time'.
//  This returns immediately if we are backtesting
//  and does not sleep.
//
//=============================================================================
void O_R_Sleep(double mean_time, double max_time)
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
}//End void O_R_Sleep(double mean_time, double max_time)

////////////////////////////////////////////////////////////////////////////////////////

void CheckTpSlAreCorrect(int type)
{
   //Looks at an open trade and checks to see that the exact tp/sl were sent with the trade.
   
   
   double stop = 0, take = 0, diff = 0;
   bool ModifyStop = false, ModifyTake = false;
   bool result;
   
   //Is the stop at BE?
   if (type == OP_BUY && OrderStopLoss() >= OrderOpenPrice() ) return;
   if (type == OP_SELL && OrderStopLoss() <= OrderOpenPrice() ) return;
   
   if (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderOpenPrice() - OrderStopLoss()) * factor;
         if (!CloseEnough(diff, StopLoss) ) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderTakeProfit() - OrderOpenPrice()) * factor;
         if (!CloseEnough(diff, TakeProfit) ) 
         {
            ModifyTake = true;
            take = CalculateTakeProfit(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, TakeProfit) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_BUY)
   
   if (type == OP_SELL || type == OP_SELLSTOP || type == OP_SELLLIMIT)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderStopLoss() - OrderOpenPrice() ) * factor;
         if (!CloseEnough(diff, StopLoss) ) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_SELL, OrderOpenPrice());

         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderOpenPrice() - OrderTakeProfit() ) * factor;
         if (!CloseEnough(diff, TakeProfit) ) 
         {
            ModifyTake = true;
            take = CalculateTakeProfit(OP_SELL, OrderOpenPrice());
         }//if (!CloseEnough(diff, TakeProfit) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_SELL)
   
   if (ModifyStop)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (ModifyStop)
   
   if (ModifyTake)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm);
   }//if (ModifyStop)
   

}//void CheckTpSlAreCorrect(int type)


void CloseAllTrades(string symbol, int type)
{
   ForceTradeClosure= false;
  
   
   if (OrdersTotal() == 0) return;
   
   //For US traders
   if (MustObeyFIFO)
   {
      CloseAllTradesFIFO(symbol, type);
      return;
   }//if (MustObeyFIFO)
      

   bool result = false;
   for (int pass = 0; pass <= 1; pass++)
   {
      
      for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
      {
         if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
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
               OpenTrades--;
            }//(result) 
            
            if (!result) ForceTradeClosure= true;
         }//if (OrderType() < 2)
         
         if (pass == 1)
            if (OrderType() > 1) 
            {
               result = OrderDelete(OrderTicket(), clrNONE);
               if (result) 
               {
                  cc++;
                  OpenTrades--;
               }//(result) 
               if (!result) ForceTradeClosure= true;
            }//if (OrderType() > 1) 
            
      }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   }//for (int pass = 0; pass <= 1; pass++)
   
  
}//End void CloseAllTrades(string symbol, int type)

void CloseAllTradesFIFO(string symbol, int type)
{
   ForceTradeClosure= false;
   
   if (OrdersTotal() == 0) return;

   bool result = false;
   for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
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
         
         if (!result) ForceTradeClosure= true;
      }//if (OrderType() < 2)
      
      if (OrderType() > 1) 
      {
         result = OrderDelete(OrderTicket(), clrNONE);
         if (result) 
         {
            cc++;
         }//(result) 
         if (!result) ForceTradeClosure= true;
      }//if (OrderType() > 1) 
      
   }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)


}//End void CloseAllTradesFIFO(string symbol, int type)

void ShutDownForTheWeekend()
{

   //Close/delete all trades to be flat for the weekend.
   
   int day = TimeDayOfWeek(TimeLocal() );
   int hour = TimeHour(TimeLocal() );
   bool CloseDelete = false;
   
   //Friday
   if (day == 5)
   {
      if (hour >= FridayCloseAllHour)
         if (TotalCashUpl >= MaxAllowableCashLoss)//MaxAllowableCashLoss is a negative number
            CloseDelete = true;
   }//if (day == 5)
 
   //Saturday
   if (day == 6)
   {
      if (hour >= SaturdayCloseAllHour)
         if (TotalCashUpl >= MaxAllowableCashLoss)//MaxAllowableCashLoss is a negative number
            CloseDelete = true;
   }//if (day == 6)
   
   if (CloseDelete)
   {
      CloseAllTrades(AllSymbols, AllTrades);
      if (ForceTradeClosure)
         CloseAllTrades(AllSymbols, AllTrades);
      if (ForceTradeClosure)
         CloseAllTrades(AllSymbols, AllTrades);
   }//if (CloseDelete)
      

}//End void ShutDownForTheWeekend()

bool MopUpTradeClosureFailures()
{
   //Cycle through the ticket numbers in the ForceCloseTickets array, and attempt to close them
   
   bool Success = true;
   
   for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   {
      //Order might have closed during a previous attempt, so ensure it is still open.
      if (!BetterOrderSelect(ForceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
         continue;
   
      bool result = CloseOrder(OrderTicket() );
      if (!result)
         Success = false;
   }//for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   
   if (Success)
      ArrayFree(ForceCloseTickets);
   
   return(Success);


}//END bool MopUpTradeClosureFailures()


bool MarginCheck()
{

   EnoughMargin = true;//For user display
   MarginMessage = "";
   if (UseScoobsMarginCheck && OpenTrades > 0)
   {
      if(AccountMargin() > (AccountFreeMargin()/100)) 
      {
         MarginMessage = "There is insufficient margin to allow trading. You might want to turn off the UseScoobsMarginCheck input.";
         return(false);
      }//if(AccountMargin() > (AccountFreeMargin()/100)) 
      
   }//if (UseScoobsMarginCheck)


   if (UseForexKiwi && AccountMargin() > 0)
   {
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < FkMinimumMarginPercent)
      {
         MarginMessage = StringConcatenate("There is insufficient margin percent to allow trading. ", DoubleToStr(ml, 2), "%");
         return(false);
      }//if (ml < FkMinimumMarginPercent)
   }//if (UseForexKiwi && AccountMargin() > 0)
   
  
   //Got this far, so there is sufficient margin for trading
   return(true);
}//End bool MarginCheck()

bool CheckTradingTimes() 
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
}//End bool CheckTradingTimes2() 
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
	if ( StringSubstrOld( tradingHours, 0, 1 ) == "-" ) 
	{
		tradingHours = StringConcatenate( "+0,", tradingHours );   
	}
	
	// Add delimiter
	if ( StringSubstrOld( tradingHours, StringLen( tradingHours ) - 1) != "," ) 
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
		string part = StringSubstrOld( tradingHours, 0, i );

		// Check start or stop prefix
		string prefix = StringSubstrOld ( part, 0, 1 );
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
		part = StringSubstrOld( part, 1 );
		double time = StrToDouble( part );
		int hour = (int)MathFloor( time );
		int minutes = (int)MathRound( ( time - hour ) * 100 );

		// Add to array
		tradeHours[size] = 60 * hour + minutes;

		// Trim input string
		tradingHours = StringSubstrOld( tradingHours, i + 1 );
		i = StringFind( tradingHours, "," );
	}//while (i != -1) 

	return ( true );
}//End bool initTradingHours() 

// for 6xx build compatibilità added by milanese
string StringSubstrOld(string x,int a,int b=-1) 
{
   if(a<0) a=0; // Stop odd behaviour
   if(b<=0) b=-1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
}

bool SundayMondayFridayStuff()
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
         if (OpenTrades == 0)
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
   
}//End bool  SundayMondayFridayStuff()

bool IsTradingAllowed(string symbol, int PairIndex)
{
   //Returns false if any of the filters should cancel trading, else returns true to allow trading
   
      
   //Maximum spread. We do not want any trading operations  during a wide spread period
   if (!SpreadCheck(PairIndex) ) 
      return(false);
   
    
   //An individual currency can only be traded twice, so check for this
   CanTradeThisPair = true;
   if (OnlyTradeCurrencyTwice && OpenTrades > 0)
   {
      IsThisPairTradable(symbol);      
   }//if (OnlyTradeCurrencyTwice)
   if (!CanTradeThisPair) return(false);
   
   //Swap filter
   if (OpenTrades == 0) TradeDirectionBySwap(symbol);
   
   //Order close time safety feature
   if (TooClose(symbol)) return(false);

   return(true);


}//End bool IsTradingAllowed()

bool IsThisPairTradable(string symbol)
{
   //Checks to see if either of the currencies in the pair is already being traded twice.
   //If not, then return true to show that the pair can be traded, else return false
   
   string c1 = StringSubstrOld(symbol, 0, 3);//First currency in the pair
   string c2 = StringSubstrOld(symbol, 3, 3);//Second currency in the pair
   int c1open = 0, c2open = 0;
   CanTradeThisPair = true;
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
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
         CanTradeThisPair = false;
         return(false);   
      }//if (c1open > 1 || c2open > 1) 
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so ok to trade
   return(true);
   
}//End bool IsThisPairTradable()

void TradeDirectionBySwap(string symbol)
{

   //Sets TradeLong & TradeShort according to the positive/negative swap it attracts

   //Swap is read in init() and AutoTrading()

   TradeLong = true;
   TradeShort = true;
   
   if (CadPairsPositiveOnly)
   {
      if (StringSubstrOld(symbol, 0, 3) == "CAD" || StringSubstrOld(symbol, 0, 3) == "cad" || StringSubstrOld(symbol, 3, 3) == "CAD" || StringSubstrOld(symbol, 3, 3) == "cad" )      
      {
         if (longSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (shortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (CadPairsPositiveOnly)
   
   if (AudPairsPositiveOnly)
   {
      if (StringSubstrOld(symbol, 0, 3) == "AUD" || StringSubstrOld(symbol, 0, 3) == "aud" || StringSubstrOld(symbol, 3, 3) == "AUD" || StringSubstrOld(symbol, 3, 3) == "aud" )      
      {
         if (longSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (shortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   
   if (NzdPairsPositiveOnly)
   {
      if (StringSubstrOld(symbol, 0, 3) == "NZD" || StringSubstrOld(symbol, 0, 3) == "nzd" || StringSubstrOld(symbol, 3, 3) == "NZD" || StringSubstrOld(symbol, 3, 3) == "nzd" )      
      {
         if (longSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (shortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   //OnlyTradePositiveSwap filter
   if (OnlyTradePositiveSwap)
   {
      if (longSwap < 0) TradeLong = false;
      if (shortSwap < 0) TradeShort = false;      
   }//if (OnlyTradePositiveSwap)
   
   //MaximumAcceptableNegativeSwap filter
   if (longSwap < MaximumAcceptableNegativeSwap) TradeLong = false;
   if (shortSwap < MaximumAcceptableNegativeSwap) TradeShort = false;      


}//void TradeDirectionBySwap()

bool TooClose(string symbol)
{
   //Returns false if the previously closed trade and the proposed new trade are sufficiently far apart, else return true. Called from IsTradeAllowed().
   
   if (OrdersHistoryTotal() == 0) return(false);
   
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
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
   
}//bool TooClose()

void RunningSpreadCalculation(string symbol, int PairIndex)
{
   //Keeps a running total of each pair's average spread
 
   //Has there been a new tick since the last OnTimer() event?
   if (!CloseEnough(SpreadArray[PairIndex][previousask], ask) )
   {
      //Yes, so update the counters
      SpreadArray[PairIndex][previousask] = ask;//Store the latest quote
      
      if (spread > SpreadArray[PairIndex][biggestspread])
         SpreadArray[PairIndex][biggestspread] = spread;//Reset the biggest spread
         
      SpreadArray[PairIndex][spreadtotalsofar]+= spread;//Add the spread to the total of spreads
      SpreadArray[PairIndex][tickscounted]++;//Update the spread calculation tick counter
      
      //Do we need to update the average spread?
      if (SpreadArray[PairIndex][tickscounted] >= 5)
      {
         SpreadArray[PairIndex][averagespread] = SpreadArray[PairIndex][spreadtotalsofar] / 5;
         SpreadArray[PairIndex][tickscounted] = 0;
         SpreadArray[PairIndex][spreadtotalsofar] = 0;
         SpreadGvName = symbol + " average spread";
         GlobalVariableSet(SpreadGvName, SpreadArray[PairIndex][averagespread]);
      }//if (SpreadArray[PairIndex][tickscounted] >= 5)
      
      SpreadArray[PairIndex][longtermspreadtotalsofar]+= spread;//Add the spread to the total of spreads
      SpreadArray[PairIndex][longtermtickscounted]++;//Update the spread calculation tick counter
      
      //Do we need to update the longterm spread
      if (SpreadArray[PairIndex][longtermtickscounted] >= 200)
      {
         SpreadArray[PairIndex][longtermspread] = SpreadArray[PairIndex][longtermspreadtotalsofar] / 200;
         SpreadArray[PairIndex][longtermtickscounted] = 0;
         SpreadArray[PairIndex][longtermspreadtotalsofar] = 0;
         SpreadGvName = symbol + " longterm spread";
         GlobalVariableSet(SpreadGvName, SpreadArray[PairIndex][longtermspread]);
      }//if (SpreadArray[PairIndex][tickscounted] >= 5)
      
         
   }//if (!CloseEnough(SpreadArray[PairIndex][previousask]), ask)
   

}//End void RunningSpreadCalculation(int PairIndex)

bool SpreadCheck(int PairIndex)
{
   //Returns 'false' if the check fails, else returns 'true'
   
   //Craptesting
   if (IsTesting() )
      return(true);//Spread is not relevant
      
   
   if (spread >= (MathMax(SpreadArray[PairIndex][averagespread],0.1) * MultiplierToDetectStopHunt) )
      return(false);
   
   //Got this far, so ok to continue
   return(true);

}//End bool SpreadCheck(int PairIndex)


//This code by tomele. Thank you Thomas. Wonderful stuff.
bool AreWeAtRollover()
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

}//End bool AreWeAtRollover()



void CalculateLotAsAmountPerCashDollops()
{

   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   int decimal = 0;
   if (CloseEnough(lotstep, 0.1) )
      decimal = 1;
   if (CloseEnough(lotstep, 0.01) )
      decimal = 2;
      
   double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double DoshDollop = AccountInfoDouble(ACCOUNT_BALANCE); 
   
   if (UseEquity)
      DoshDollop = AccountInfoDouble(ACCOUNT_EQUITY); 

//For testing:
//DoshDollop = 2796;
   
   //Calculate the no of dollops in DoshDollop
   int NoOfDollops = (int) DoshDollop / SizeOfDollop;

   
   //Initial lot size
   Lot = NormalizeDouble(NoOfDollops * LotsPerDollopOfCash, decimal);
     
   //Min/max size check
   if (Lot > maxlot)
      Lot = maxlot;
      
   if (Lot < minlot)
      Lot = minlot;      

//For testing
//Alert(DoubleToStr(Lot, decimal));


}//void CalculateLotAsAmountPerCashDollops()

int ExtractPairIndexFromOrderSymbol(string symbol)
{

   //Returns the index in the TradePair array that corresponds
   //to the order symbol.
   
   for (int cc = 0; cc < ArraySize(TradePair); cc++)
   {
      if (TradePair[cc] == symbol)
         return(cc);   
   }//for (int cc = 0; cc < ArraySize(TradePair) - 1; cc++)
   
   
   //Symbol not found, so return a dummy
   return(-1);

}//End int ExtractPairIndexFromOrderSymbol(string symbol)


void CountTotalsForDisplay()
{
   //Makes a tally of all trades belonging to the EA, regardless of their order symbol

   TotalPipsUpl = 0;
   TotalCashUpl = 0;
   TotalOpenTrades = 0;
   
   ArrayInitialize(BuyTradeTotals, 0);
   ArrayInitialize(SellTradeTotals, 0);

   //FIFO ticket resize
   ArrayFree(FifoTicket);

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      //Ensure the trade is still open
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;

      
      //Ensure the EA 'owns' this trade
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
      //Store ticket numbers for FIFO.
      //This is here so that it can be used to close trades FIFO
      //in basket equity closure
      ArrayResize(FifoTicket, TotalOpenTrades + 1);
      FifoTicket[TotalOpenTrades] = OrderTicket();

      GetBasics(OrderSymbol());
      
      double pips = CalculateTradeProfitInPips(OrderType() );

      TotalPipsUpl+= pips;
      double profit = (OrderProfit() + OrderSwap() + OrderCommission()); 
      TotalCashUpl+= profit;
      TotalOpenTrades++;
      
      double swap = OrderSwap();

      //Total cash/pips for chart display
      int PairIndex = ExtractPairIndexFromOrderSymbol(OrderSymbol() );
      if (PairIndex == -1)
         continue;//Something is wrong
         
      if (OrderType() == OP_BUY)
      {
         BuyTradeTotals[PairIndex][pipst]+= pips;
         BuyTradeTotals[PairIndex][casht]+= profit;
         BuyTradeTotals[PairIndex][swapt]+= swap;
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL)
      {
         SellTradeTotals[PairIndex][pipst]+= pips;
         SellTradeTotals[PairIndex][casht]+= profit;
         SellTradeTotals[PairIndex][swapt]+= swap;
      }//if (OrderType() == OP_SELL)
      
      
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);

}//End void CountTotalsForDisplay()




void UpdateTradeArrows()
{
   //No update cycle
   if(TimerCount>0)
      return;
      
   //Cycle through charts
   long nextchart=ChartFirst();
   do
   {
      string symbol=ChartSymbol(nextchart);
      if(symbol!=ReservedPair && nextchart!=ChartID())
         DrawTradeArrows(symbol,nextchart);
   }
   while((nextchart=ChartNext(nextchart))!=-1);
   
   return;
}//void UpdateTradearrows()


void CalculateClosedProfits()
{
   //Adds up all the closed trades in the history tab.
   
   TotalClosedCashPl = 0;
   TotalClosedPipsPl = 0;
   TotalClosedTrades = 0;
   Winners = 0;
   Losers = 0;
   
   ArrayInitialize(ClosedBuyTradeTotals, 0);
   ArrayInitialize(ClosedSellTradeTotals, 0);

   if (OrdersHistoryTotal() == 0)
      return;
      
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() < 0 || OrderType() > 1) continue;
      if (OrderCloseTime() == 0) continue; 
      
      TotalClosedTrades++;
      
      GetBasics(OrderSymbol());

      double profit = OrderSwap() + OrderCommission() + OrderProfit();
      if (profit > 0)
         Winners++;
      else
         Losers++;
         
      TotalClosedCashPl += profit;
      
      double pips=0;
      if (OrderType() == OP_BUY)
         pips = ( OrderClosePrice() - OrderOpenPrice() ) * factor;
      if (OrderType() == OP_SELL)
         pips = ( OrderOpenPrice() - OrderClosePrice() ) * factor;
         
      TotalClosedPipsPl += pips;
      
      double swap=OrderSwap();

      //Total cash/pips for chart display
      int PairIndex = ExtractPairIndexFromOrderSymbol(OrderSymbol() );
      if (PairIndex == -1)
         continue;//Something is wrong
         
      if (OrderType() == OP_BUY)
      {
         ClosedBuyTradeTotals[PairIndex][pipst]+= pips;
         ClosedBuyTradeTotals[PairIndex][casht]+= profit;
         ClosedBuyTradeTotals[PairIndex][swapt]+= swap;
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL)
      {
         ClosedSellTradeTotals[PairIndex][pipst]+= pips;
         ClosedSellTradeTotals[PairIndex][casht]+= profit;
         ClosedSellTradeTotals[PairIndex][swapt]+= swap;
      }//if (OrderType() == OP_SELL)
   }//for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)

}//End void CalculateClosedProfits()

bool CanIndividualPairBasketBeClosed(string symbol, int PairIndex)
{

   //Pips target
   if (IndividualBasketTargetPips > 0)
      if (PipsUpl[PairIndex] >= IndividualBasketTargetPips)
      {
         CloseAllTrades(symbol, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
            if (ForceTradeClosure)
            {
               CloseAllTrades(symbol, AllTrades);
               if (ForceTradeClosure)
               {
                  return(false);
               }//if (ForceTradeClosure)                     
            }//if (ForceTradeClosure)         
         }//if (ForceTradeClosure)    
         
         if (!ForceTradeClosure)
            return(true);//Closure target reached and closure successful
      }//if (PipsUpl >= IndividualBasketTargetPips)
   
      
   //Cash target
   if (!CloseEnough(IndividualBasketTargetCash,0) )
   {
      if (UseDynamicCashTPIndividualPair) 
      {
         IndividualBasketTargetCash = NormalizeDouble(CashTakeProfitIndividualePairPerLot * Lot, 2);
      } // if (UseDynamicCashTPIndividualPair) 
      if (CashUpl[PairIndex] >= IndividualBasketTargetCash)
      {
         CloseAllTrades(symbol, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
            if (ForceTradeClosure)
            {
               CloseAllTrades(symbol, AllTrades);
               if (ForceTradeClosure)
               {
                  return(false);
               }//if (ForceTradeClosure)                     
            }//if (ForceTradeClosure)         
         }//if (ForceTradeClosure)    
         
         if (!ForceTradeClosure)
            return(true);//Closure target reached and closure successful
      }//if (CashUpl[PairIndex] >= IndividualBasketTargetCash)
   }//if (!CloseEnough(IndividualBasketTargetCash,0) )
   
   
      

   //Got here, so no closure or closure part-failed
   return(false);

}//bool CanIndividualPairBasketBeClosed(string symbol, int PairIndex)

bool CanEntirePositionClose()
{
   
   //The basket trailing stop feature was added by 1of3. Fabulous contributin John; many thanks.
   if(TreatAllPairsAsBasket && UseBasketTrailingStop)
   {
      if(BTSActivated)
      {
         if(TotalCashUpl > BTSHighValue)
         {
            BTSHighValue = TotalCashUpl;
            BTSStopLoss = NormalizeDouble(BTSHighValue - BasketTrailingStopGapValue, 2);
         }//if(TotalCashUpl > BTSHighValue)

         if(TotalCashUpl <= BTSStopLoss)
         {
            BTSActivated=false;
            Print("Basket Stoploss closing trades at "+DoubleToStr(TotalCashUpl,2)+". Highest Value:"+DoubleToStr(BTSHighValue,2)+" initial Basket SL Value £"+DoubleToStr(BTSStopLoss,2));
            BTSHighValue = 0;
            BTSStopLoss = 0;
            CloseAllTrades(AllSymbols, AllTrades);
            if (ForceTradeClosure)
            {
               CloseAllTrades(AllSymbols, AllTrades);
               if (ForceTradeClosure)
               {
                  CloseAllTrades(AllSymbols, AllTrades);
                  if (ForceTradeClosure)
                  {
                     ForceWholePositionClosure = true;
                     return(false);
                  }//if (ForceTradeClosure)
               }//if (ForceTradeClosure)
            }//if (ForceTradeClosure)

            if (!ForceTradeClosure)
               return(true);//Closure target reached and closure successful
         }//if(TotalCashUpl <= BTSStopLoss)
      }//if(BTSActivated)
      else
      {
         if (!CloseEnough(BasketTrailingStopStartValue,0) )
            if (TotalCashUpl >= BasketTrailingStopStartValue)
            {
               BTSHighValue = TotalCashUpl;
               BTSStopLoss = NormalizeDouble(TotalCashUpl - BasketTrailingStopGapValue, 2);
               BTSActivated = true;
               Print("Basket StopLoss Triggered at £"+DoubleToStr(TotalCashUpl,2)+". High Value:£"+DoubleToStr(BTSHighValue,2)+" initial Basket SL Value £"+DoubleToStr(BTSStopLoss,2));
            }//if (TotalCashUpl >= BasketTrailingStopStartValue)
      }//else
      //return(false); This would prevent the rest of the function being tested.
   }//if(TreatAllPairsAsBasket && UseBasketTrailingStop)

   //Pips target
   if (BasketTargetPips > 0)
      if (TotalPipsUpl >= BasketTargetPips)
      {
         CloseAllTrades(AllSymbols, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(AllSymbols, AllTrades);
            if (ForceTradeClosure)
            {
               CloseAllTrades(AllSymbols, AllTrades);
               if (ForceTradeClosure)
               {
                  return(false);
               }//if (ForceTradeClosure)                     
            }//if (ForceTradeClosure)         
         }//if (ForceTradeClosure)    
         
         if (!ForceTradeClosure)
            return(true);//Closure target reached and closure successful
      }//if (TotalPipsUpl >= BasketTargetPips)
   
      
   //Cash target
   if (!CloseEnough(BasketTargetCash,0) )
      if (TotalCashUpl >= BasketTargetCash)
      {
         CloseAllTrades(AllSymbols, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(AllSymbols, AllTrades);
            if (ForceTradeClosure)
            {
               CloseAllTrades(AllSymbols, AllTrades);
               if (ForceTradeClosure)
               {
                  return(false);
               }//if (ForceTradeClosure)                     
            }//if (ForceTradeClosure)         
         }//if (ForceTradeClosure)    
         
         if (!ForceTradeClosure)
            return(true);//Closure target reached and closure successful
      }//if (TotalCashUpl >= BasketTargetCash)

   //Got this far, so no closure or closure part-failed
   return(false);

}//End bool CanEntirePositionClose()

void CanPendingsBeDeleted()
{
   //Delete pendings that are not yet part of a market position
   //if the margin level drops below our minimum. This function 
   //is called if the margin level has dropped below this minimum.
   
   for (int PairIndex = 0; PairIndex < ArraySize(TradePair); PairIndex++)
   {
      string symbol = TradePair[PairIndex];
      GetBasics(symbol);
      CountOpenTrades(symbol, PairIndex);
      
      //Only delete the pendings if there are no market trades already open
      if (MarketTradesTotal == 0)
         if (PendingTradesTotal > 0)//and there are still pending orders
            CloseAllTrades(symbol, AllTrades);
            
      
   }//for (int PairIndex = 0; PairIndex < ArraySize(TradePair); PairIndex++)
   
   
}//End void CanPendingsBeDeleted()

void CalculateDynamicBasketCashTP(double lots)
{

   //Calculates a basket cash TB calculated by lot size
   
   BasketTargetCash = NormalizeDouble(CashTakeProfitPerLot * lots, 2);

}//End void CalculateDynamicBasketCashTP(double lots)


void AutoTrading()
{
   //Think of this being the equivalent to OnTimer() in a multi-pair
   //EA without the dashboard element.

   //In case an entire basket closure failure happened
   if (ForceWholePositionClosure)
   {
      CloseAllTrades(AllSymbols, AllTrades);
      if (ForceWholePositionClosure)
      {
         CloseAllTrades(AllSymbols, AllTrades);
         if (ForceWholePositionClosure)
         {
            return;//Still failed, so try again at the next timer event
         }//if (ForceWholePositionClosure)                     
      }//if (ForceWholePositionClosure)  
      ForceWholePositionClosure = false;//Closure succeeded       
   }//if (ForceWholePositionClosure)    
      
   //Calculate a dynamic whole basket TP for initial display
   if (UseDynamicCashTP)
   {
      //Applied to a fixed lot size
      if (CloseEnough(LotsPerDollopOfCash, 0))
         if (CloseEnough(RiskPercent, 0))
            CalculateDynamicBasketCashTP(Lot);
   
      //LotsPerDollop
      if (!CloseEnough(LotsPerDollopOfCash, 0))
      {
         CalculateLotAsAmountPerCashDollops();
         CalculateDynamicBasketCashTP(Lot);
      }//if (!CloseEnough(LotsPerDollopOfCash, 0))
         
      //RiskPercent   
      if (!CloseEnough(RiskPercent, 0))
      {
         //Simulate a trade to calculate the lot size for a RiskPercent-based trade.
         double stop = 0, price = 0;
         string symbol = TradePair[0];
         price = MarketInfo(symbol, MODE_ASK);
         stop = CalculateStopLoss(OP_BUY, price);
         double SendLots = CalculateLotSize(symbol, price, stop);
      
         CalculateDynamicBasketCashTP(SendLots);
      
      }//if (!CloseEnough(RiskPercent, 0))
      
      
   }//if (UseDynamicCashTP)

   //Spread calculation for dashboard
   for (int PairIndex = 0; PairIndex < ArraySize(TradePair); PairIndex++)
   {
      GetBasics(TradePair[PairIndex]);
      RunningSpreadCalculation(TradePair[PairIndex], PairIndex);
   }//for (int PairIndex = 0; PairIndex < ArraySize(TradePair); PairIndex++)

   //mptm sets a Global Variable when it is closing the trades.
   //This tells this ea not to send any fresh trades.
   if (GlobalVariableCheck(GvName))
      return;
   //'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(LocalGvName))
      return;
   //'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(NuclearGvName))
      return;
      
   bool result = false;   

   CountTotalsForDisplay();
   //Has the position reached its entire basket profit target
   if (TreatAllPairsAsBasket)
   {
      if (CanEntirePositionClose() )
         return;//Start again at next timer event
      
      if (ForceTradeClosure)
      {
         CloseAllTrades(AllSymbols, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(AllSymbols, AllTrades);
            if (ForceTradeClosure)
            {
               ForceWholePositionClosure = true;
               return;//Still failed, so try again at the next timer event
            }//if (ForceTradeClosure)                     
         }//if (ForceTradeClosure)         
      }//if (ForceTradeClosure)    
         
   
   }//if (TreatAllPairsAsBasket)
   
   //Can we shut down for the weekend
   if (TotalOpenTrades > 0)
      ShutDownForTheWeekend();
      
   
   
   //Rollover
   if (DisableEaDuringRollover)
   {
      RolloverInProgress = false;
      if (AreWeAtRollover())
      {
         RolloverInProgress = true;
         return;
      }//if (AreWeAtRollover)
   }//if (DisableEaDuringRollover)
      
   //Trading times
   TradeTimeOk=CheckTradingTimes();
   if(!TradeTimeOk)
   {
      DisplayUserFeedback();
      Sleep(1000);
      return;
   }//if (!TradeTimeOk)

   //Sunday trading, Monday start time, Friday stop time, Thursday trading
   TradeTimeOk = SundayMondayFridayStuff();
   if (!TradeTimeOk)
   {
      DisplayUserFeedback();
      return;
   }//if (!TradeTimeOk)

   for (int PairIndex = 0; PairIndex < ArraySize(TradePair); PairIndex++)
   {
      string symbol = TradePair[PairIndex];
      GetBasics(symbol);

      //In case an individual basket closure failed. PairIndex has been
      //adjusted, so try again
      if (ForceTradeClosure)
      {
         CloseAllTrades(symbol, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
            if (ForceTradeClosure)
            {
               PairIndex--;
               continue;
            }//if (ForceTradeClosure)                     
         }//if (ForceTradeClosure)         
      }//if (ForceTradeClosure)      
      
      //For the swap filter. It will set these variable to false if the swap filter fails.
      //The variables are left behind from the conversion of the single pair trading EA
      //to the multi-pair one. This seems to me to be the easiest way of dealing with the problem
      //that the filter causes of not resetting here.
      TradeLong = true;
      TradeShort = true;
      
      //In case any order close/delete failed
      if (ForceTradeClosure)
      {
         CloseAllTrades(symbol, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
            if (ForceTradeClosure)
               PairIndex--;
         }//if (ForceTradeClosure)
         continue;
      }//if (ForceTradeClosure)
  
      //Average spread
      RunningSpreadCalculation(symbol, PairIndex);
      //Is spread ok to allow accions on this pair
      if (!SpreadCheck(PairIndex) )
         continue;

      CountOpenTrades(symbol, PairIndex);
      //Individual pair basket closure
      if (TreatIndividualPairsAsBasket)
         if (CanIndividualPairBasketBeClosed(symbol, PairIndex) )
            continue;

      if (ForceTradeClosure)
      {
         CloseAllTrades(symbol, AllTrades);
         if (ForceTradeClosure)
         {
            CloseAllTrades(symbol, AllTrades);
            if (ForceTradeClosure)
            {
               PairIndex--;
               continue;
            }//if (ForceTradeClosure)                     
         }//if (ForceTradeClosure)         
      }//if (ForceTradeClosure)      
      
      //Lot size based on account size
      if (!CloseEnough(LotsPerDollopOfCash, 0))
         CalculateLotAsAmountPerCashDollops();
     
      //Deal with pending orders when the margin level drops below our minimum
      bool MarginOK = MarginCheck();
      if (!MarginOK)
      {
         CanPendingsBeDeleted();
         return;
      }//if (!MarginOK)
      
      
      if (TimeCurrent() >= TimeToStartTrading[PairIndex])
      {
         if (!StopTrading)              
         {
            if (MarginOK)
            {
               LookForTradingOpportunities(symbol, PairIndex);
               TimeToStartTrading[PairIndex] = 0;//Set to TimeCurrent() + (PostTradeAttemptWaitMinutes * 60) 
                                                 //when there is an OrderSend() attempt)
            }//if (MarginOK)
         }//if (!StopTrading)
      }//if (TimeCurrent() >= TimeToStartTrading[PairIndex])
   
   }//for (int PairIndex = 0; PairIndex < ArraySize(TradePair); PairIndex++)

}//void AutoTrading()



//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

   UpdateTradeArrows();
   
   
   if (RemoveExpert)
   {
      ExpertRemove();
      return;
   }//if (RemoveExpert)
   
   //mptm sets a Global Variable when it is closing the trades.
   //This tells this ea not to send any fresh trades.
   
   
   
   TimerCount++;
   if (TimerCount>=ChartCloseTimerMultiple)//Now we have a chart closing cycle
      TimerCount=0;



   ReadIndicatorValues();
   
   if (MinimiseChartsAfterOpening)
      ShrinkCharts();
   
   //Using the EA to trade
   if (AutoTradingEnabled)
      AutoTrading();
   
   DisplayUserFeedback();
   
}
//+------------------------------------------------------------------+
