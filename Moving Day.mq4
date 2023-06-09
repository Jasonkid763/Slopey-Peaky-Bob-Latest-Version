//AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)

//+------------------------------------------------------------------+
//|                                                   Moving Day.mq4 |
//|                                                 Steve and Tomele |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property strict
#define version "Version 1l"

/*
The idea is to trade the cross of the D1 20 period moving average.
*/

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
#define  tradablelong "Tradable long" // i.e. long cross
#define  tradableshort "Tradable short" //i.e. short cross
#define  untradable "Not tradable" //i.e. no cross

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

enum TradeTypes
{
   MarketOrder,
   StopOrder
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



extern string  cau="---- Chart automation ----";
//These inputs tell the ea to automate opening/closing of charts and
//what to load onto them
extern string           ReservedPair                        ="XAUUSD";
extern string           TemplateName                        ="MD H1";
extern string           tra                                 ="-- Trade arrows --";
extern bool             drawTradeArrows                     = false;
extern ArrowPlaces      WhereToDrawArrows                  = CandleHighLow;
extern color            TradeLongColor                      = Blue;
extern color            TradeShortColor                     = Blue;
extern int              TradeArrowSize                      = 5;
extern string           lin                                 ="-- Trade lines --";
extern bool             DrawTradeLines                      = True;
extern LineColoring     HowToColorLines                     = LongShort;
extern color            TradeLineLongOrProfitableColor      = Lime;
extern color            TradeLineShortOrUnprofitableColor   = Red;
extern int              TradeLineSize                       = 1;
extern ENUM_LINE_STYLE  TradeLineStyle                      = STYLE_DOT;

extern string           s1="================================================================";
extern string           oad               ="---- Other stuff ----";
extern string           PairsToTrade   = "AUDCAD,AUDCHF,AUDNZD,AUDJPY,AUDUSD,CADCHF,CADJPY,CHFJPY,EURAUD,EURCAD,EURCHF,EURGBP,EURNZD,EURJPY,EURUSD,GBPCHF,GBPJPY,GBPUSD,NZDUSD,NZDJPY,USDCAD,USDCHF,USDJPY";
extern ENUM_TIMEFRAMES  ChartTimeFrame=PERIOD_H1;
extern int              EventTimerIntervalSeconds=1;
extern int              ChartCloseTimerMultiple=15;
extern bool             WriteFileForTestDatabase=true;
// TDesk code
extern bool    SendToTDesk=false;
////////////////////////////////////////////////////////////////////////////////
int            noOfPairs;// Holds the number of pairs passed by the user via the inputs screen
string         tradePair[]; //Array to hold the pairs traded by the user
datetime       ttfCandleTime[];
double         ask=0, bid=0, spread=0;//Replaces Ask. Bid, Digits. factor replaces Point
int            digits;//Replaces Digits.
double         longSwap=0, shortSwap=0;
int            openLongTrades=0, openShortTrades=0;
int            closedLongTrades=0, closedShortTrades=0;
bool           buySignal[], sellSignal[];
bool           buyCloseSignal[], sellCloseSignal[];
string         tradingTimeFramedisplay="";
int            timerCount=0;//Count timer events for closing charts
bool           forceTradeClosure=false;
datetime       oldCandleReadTime[];
double         buyTradeTotals[][3];//Total pips and cash for each pair's buy trades
double         sellTradeTotals[][3];//Total pips and cash for each pair's sell trades
double         closedBuyTradeTotals[][3];//Total pips and cash for each pair's closed buy trades
double         closedSellTradeTotals[][3];//Total pips and cash for each pair's closed sell trades
//Variables for closed trades
int            winners=0, losers=0;
double         closedPipsPL=0, closedCashPL=0;
////////////////////////////////////////////////////////////////////////////////

extern string  tsep1="================================================================";
extern string  tsep2="================================================================";
extern string  tsep3="================================================================";
extern string  aut="---- Using the dashboard as an auto-trader ----";
extern bool    AutoTradingEnabled=true;
//One for our friends in the US
extern bool    MustObeyFIFO=false;
extern bool    StopTrading=false;
bool    tradeLong=true;//Not needed as an extern here
bool    tradeShort=true;//Not needed as an extern here
extern int     MagicNumber=0;
extern string  TradeComment="Moving Day";
extern bool    IsGlobalPrimeOrECNCriminal=false;
extern int     MaxSlippagePips=5;
extern string  PairPrefix="";
extern string  PairSuffix="";
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitSeconds seconds, whether OR detects a receipt return or not.
extern int     PostTradeAttemptWaitSeconds=60;
////////////////////////////////////////////////////////////////////////////////////////
datetime       timeToStartTrading[];//Re-start calling lookForTradingOpportunities() at this time.
string         gvName="Under management flag";//The name of the GV that tells the EA not to send trades whilst the manager is closing them.
//'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
string         localGvName = "Local closure in operation " + Symbol();
//'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
string         nuclearGvName = "Nuclear option closure in operation " + Symbol();
//For FIFO
int            fifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.
//An array to store ticket numbers of trades that need closing, should an offsetting OrderClose fail
int            forceCloseTickets[];
bool           removeExpert=false;
double         minDistanceBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1="================================================================";
extern string  lsz="---- Lot sizing ----";
extern string  hls="-- 'Hard' lot sizing --";
extern double  Lot=0.01;
string  prc="-- Percentage based lot sizing --";
//Set RiskPercent to zero to disable and use Lot
double  RiskPercent=0;
extern string  acs="-- Account size lot sizing --";
//LotsPerDollopOfCash over rides Lot. Zero input to cancel.
extern double  LotsPerDollopOfCash=0;
extern int     SizeOfDollop=4000;
extern bool    UseBalance=false;
extern bool    UseEquity=true;
extern string  dcs="-- Differential lot sizing --";
//This attempt to send lot sizes that will result in equal profitability/loss 
//over all pairs per pip movement.
extern bool    UseDifferentialLotSizing=false;
extern int     AtrPeriod=14;
////////////////////////////////////////////////////////////////////////////////////////
double         lotSizeMultiplier=0;//For differential lot sizing
string         lotSizeGvName=" MD lot size";//Save the trade lot size for scaling out
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1i="================================================================";
extern string  tex="---- Trade exits ----";
extern string  htex="-- 'Hard' stops-- "; 
extern int     TakeProfitPips=120;
extern int     StopLossPips=0;
//A distance from the moving average to set the stop loss.
//Enter a zero value here to use StopLossPips instead.
extern int     OppositeSideStopLossPips=30;
extern string  atrs="-- ATR stops --";
extern bool    UseAtrForTakeProfit=false;
extern ENUM_TIMEFRAMES AtrTpTimeFrame=PERIOD_D1;
extern int     AtrTpPeriod=20;
extern double  AtrTpMultiplier=1;
extern bool    UseAtrForStopLoss=false;
extern ENUM_TIMEFRAMES AtrSlTimeFrame=PERIOD_D1;
extern int     AtrSlPeriod=20;
extern double  AtrSlMultiplier=1;
extern string  hslt="-- Hidden take profit and stop loss --";
extern bool    HideStopLossAndTakeProfit=false;
extern string  psl="-- Scale out stop loss --";
extern bool    UseScaleOutStopLoss=false;
extern int     NoOfLevels=4;
extern int     DistanceBetweenLevelsPips=20;
extern double  PercentToClose=25;
extern bool    UseScaleBackIn=false;
extern string  ScaleBackInTradeComment="Scale in";
////////////////////////////////////////////////////////////////////////////////////////
double         takeProfit=0, stopLoss=0;
double         oppositeSideStopLoss=0;
//HIdden sltp storage
string         stopLossGvName= " Moving Day stored stop loss";
string         takeProfitGvName= " Moving Day stored take profit";
double         DistanceBetweenLevels=0;
////////////////////////////////////////////////////////////////////////////////////////


extern string  sep1h="================================================================";
/*
This is an idea presented by Bill (billv). Give the user the opportunity to respond to
signals in a selected 'bigger picture' direction only. Please read the user guide for more details.
The inputs are csv lists of pairs.
*/
extern string  tdc="---- Trade direction controls ----";
extern string  PairsToTradeLongOnly="";
extern string  PairsToTradeShortOnly="";
////////////////////////////////////////////////////////////////////////////////////////
//Variables/arrays to hold the buy/sell only pairs
int            noOfLongOnlyPairs=0, noOfShortOnlyPairs=0;
string         longOnlyPairs[], shortOnlyPairs[];
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep11a="================================================================";
//Trade trigger
extern string  ttr="---- The trade trigger is a cross of a moving average ----";
extern ENUM_TIMEFRAMES TradingTimeFrame=PERIOD_H1;
extern ENUM_TIMEFRAMES MaTimeFrame=PERIOD_D1;
extern bool    EveryTickMode=false;
extern int     MaPeriod=20;
extern ENUM_MA_METHOD MaMethod=MODE_EMA;
extern ENUM_APPLIED_PRICE MaAppliedPrice=PRICE_CLOSE;
 int     MaShift=0;
////////////////////////////////////////////////////////////////////////////////////////
string         mastatus[];
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1b="================================================================";
extern string  trm="---- Trading methods ----";
extern string  stm="-- Single Trade --";
extern bool    UseSingleTradingMethod=false;
extern TradeTypes TypeOfOrder=StopOrder;
extern int     StopOrderDistancePips=20;
extern string  gri="-- Grid trading --";
extern bool    UseGridTradingMethod=true;
//Limit the number of pairs allowed to trade. Zero value disables this.
extern int     MaxPairsAllowed=0;
//Send a market trade as soon as there is a signal
extern bool    SendImmediateMarketTrade=false;
extern int     GridSize=5;
//If not immediate market order, then the distance from market to first trade
extern int     PendingDistanceToFirstTradePips=20;
extern int     DistanceBetweenTradesPips=20;
extern bool    UseAtrForGrid=false;
extern ENUM_TIMEFRAMES GridAtrTimeFrame=PERIOD_D1;
extern int     GridAtrPeriod=20;
extern double  GridAtrDivisor=5;
//Adding to the grid when there is a strong move in our favour and all the stop orders have filled
extern string  rgi="--Rolling grid inputs --";
extern bool    RollingGrid=false;
extern int     MaxRolledTrades=20;
//Close the grid when there are the max trades open and the market reaches the next level
extern bool    CloseGridAtMrtPlusOneLevel=false;
extern string  gtp="-- Grid trades take profit --";
//This tells Desky to set the take profit for each trade at the open price of the next trade in the grid.
//I have hidden this because I do not think it will be useful, but have left the code just in case.
 bool    UseNextLevelForTP=false;
////////////////////////////////////////////////////////////////////////////////////////
double         distanceBetweenTrades=0, stopOrderDistance=0, pendingDistanceToFirstTrade=0;
string         pairsTraded[];
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1c="================================================================";
extern string  bas="---- Basket trading ----";
//Pips and cash inputs will not be considered when = 0
extern string  ind="-- Individual pairs --";
extern bool    TreatIndividualPairsAsBasket=false;
extern int     IndividualBasketTargetPips=0;
extern double  IndividualBasketTargetCash=0;
extern bool    LeaveIndividualBasketPendingsOpen=false;
extern string  dbi="-- Dynamic individual pair basket take profit --";
//Individual Pair Basket cash TP based on lot size. Lucky64 added this function. Many thanks Luciano.
extern bool    UseDynamicCashTPIndividualPair=false;
extern double  CashTakeProfitIndividualePairPerLot=1000;
extern string  all="-- All trades belong to a single basket --";
extern bool    TreatAllPairsAsBasket=true;
extern int     BasketTargetPips=0;
extern double  BasketTargetCash=40;
extern bool    KnockOffForDayAfterClosure=true;
extern bool    LeaveAllPairsBasketPendingsOpen=false;
extern string  dbt="-- Dynamic basket take profit --";
//Basket cash TP based on lot size
extern bool    UseDynamicCashTP=false;
extern double  CashTakeProfitPerLot=3000;
////////////////////////////////////////////////////////////////////////////////////////
bool           forceWholePositionClosure=false;
bool           deletePendings=false;//Set in OnInit()
string         basketClosureTimeGV="Moving Day all-pair basket closure time";
bool           tradingSuspendedAfterBasketClosure=false;
////////////////////////////////////////////////////////////////////////////////////////
//The basket cash trailing stop feature was added by 1of3. Fabulous contributin John; many thanks.
extern string  dts="-- Basket Cash Trailing Stop --";
extern bool    UseBasketTrailingStopCash=false;
extern double  BasketTrailingStopStartValueCash=16;
extern double  BasketTrailingStopgapValueCash=10;
////////////////////////////////////////////////////////////////////////////////////////
double         bTSStopLossCash = 0;// Basket Trailing Stop Stop Loss Monetary Value
double         bTSHighValueCash = 0;// Basket Trailing Stop high money value to drag stop loss up this amount
bool           bTSActivatedCash = false;//Basket Trailing Stop is currently in operation
//Addition to John's code
string         bTSTrailingStopCashGV="SPB_Basket cash trailing stop";//A global variable that stores the basket stop loss, allowing
////////////////////////////////////////////////////////////////////////////////////////
//I have adapted John's basket cash trailing stop feature to create the pips trailing stop.
extern string  pits="-- Basket Pips Trailing Stop --";
extern bool    UseBaskettrailingStopPips=false;
extern int     BasketTrailingStopStartValuePips=16;
extern int     BasketTrailingStopgapValuePips=10;
////////////////////////////////////////////////////////////////////////////////////////
double         bTSStopLossPips = 0;// Basket Trailing Stop Stop Loss pips Value
double         bTSHighValuePips = 0;// Basket Trailing Stop high pips value to drag stop loss up this amount
bool           bTSActivatedPips = false;//Basket Trailing Stop is currently in operation
//Addition to John's code
string         bTStrailingStopPipsGV="SPB_Basket pips trailing stop";//A global variable that stores the basket stop loss, allowing
////////////////////////////////////////////////////////////////////////////////////////
//Trailing stop based on a percentage of balance
extern string  pets="-- Basket Percentage of Balance Trailing Stop --";
extern bool    UseBasketTrailingStopPercentage=false;
//The profit percentage of balance to start the trail.
extern double  BasketTrailingStopStartValuePercent=0.5;
//The percentage of balance to use as the trail
extern double  BasketTrailingStopgapValuePercent=0.1;
//No associated variable - use the bTSStopLossCash etc variables

extern string  sep1g="================================================================";
extern string  rec1="---- Recovery ----";
extern bool    UseRecovery=false;
extern int     TradesToStartLookingForRecovery=6;//The number of trades that must be open for Recovery to be needed
extern int     MinimumLosersToTriggerRecovery=2;//The number of losers to try to close out at the breakeven point
extern int     RecoveryProfitCash=10;
////////////////////////////////////////////////////////////////////////////////////////
int            buyTickets[], sellTickets[];
bool           buysInRecovery=false, sellsInRecovery=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1d="================================================================";
extern string  sfs="----SafetyFeature----";
//Minimum time to pass after a trade closes, until the ea can open another.
extern int     MinMinutesBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////
//bool           safetyViolation;//For chart display
//bool           robotSuspended=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep7c="================================================================";
//CheckTradingTimes. Baluda has provided all the code for this. Mny thanks Paul; you are a star.
extern string  trh            = "---- Trading hours ----";
extern string  tr1            = "tradingHours is a comma delimited list";
extern string  tr1a="of start and stop times.";
extern string  tr2="Prefix start with '+', stop with '-'";
extern string  tr2a="Use 24H format, local time.";
extern string  tr3="Example: '+07.00,-10.30,+14.15,-16.00'";
extern string  tr3a="Do not leave spaces";
extern string  tr4="Blank input means 24 hour trading.";
extern string  tradingHours="";
////////////////////////////////////////////////////////////////////////////////////////
double         tradeTimeOn[];
double         tradeTimeOff[];
// trading hours variables
int            tradeHours[];
string         tradingHoursdisplay;//tradingHours is reduced to "" on initTradingHours, so this variable saves it for screen display.
bool           tradeTimeOk;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1de="================================================================";
extern string  fssmt="---- Inputs applied to individual days ----";
//Ignore signals at and after this time on Friday.
//Local time input. >23 to disable.
extern int     FridayStopTradingHour=14;
//Friday time to close all open trades/delete stop orders for the weekend.
//Local time input. >23 to disable.
extern int     FridayCloseAllHour=24;
//For those in Upside Down Land.  
extern int     SaturdayStopTradingHour=24;
//For those in Upside Down Land.
//Local time input. >23 to disable.
extern int     SaturdayCloseAllHour=24;  
//Only close all trades when the negative cash upl is less than this.
//Converted into a negative value in OnInit()
extern int     MaxAllowableCashLoss=-20;
extern bool    TradeSundayCandle=false;
//24h local time     
extern int     MondayStartHour=8;
//Thursday tends to be a reversal day, so avoid it. Not relevant here, so turned off but left in place in case we need it.                         
 bool    TradeThursdayCandle=true;
//This is another wonderful contripution by John (SHF 1of3). It gradually reduces the
//basket TP the deeper we get into Friday. This can be cash, pips or both.
//Leave the inputs blank to disable the feature. Thanks John.
extern string  BasketFridayCashTargets="";
extern string  BasketFridayPipsTargets="";
////////////////////////////////////////////////////////////////////////////////////////
double         originalBasketTargetCash=0;
double         originalBasketTargetPips=0;
////////////////////////////////////////////////////////////////////////////////////////

//Trading done for the week stuff
extern string  tdfw="-- Trading done for the week inputs --";
extern bool    UseTradingDoneForTheWeek=false;
//Default to stop trading in Thursday
extern DaysOfWeek TargetDay=Thursday;
//'Hard' targets
extern int     WeeklyCashTarget=0;
extern int     WeeklyPipsTarget=0;
//Dynamic targets. The default equates to 2 basket TP's.
extern bool    UseDynamicWeeklyTargetCash=true;       
extern bool    UseDynamicWeeklyTargetPips=false;       
extern int     WeeklyTargetBasketTpMultiplier=2;
//Build in some tolerance for slippage during closure.
extern double  SlippageTolerancePercent=10;
////////////////////////////////////////////////////////////////////////////////////////
bool           doneForTheWeek=false;
double         closedTradesCash=0, closedTradesPips=0;
string         DoneForTheWeekGV="SPB_Done for the week GV";//A global variable to reset doneForTheWeek on a reset.
////////////////////////////////////////////////////////////////////////////////////////

//This code by tomele. Thank you Thomas. Wonderful stuff.
extern string  sep7b="================================================================";
extern string  roll="---- Rollover time ----";
extern bool    DisableEaDuringRollover=true;
extern string  ro1 = "Use 24H format, SERVER time.";
extern string  ro2 = "Example: '23.55'";
extern string  RollOverStarts="23.55";
extern string  RollOverEnds="00.15";
////////////////////////////////////////////////////////////////////////////////////////
bool           rolloverInProgress=false;//Tells displayUserFeedback() to display the rollover message
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep8="================================================================";
extern string  bf="----Trading balance filters----";
extern bool    UseZeljko=false;
extern bool    OnlyTradeCurrencyTwice=false;
////////////////////////////////////////////////////////////////////////////////////////
bool           canTradeThisPair;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep9="================================================================";
extern string  pts="----Swap filter----";
extern bool    CadPairsPositiveOnly=false;
extern bool    AudPairsPositiveOnly=false;
extern bool    NzdPairsPositiveOnly=false;
extern bool    OnlyTradePositiveSwap=false;
//This next input allows users to trade negative swap pairs but sets a maximum negative swap.
extern double  MaximumAcceptableNegativeSwap=-1000000;
//CSV strings for buy only and sell only pairs
extern string  BuyOnlyPairs="";
extern string  SellOnlyPairs="";
////////////////////////////////////////////////////////////////////////////////////////
//Variables/arrays to hold the buy/sell only pairs
int            noOfBuyOnlyPairs=0, noOfSellOnlyPairs=0;
string         buyOnlyPairs[], sellOnlyPairs[];
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep10="================================================================";
extern string  amc="----Available Margin checks----";
extern string  sco="Scoobs";
extern bool    UseScoobsMarginCheck=false;
extern string  fk="ForexKiwi";
extern bool    UseForexKiwi=true;
extern int     FkMinimumMarginPercent=500;
////////////////////////////////////////////////////////////////////////////////////////
bool           enoughMargin;
string         marginMessage;
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

extern string  sep11="================================================================";
extern string  asi="----Average spread inputs----";
bool    RunInSpreadDetectionMode=false;
//The ticks to count whilst canculating the av spread
//extern int     TicksToCount=5;
extern double  MultiplierToDetectStopHunt=10;
////////////////////////////////////////////////////////////////////////////////////////
double         spreadArray[][9];
string         spreadGvName;//A GV will hold the calculated average spread
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep13="================================================================";
extern string  tmm="----Trade management module----";
//Breakeven has to be enabled for JS and TS to work.
extern string  BE="Break even settings";
extern bool    BreakEven=false;
extern int     BreakEvenTargetPips=20;
extern int     BreakEvenTargetProfit=2;
extern bool    PartCloseEnabled=false;
//Percentage of the trade lots to close
extern double  PartClosePercent=50;
////////////////////////////////////////////////////////////////////////////////////////
double         breakEvenPips,breakEvenProfit;
bool           TradeHasPartClosed=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep14="================================================================";
extern string  JSL="Jumping stop loss settings";
extern bool    JumpingStop=false;
extern int     JumpingStopTargetPips=2;
////////////////////////////////////////////////////////////////////////////////////////
double         jumpingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep15="================================================================";
extern string  cts="----Candlestick jumping stop----";
extern bool    UseCandlestickTrailingStop=false;
//Defaults to current chart
extern int     CstTimeFrame=0;
//Defaults to previous candle
extern int     CstTrailCandles=1;
extern bool    TrailMustLockInProfit=true;
////////////////////////////////////////////////////////////////////////////////////////
int            oldCstBars;//For candlestick ts
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep16="================================================================";
extern string  TSL="Trailing stop loss settings";
extern bool    TrailingStop=false;
extern int     TrailingStopTargetPips=20;
////////////////////////////////////////////////////////////////////////////////////////
double         trailingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep17="================================================================";
//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  chf               ="---- Chart feedback display ----";
int     chartRefreshDelaySeconds=0;
// if using Comments
int     displaygapSize    = 30; 
// ****************************** added to make screen Text more readable
// replaces Comment() with OBJ_LABEL text
bool    displayAsText     = true;  
//Disable the chart in foreground CrapTx setting so the candles do not obscure the textbool    KeepTextOnTop     = true;
extern int     displayX          = 100;
extern int     displayY          = 0;
extern double  ScaleX            = 1.0;
extern double  ScaleY            = 1.0;
extern int     fontSize          = 9;
extern string  fontName          = "Arial";
extern color   colour            = Yellow;

extern string  dad               ="---- Dashboard display ----";

// TDesk - disable internal dashboard when using TDesk
extern bool    ShowDashboard    = true;
extern bool    SendTDeskSignals = false;

extern bool    HidePipsDetails  = false;
extern bool    HideCashDetails  = false;
extern bool    HideSwapDetails  = false;
extern bool    HideSpreadDetails= false;

extern color   UpSignalColor    = clrGreen;
extern color   DnSignalColor    = clrRed;
extern color   NoSignalColor    = clrSilver;
extern color   ButtonColor      = clrCyan;
//Add other colours here

extern string  cdb               ="---- Alternative multi-color dashboard ----";
extern bool    ColoredDashboard = true;
//Values below are only applicated if ColoredDashboard is "true"
extern color   HeadColor        = 0x404040;
extern color   RowColor1        = 0x202020;
extern color   RowColor2        = 0x303030;
extern color   TitleColor       = White;
extern color   TradePairColor   = Yellow;
extern color   TextColor        = Gray;
extern color   SpreadAlertColor = Yellow;
extern color   StopHuntColor    = Orange;
extern color   PosNumberColor   = SeaGreen;
extern color   NegNumberColor   = DarkGoldenrod;
extern color   PosSumColor      = SpringGreen;
extern color   NegSumColor      = Gold;

////////////////////////////////////////////////////////////////////////////////////////
int            displayCount;
string         gap,screenMessage,whatToShow="AllPairs";

////////////////////////////////////////////////////////////////////////////////////////

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


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

   if(WriteFileForTestDatabase) 
      ChartSaveTemplate(0,StringFormat("ZZT2MTPL-%s-%s-%s-%d-%d-%d-%d","SHF","MD","MULSYM",Period(),AccountNumber(),TimeCurrent(),MagicNumber));

   // TDesk code
   if (SendToTDesk)
      InitializeTDesk(TradeComment,MagicNumber);

   //Incorrect trading style choices
   //Both enabled
   if (UseSingleTradingMethod)
      if (UseGridTradingMethod)
      {
         Alert("You have both trading styles enabled. This would damage the MD's working, so Grid trading is disabled.");
         UseGridTradingMethod = false;
      }//if (UseGridTradingMethod)
      
   //Nothing enabled
   if (!UseSingleTradingMethod)
      if (!UseGridTradingMethod)
      {
         Alert("You have not enabled a trading style. I have enabled the single trading style for you.");
         UseGridTradingMethod = true;
      }//if (!UseGridTradingMethod)
      
   //Missing indi check
   /*
   if (!indiExists( "IndiName" ))
   {
      Alert("");
      Alert("Download the indi from the thread.");//Follow this with a link to the thread.
      Alert("The required indicator " + "IndiName" + " does not exist on your platform. I am removing myself from your chart.");
      removeExpert = true;
      ExpertRemove();
      return(0);
   }//if (! indiExists( "IndiName" ))
   */
   
   //create timer
   //EventSetTimer(EventTimerIntervalSeconds);
   secureSetTimer(EventTimerIntervalSeconds);//Explanation at the top of the function
   
   
   stopLoss=StopLossPips;
   takeProfit=TakeProfitPips;
   breakEvenPips=BreakEvenTargetPips;
   breakEvenProfit = BreakEvenTargetProfit;
   jumpingStopPips = JumpingStopTargetPips;
   trailingStopPips = TrailingStopTargetPips;
   distanceBetweenTrades = DistanceBetweenTradesPips;
   stopOrderDistance = StopOrderDistancePips;
   pendingDistanceToFirstTrade = PendingDistanceToFirstTradePips;
   DistanceBetweenLevels = DistanceBetweenLevelsPips;
   oppositeSideStopLoss = OppositeSideStopLossPips;
   
   
   
   //Extract the pairs traded by the user
   extractPairs();

   
   StringInit(gap, displaygapSize, ' ' );
   
   
   readIndicatorValues();//Initial read


   //Lot size based on account size
   if (!closeEnough(LotsPerDollopOfCash, 0))
      calculateLotAsAmountPerCashDollops();


   //Calculate a dynamic whole basket TP for initial display
   if (UseDynamicCashTP)
   {
      //Applied to a fixed lot size
      if (closeEnough(LotsPerDollopOfCash, 0))
         if (closeEnough(RiskPercent, 0))
            calculateDynamicBasketCashTP(Lot);

   
      //LotsPerDollop
      if (!closeEnough(LotsPerDollopOfCash, 0))
      {
         calculateLotAsAmountPerCashDollops();
         calculateDynamicBasketCashTP(Lot);
      }//if (!closeEnough(LotsPerDollopOfCash, 0))
         
      //RiskPercent   
      if (!closeEnough(RiskPercent, 0))
      {
         //Simulate a trade to calculate the lot size for a RiskPercent-based trade.
         double stop = 0, price = 0;
         string symbol = tradePair[0];
         price = MarketInfo(tradePair[0], MODE_ASK);
         stop = calculateStopLoss(tradePair[0], OP_BUY, price);
         double sendLots = calculateLotSize(symbol, price, stop);
      
         calculateDynamicBasketCashTP(sendLots);
      
      }//if (!closeEnough(RiskPercent, 0))
      
      
   }//if (UseDynamicCashTP)

   originalBasketTargetCash=BasketTargetCash;
   originalBasketTargetPips=BasketTargetPips;   
      

   
   
   //Set up the trading hours
   tradingHoursdisplay=tradingHours;//For display
   initTradingHours();//Sets up the trading hours array


   //Trading done for the week stuff.
   //This allows doneForTheWeek to reset to 'true' following a restart.
   if (GlobalVariableCheck(DoneForTheWeekGV))//Is there a GV?
   {
      //Extract the time.
      datetime WeekStartTime = (datetime) GlobalVariableGet(DoneForTheWeekGV);
      
      
      //Is it the start of this week?
      if (WeekStartTime == iTime(Symbol(), PERIOD_W1, 0) )
         doneForTheWeek = true; 

      //Is it a previous week?
      if (WeekStartTime < iTime(Symbol(), PERIOD_W1, 0) )
      {
         doneForTheWeek = false;//Reset the bool
         GlobalVariableDel(DoneForTheWeekGV);//Delete the GV
      }//if (WeekStartTime < iTime(Symbol(), PERIOD_W1, 0) )
      
   }//if (GlobalVariableCheck(DoneForTheWeekGV))
   

   //Addition to John's codei
   //Allow a trailing stop to resume following a restart
   if(TreatAllPairsAsBasket)
   {
      if (UseBasketTrailingStopCash)
         if (GlobalVariableCheck(bTSTrailingStopCashGV) )
            bTSStopLossCash = GlobalVariableGet(bTSTrailingStopCashGV);
            
      if (UseBaskettrailingStopPips)
         if (GlobalVariableCheck(bTStrailingStopPipsGV) )
            bTSStopLossPips = GlobalVariableGet(bTStrailingStopPipsGV);
   
   }//if(TreatAllPairsAsBasket)
      
 
   //Users cannot use both UseBasketTrailingStopCash and UseBasketTrailingStopPercentage
   if (UseBasketTrailingStopPercentage)
   {
      UseBasketTrailingStopCash = false;
      //UseBasketTrailingStopPercentage uses the cash TS variables, so set them to 0.
      BasketTrailingStopStartValueCash = 0;
      BasketTrailingStopgapValueCash = 0;
   }//if (UseBasketTrailingStopPercentage)
   
 
               
   displayUserFeedback();

   
   return(INIT_SUCCEEDED);
}

void extractPairs()
{
   
   StringSplit(PairsToTrade,',',tradePair);
   noOfPairs = ArraySize(tradePair);
   int cc = 0;
   
   
   // Resize the arrays appropriately
   ArrayResize(tradePair, noOfPairs);
   ArrayResize(ttfCandleTime, noOfPairs);
   ArrayResize(buySignal, noOfPairs);
   ArrayResize(buyCloseSignal, noOfPairs);
   ArrayResize(sellCloseSignal, noOfPairs);
   ArrayResize(sellSignal, noOfPairs);
   ArrayResize(timeToStartTrading, noOfPairs);
   ArrayResize(oldCandleReadTime, noOfPairs);
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
   ArrayResize(buyCashUpl, noOfPairs);
   ArrayResize(sellCashUpl, noOfPairs);
   ArrayResize(mastatus, noOfPairs);
   

   
   for (cc = 0; cc < noOfPairs; cc ++)
   {
      tradePair[cc] = StringTrimLeft(tradePair[cc]);
      tradePair[cc] = StringTrimRight(tradePair[cc]);
      tradePair[cc] = StringConcatenate(PairPrefix, tradePair[cc], PairSuffix);
      
      timeToStartTrading[cc] = 0;
      oldCandleReadTime[cc] = 0;
      
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


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    
   ArrayFree(tradePair);
   ArrayFree(ttfCandleTime);
   ArrayFree(oldCandleReadTime);
   ArrayFree(buySignal);
   ArrayFree(sellSignal);
   ArrayFree(sellCloseSignal);
   ArrayFree(buyCloseSignal);
   ArrayFree(timeToStartTrading);
   ArrayFree(pipsUpl);
   ArrayFree(cashUpl);
   ArrayFree(buyTradeTotals);
   ArrayFree(sellTradeTotals);
   ArrayFree(closedBuyTradeTotals);
   ArrayFree(closedSellTradeTotals);
   ArrayFree(buyOnlyPairs);
   ArrayFree(sellOnlyPairs);
   ArrayFree(longOnlyPairs);
   ArrayFree(shortOnlyPairs);
   ArrayFree(buyCashUpl);
   ArrayFree(sellCashUpl);
   ArrayFree(mastatus);
   ArrayFree(pairsTraded);
   


   removeAllObjects();
   
   // TDesk code
   DeleteTDeskSignals();
   
   //--- destroy timer
   EventKillTimer();
       
}

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

void displayUserFeedback()
{
   //Update all values
   countTotalsForDisplay();
   calculateClosedProfits();
   
   string text = "";
   //int cc = 0;
   
 
   //   ************************* added for OBJ_LABEL
   displayCount = 1;
   //removeAllObjects();
   //   *************************

 
   screenMessage = "";
   //screenMessage = StringConcatenate(screenMessage,gap + NL);
   //sm(NL);
   
   sm("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   sm("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);
   sm("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   sm(version + NL);
   sm(marginMessage + NL);   
   sm(NL);

   
   if (AutoTradingEnabled)
   {
      if(rolloverInProgress)
      {
         sm(NL);
         sm("---------- ROLLOVER IN PROGRESS. I am taking no action until "+RollOverEnds+" ----------"+NL);
      }//if (RolloverInProgress)
   
      //Trading done for the week stuff
      if (doneForTheWeek)
         sm("---------- WE HAVE REACHED OUR WEEKLY PROFIT TARGET. I HAVE STOPPED TRADING UNTIL NEXT WEEK. ----------" + NL);

      //Trading suspended for the day after a whole-position basket closure
      //Trading done for the week stuff
      if (tradingSuspendedAfterBasketClosure)
         sm("---------- I HAVE CLOSED A WHOLE-POSITION BASKET. I HAVE STOPPED TRADING UNTIL THE NEXT D1 CANDLE. ----------" + NL);


   }//if (AutoTradingEnabled)
   
   sm(NL);
   sm(NL);
   //if (TreatAllPairsAsBasket)
     // sm("Lot size = " + DoubleToStr(Lot, 2) + ": Basket cash take profit = " + AccountCurrency() + " " + DoubleToStr(BasketTargetCash, 2) + NL);
   
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
   if(TreatAllPairsAsBasket && UseBasketTrailingStopCash)
   {
      string descr = "Basket Cash Trailing Stop active";
      if(bTSActivatedCash)
         descr += ": Basket Cash stopLoss Value: " + DoubleToStr(bTSStopLossCash, 2) + " Current Cash Proft: " + DoubleToStr(totalCashUpl, 2);
      else
         descr += ": Distance to cash target ("+DoubleToStr(BasketTrailingStopStartValueCash,2)+") = " 
                  + DoubleToStr(BasketTrailingStopStartValueCash - totalCashUpl, 2);
      sm(descr + NL);
   }
   
   //This came from DigitalCrypto. Thanks David.
   if (TreatAllPairsAsBasket)
   {
      if (BasketTargetCash > 0)
         sizingInfo +=  " , Basket cash take profit = " + AccountCurrency() + " " + DoubleToStr(BasketTargetCash, 2) ;
   
      if (BasketTargetPips > 0)
         sizingInfo +=  " , Basket take profit pips = " + IntegerToString(BasketTargetPips);
     
   }
   
   if (UseSingleTradingMethod)
   {
      sizingInfo = sizingInfo + "   Single trading method is enabled. ";
      if (TypeOfOrder == MarketOrder)
         sizingInfo = sizingInfo + "Sending immediate market orders.";
      else
         sizingInfo = sizingInfo + "Sending stop orders at " + IntegerToString(StopOrderDistancePips) + " pips from market price.";  
   }//if (UseSingleTradingMethod)
   else   
      sizingInfo = sizingInfo + "   Grid trading method is enabled";
      
   sm(sizingInfo + NL);
      
   //This is John's cash basket TS adapted for pips
   if(TreatAllPairsAsBasket && UseBaskettrailingStopPips)
   {
      string descr = "Basket Pips Trailing Stop active";
      if(bTSActivatedPips)
         descr += ": Basket Pips stopLoss Value: " + DoubleToStr(bTSStopLossPips, 2) 
         + " Current Pips Proft: " + DoubleToStr(totalPipsUpl, 0);
      else
         descr += ": Distance to pips target ("+DoubleToStr(BasketTrailingStopStartValuePips,0)+") = " 
                  + DoubleToStr(BasketTrailingStopStartValuePips - totalPipsUpl, 0);
      sm(descr + NL);
   }
   
      
   // TDesk
   if(ShowDashboard)
   {   
      sm("Click a pair to open its chart, the table name to switch between views, the headers to show/hide details, the labels at the bottom to let them do what they offer."+NL);
      displayMatrix();
   }

 
   //Comment(screenMessage);


}//End void displayUserFeedback()

void displayMatrix()
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
   int TextYPos=displayY+displayCount*(int)(FactorY*1.5)+(int)(FactorY*3);
   
   //Detect need for deleting and redrawing the matrix at different y-position
   string PosMarker="OAM-displayStart"+IntegerToString(TextYPos);
   if(ObjectFind(0,PosMarker)<0)
   {
      removeAllObjects();
      ObjectCreate(PosMarker,OBJ_LABEL,0,0,0);
      ObjectSetText(PosMarker,"");
      displayUserFeedback();
      return;
   }

   //These are the sizes of the different columns
   int TPLength=(int)(FactorX*7); //tradePair column
   int SSLength=(int)(FactorX*4); //SuperSlope columns
   int TSLength=(int)(FactorX*4); //TradeStatus column
   int TRLength=(int)(FactorX*6); //Trades column
   int PPLength=(int)(FactorX*7); //Profit/Loss in pips columns
   int PCLength=(int)(FactorX*7); //Profit/Loss in cash columns
   int SWLength=(int)(FactorX*6); //Swap columns
   int SPLength=(int)(FactorX*7); //Spread columns
   
   int GDLength=(int)(FactorX*2);   //Group divider (empty space)
   int TTLength=(int)(FactorX*118); //Table total (all columns and dividers +1 for the margins)
   
   if(HidePipsDetails)
      TTLength-=2*PPLength;
   if(HideCashDetails)
      TTLength-=2*PCLength;
   if(HideSwapDetails)
      TTLength-=2*SWLength;
   if(HideSpreadDetails)
      TTLength-=3*SPLength;
      
   
   //display Headers
   
   TextXPos=displayX;
   
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
   
   if (whatToShow=="AllPairs")
   {
      text1="All Pairs";
      text2="Unrealized P/L";
      PLString="UPL";
   }
   else if (whatToShow=="TradablePairs")
   {
      text1="Tradable Pairs";
      text2="Unrealized P/L";
      PLString="UPL";
   }
   else if (whatToShow=="openTrades")
   {
      text1="Open Trades";
      text2="Unrealized P/L";
      PLString="UPL";
   }
   else if (whatToShow=="closedTrades")
   {
      text1="Closed Trades";
      text2="Realized P/L";
      PLString="RPL";
   }
   else if (whatToShow=="AllTrades")
   {
      text1="All Trades";
      text2="Total P/L";
      PLString="TPL";
   }
   
   displayTextLabel(text1,TextXPos,TextYPos,ANCHOR_LEFT_UPPER,"SWITCH", 0, ButtonColor);
   displayTextLabel(text2,TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_LEFT_UPPER,"SWITCH", 0, ButtonColor);
   TextXPos+=TPLength;
   
   //Now draw all the column headers
   
   TextXPos+=GDLength; //Group divider
   
   
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=TRLength;
   displayTextLabel("Open",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   displayTextLabel("Trades",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=PPLength;
   displayTextLabel("Sum "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"HIDEPIPS", 0, ButtonColor);
   displayTextLabel("in pips",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"HIDEPIPS", 0, ButtonColor);

   if(!HidePipsDetails)
   {
      TextXPos+=PPLength;
      displayTextLabel("Buy "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("in pips",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   
      TextXPos+=PPLength;
      displayTextLabel("Sell "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("in pips",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }   
   
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=PCLength;
   displayTextLabel("Sum "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"HIDECASH", 0, ButtonColor);
   displayTextLabel("in " + AccountCurrency(),TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"HIDECASH", 0, ButtonColor);

   if(!HideCashDetails)
   {
      TextXPos+=PCLength;
      displayTextLabel("Buy "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("in " + AccountCurrency(),TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   
      TextXPos+=PCLength;
      displayTextLabel("Sell "+PLString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("in " + AccountCurrency(),TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }
      
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=SWLength;
   displayTextLabel("Trades",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"HIDESWAP", 0, ButtonColor);
   displayTextLabel("Swap",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"HIDESWAP", 0, ButtonColor);
   
   if(!HideSwapDetails)
   {
      TextXPos+=SWLength;
      displayTextLabel(" Long",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("Swap",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      
      TextXPos+=SWLength;
      displayTextLabel(" Short",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("Swap",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }
   
   TextXPos+=GDLength; //Group divider
   
   TextXPos+=SPLength;
   displayTextLabel("Actual",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"HIDESPREAD", 0, ButtonColor);
   displayTextLabel("Spread",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"HIDESPREAD", 0, ButtonColor);
   
   if(!HideSpreadDetails)
   {
      TextXPos+=SPLength;
      displayTextLabel("Average",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("Spread",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      
      TextXPos+=SPLength;
      displayTextLabel("Longterm",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("Spread",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      
      TextXPos+=SPLength;
      displayTextLabel("Biggest",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("Spread",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
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
   for (int pairIndex = 0; pairIndex <= ArraySize(tradePair) - 1; pairIndex++)
   {
      countTradesForDashboard(tradePair[pairIndex]);
      countClosedTradesForDashboard(tradePair[pairIndex]);
      
      //Apply the filter      
      if (whatToShow=="TradablePairs" && mastatus[pairIndex] == untradable)
            continue;
      if (whatToShow=="openTrades" && openTrades==0)
           continue;
      if (whatToShow=="closedTrades" && closedTrades==0)
           continue;
      if (whatToShow=="AllTrades" && openTrades+closedTrades==0)
           continue;

      getBasics(tradePair[pairIndex]);
      
      int ActLongTrades=openLongTrades;
      int ActShortTrades=openShortTrades;
      double ActBuyTradeTotalsPips=buyTradeTotals[pairIndex][pipst];
      double ActSellTradeTotalsPips=sellTradeTotals[pairIndex][pipst];
      double ActBuyTradeTotalsCash=buyTradeTotals[pairIndex][casht];
      double ActSellTradeTotalsCash=sellTradeTotals[pairIndex][casht];
      double ActBuyTradeTotalsSwap=buyTradeTotals[pairIndex][swapt];
      double ActSellTradeTotalsSwap=sellTradeTotals[pairIndex][swapt];
      
      if (whatToShow=="closedTrades")
      {
         ActLongTrades=closedLongTrades;
         ActShortTrades=closedShortTrades;
         ActBuyTradeTotalsPips=closedBuyTradeTotals[pairIndex][pipst];
         ActSellTradeTotalsPips=closedSellTradeTotals[pairIndex][pipst];
         ActBuyTradeTotalsCash=closedBuyTradeTotals[pairIndex][casht];
         ActSellTradeTotalsCash=closedSellTradeTotals[pairIndex][casht];
         ActBuyTradeTotalsSwap=closedBuyTradeTotals[pairIndex][swapt];
         ActSellTradeTotalsSwap=closedSellTradeTotals[pairIndex][swapt];
      }
      else if (whatToShow=="AllTrades")
      {
         ActLongTrades=openLongTrades+closedLongTrades;
         ActShortTrades=openShortTrades+closedShortTrades;;
         ActBuyTradeTotalsPips=buyTradeTotals[pairIndex][pipst]+closedBuyTradeTotals[pairIndex][pipst];
         ActSellTradeTotalsPips=sellTradeTotals[pairIndex][pipst]+closedSellTradeTotals[pairIndex][pipst];
         ActBuyTradeTotalsCash=buyTradeTotals[pairIndex][casht]+closedBuyTradeTotals[pairIndex][casht];
         ActSellTradeTotalsCash=sellTradeTotals[pairIndex][casht]+closedSellTradeTotals[pairIndex][casht];
         ActBuyTradeTotalsSwap=buyTradeTotals[pairIndex][swapt]+closedBuyTradeTotals[pairIndex][swapt];
         ActSellTradeTotalsSwap=sellTradeTotals[pairIndex][swapt]+closedSellTradeTotals[pairIndex][swapt];
      }
   
      //Start the line
      TextXPos=displayX;
      
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

      // Draw the tradePair and its data in one line
      
      displayTextLabel(tradePair[pairIndex],TextXPos,TextYPos, ANCHOR_LEFT_UPPER, tradePair[pairIndex], 0, ActTradePairColor);
      SumPairs+=1;
      TextXPos+=TPLength;

      
      
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
      displayTextLabel(trades,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, tcolor);
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
         displayTextLabel(DoubleToStr(ActValue, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"",0,ActColor);
      else
         displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      
      if(!HidePipsDetails)
      {
         TextXPos+=PPLength;
         if (ActLongTrades>0)
            displayTextLabel(DoubleToStr(ActBuyTradeTotalsPips, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         else
            displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

         TextXPos+=PPLength;
         if (ActShortTrades>0)
            displayTextLabel(DoubleToStr(ActSellTradeTotalsPips, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         else
            displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
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
         displayTextLabel(DoubleToStr(ActValue, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"",0,ActColor);
      else
         displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      
      if(!HideCashDetails)
      {
         TextXPos+=PCLength;
         if (ActLongTrades>0)
            displayTextLabel(DoubleToStr(ActBuyTradeTotalsCash, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         else
            displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         
         TextXPos+=PCLength;
         if (ActShortTrades>0)
            displayTextLabel(DoubleToStr(ActSellTradeTotalsCash, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         else
            displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
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
         displayTextLabel(DoubleToStr(ActValue, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"",0,ActColor);
      else
         displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      SumTradeSwap+=ActBuyTradeTotalsSwap+ActSellTradeTotalsSwap;
      
      if(!HideSwapDetails)
      {
         TextXPos+=SWLength;
         displayTextLabel(DoubleToStr(longSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
         
         TextXPos+=SWLength;
         displayTextLabel(DoubleToStr(shortSwap, 2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      }
      
      TextXPos+=GDLength; //Group divider
      
      //Highlight the spreads if unusual (higher than double the average or higher than biggest)
      ActColor=ActTextColor;
      if (!spreadCheck(pairIndex) )
      {   
         ActColor=ActStopHuntColor;
         SumStopHuntAlerts+=1;
      }
      else if(NormalizeDouble(spreadArray[pairIndex][averagespread],1)>MathMax(NormalizeDouble(spreadArray[pairIndex][longtermspread],1),0.1)*3)
      {
         ActColor=ActSpreadAlertColor;
         SumSpreadAlerts+=1;
      }

      TextXPos+=SPLength;
      displayTextLabel(DoubleToStr(spread, 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
      
      if(!HideSpreadDetails)
      {
         TextXPos+=SPLength;
         displayTextLabel(DoubleToStr(spreadArray[pairIndex][averagespread], 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
         
         TextXPos+=SPLength;
         displayTextLabel(DoubleToStr(spreadArray[pairIndex][longtermspread], 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
         
         TextXPos+=SPLength;
         displayTextLabel(DoubleToStr(spreadArray[pairIndex][biggestspread], 1) + " pips",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
      }
             
      //Point to the next YPos to start a new line
      TextYPos+=(int)(FactorY*1.8);
        
   }//for (pairIndex = 0; pairIndex <= ArraySize(tradePair) -1; pairIndex++)
   
   //display summary line
   
   TextXPos=displayX;
   
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
      displayTextLabel(IntegerToString((int)ActValue)+" pairs",TextXPos,TextYPos,ANCHOR_LEFT_UPPER,"", 0, ActTitleColor);
   else
      displayTextLabel("No matching pairs",TextXPos,TextYPos,ANCHOR_LEFT_UPPER,"", 0, ActTitleColor);
   TextXPos+=TPLength;
   
   TextXPos+=GDLength; //Group divider
   
  
   TextXPos+=TSLength; //Group divider
   
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

   //TextXPos+=2;
   int ActTrades=SumLongTrades+SumShortTrades;
   ActString=IntegerToString(ActTrades)+" trades";
   if(ColoredDashboard)
      ActColor=ActTitleColor;
   else
      ActColor=NoSignalColor;
   if(ActTrades>0)
      displayTextLabel(ActString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER, "", 0, ActColor);
   else
      displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   
   TextXPos+=GDLength; //Group divider

   TextXPos+=PPLength;
   ActValue=SumLongPips+SumShortPips;
   if(ActValue>0)
      ActColor=ActPosSumColor;
   else
      ActColor=ActNegSumColor;
   if(ActTrades>0)
      displayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
   else
      displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

   if(!HidePipsDetails)
   {
      TextXPos+=PPLength;
      ActValue=SumLongPips;
      if(ActValue>0)
         ActColor=ActPosNumberColor;
      else
         ActColor=ActNegNumberColor;
      if(ActTrades>0)
         displayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
      else
         displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   
      TextXPos+=PPLength;
      ActValue=SumShortPips;
      if(ActValue>0)
         ActColor=ActPosNumberColor;
      else
         ActColor=ActNegNumberColor;
      if(ActTrades>0)
         displayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
      else
         displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   }
   
   TextXPos+=GDLength; //Group divider
      
   TextXPos+=PCLength;
   ActValue=SumLongCash+SumShortCash;
   if(ActValue>0)
      ActColor=ActPosSumColor;
   else
      ActColor=ActNegSumColor;
   if(ActTrades>0)
      displayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
   else
      displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

   if(!HideCashDetails)
   {
      TextXPos+=PCLength;
      ActValue=SumLongCash;
      if(ActValue>0)
         ActColor=ActPosNumberColor;
      else
         ActColor=ActNegNumberColor;
      if(ActTrades>0)
         displayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
      else
         displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   
      TextXPos+=PCLength;
      ActValue=SumShortCash;
      if(ActValue>0)
         ActColor=ActPosNumberColor;
      else
         ActColor=ActNegNumberColor;
      if(ActTrades>0)
         displayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
      else
         displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   }
   
   TextXPos+=GDLength; //Group divider
      
   TextXPos+=SWLength;
   ActValue=SumTradeSwap;
   if(ActValue>0)
      ActColor=ActPosSumColor;
   else
      ActColor=ActNegSumColor;
   if(ActTrades>0)
      displayTextLabel(DoubleToStr(ActValue,2),TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
   else
      displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
   
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
      else if(SumSpreadAlerts>(int)(ArraySize(tradePair)/3))
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
      displayTextLabel(ActString,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActColor);
   }
   else
      displayTextLabel("",TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);

   //Draw the buttons below the table
   TextYPos+=(int)(FactorY*4);

   displayTextLabel("Open all charts in alphabetical order",displayX,TextYPos,ANCHOR_LEFT_UPPER,"OPENALL", 0, ButtonColor);
   displayTextLabel("Open all trades in alphabetical order",displayX+(int)(FactorX*25),TextYPos,ANCHOR_LEFT_UPPER,"OPENTRADES", 0, ButtonColor);
   displayTextLabel("Touch all charts for CTRL-F6 browsing",displayX+(int)(FactorX*50),TextYPos,ANCHOR_LEFT_UPPER,"TOUCH", 0, ButtonColor);
   displayTextLabel("Close all charts",(int)(displayX+FactorX*76),TextYPos,ANCHOR_LEFT_UPPER,"CLOSE", 0, ButtonColor);
   //displayTextLabel("Minimise all charts",(int)(displayX+FactorX*90),TextYPos,ANCHOR_LEFT_UPPER,"MINIMISE", 0, ButtonColor);

   
}//End void displayMatrix()


void displayTextLabel(string text, int xpos, int ypos, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, string pair="", int tf=0, color scol=clrNONE)
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
      //Clickable label needs pair and timeframe for openChart()
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
   
}//End void displayTextLabel(string text, int xpos, int ypos, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)



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


double getAtr(string symbol, int tf, int period, int shift)
{
   //Returns the value of atr
   
   return(iATR(symbol, tf, period, shift) );   

}//End double getAtr()


double getMa(string symbol, int tf, int period, int mashift, int method, int ap, int shift)
{
   return(iMA(symbol, tf, period, mashift, method, ap, shift) );
}//End double getMa(int tf, int period, int mashift, int method, int ap, int shift)


void readIndicatorValues()
{

   
   for (int pairIndex = 0; pairIndex <= ArraySize(tradePair) - 1; pairIndex++)
   {
      int cc = 0;
      double val = 0;
      
      string symbol = tradePair[pairIndex];//Makes typing easier
  
      countOpenTrades(symbol, pairIndex);

      getBasics(symbol);//Bid etc

      //Prevent multiple trades
      buySignal[pairIndex] = false;
      sellSignal[pairIndex] = false;
      
      int shift = 1;
      if (EveryTickMode)
      {
         shift = 0;
         oldCandleReadTime[pairIndex] = 0;
      }//if (EveryTickMode)
      
      
      //Trade trigger
      //Moving average filter
      if (oldCandleReadTime[pairIndex] != iTime(symbol, TradingTimeFrame, 0) )
      {
         oldCandleReadTime[pairIndex] = iTime(symbol, TradingTimeFrame, 0);
         double maval = 0;
         
         double close0 = iClose(symbol, TradingTimeFrame, shift);
         double close1 = iClose(symbol, TradingTimeFrame, shift + 1);
         
         
         //Read the D1 (can be a user choice of a different time frame) MA
         maval = getMa(symbol, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 0);

         //Nothing I can do will persuade this blasted bot to close opposite direction trades in the
         //appropriate function, so code the closure here instead.
         int tries = 0;
         forceTradeClosure = false;
         
         //Close sell trades
         if (bid > maval)
         {
            sellCloseSignal[pairIndex] = true;
            closeAllTrades(symbol, OP_SELL);
            while (forceTradeClosure)
            {
               tries++;
               if (tries>= 100)//Something has gone wrong, so reset the loop
               {
                  cc++;
                  oldCandleReadTime[pairIndex] = 0;
                  continue;
               }//if (tries>= 100)
               
               Sleep(1000);
               closeAllTrades(symbol, OP_SELL);
            }//while (forceTradeClosure)
            if (!forceTradeClosure)
               sellCloseSignal[pairIndex] = false;
         }//if (bid > maval)
      
         //Close buy trades
         if (bid < maval)
         {
            buyCloseSignal[pairIndex] = true;
            closeAllTrades(symbol, OP_BUY);
            while (forceTradeClosure)
            {
               tries++;
               if (tries>= 100)//Something has gone wrong, so reset the loop
               {
                  cc++;
                  oldCandleReadTime[pairIndex] = 0;
                  continue;
               }//if (tries>= 100)
               
               Sleep(1000);
               closeAllTrades(symbol, OP_BUY);
            }//while (forceTradeClosure)
            if (!forceTradeClosure)
               buyCloseSignal[pairIndex] = false;
         }//if (bid < maval)
      
         
         //Define the cross status
         mastatus[pairIndex] = untradable;
         
         buyCloseSignal[pairIndex] = false;
         sellCloseSignal[pairIndex] = false;
         
         //Long cross?
         if (close1 < maval )
            if (close0 > maval)
            {
               mastatus[pairIndex] = tradablelong;
               sellCloseSignal[pairIndex] = true;
            }//if (close0 > maval)
               
         //Short cross
         if (mastatus[pairIndex] == untradable)
            if (close1 > maval )
               if (close0 < maval)
               {
                  mastatus[pairIndex] = tradableshort;
                  buyCloseSignal[pairIndex] = true;
               }//if (close0 < maval)
               
         //In case an opposite direction cross has been missed
         if (bid < maval)
            buyCloseSignal[pairIndex] = true;
         if (bid > maval)
            sellCloseSignal[pairIndex] = true;
         
                  
         // TDesk code
         if (SendToTDesk)
         {
            if (mastatus[pairIndex] == untradable) PublishTDeskSignal("MA",TradingTimeFrame,symbol,FLAT); else
            if(mastatus[pairIndex] == tradablelong)  PublishTDeskSignal("MA",TradingTimeFrame,symbol,LONG); else
            if(mastatus[pairIndex] == tradableshort)   PublishTDeskSignal("MA",TradingTimeFrame,symbol,SHORT);
         }//if (SendToTDesk)
         
      }//if (oldCandleReadTime[pairIndex] != iTime(symbol, CandleTimeFrame, 0) )
      
      int barReadingPeriod = 0;//A variable that allows indis to be read once a candle if need be
      
       
         
      //Make the initial trading decision
               
      //Buy
      if (marketBuysCount == 0)
         if (buyStopsCount == 0)
            if (mastatus[pairIndex] == tradablelong)//Trade trigger
               buySignal[pairIndex] = true;
                     
      //Sell
      if (marketSellsCount == 0)
         if (sellStopsCount == 0)
            if (mastatus[pairIndex] == tradableshort)//Trade trigger
               sellSignal[pairIndex] = true;
                  
      /*
      //Fill in gaps if the market is moving in the wrong direction.
      //This is only needed if we are grid trading.
      if (UseGridTradingMethod)
      {
         double price = 0, target = 0, sendPrice = 0;
         double stop = 0, take = 0, sendLots = 0;
         bool result = true;
         if (GridSize > 0 && marginCheck() )
         {
            
            //Examine buys
            //if (buyStopsCount > 0 || marketBuysCount > 0 )
            if (buyStopsCount > 0 || marketBuysCount > 0)
            {
               //Is the market lower than the lowest buy/stop price
               price = MathMin(lowestBuyPrice, lowestBuyStopPrice);
               if (ask < price)
               {
                  //Atr for grid size
                  if (UseAtrForGrid)
                  {
                     val = getAtr(symbol, GridAtrTimeFrame, GridAtrPeriod, 0);
                     distanceBetweenTrades = (val * factor) / GridAtrDivisor;
                  }//if (UseAtrForGrid)
                  target = price - ((distanceBetweenTrades * 2) / factor);
                  
                  //Is there a gap to fill?
                  if (ask <= target)
                  {
                     sendPrice = NormalizeDouble(price - (distanceBetweenTrades / factor), digits);
                     //Yes, so set the parameters and send a trade
                     stop = calculateStopLoss(symbol, OP_BUY, sendPrice);
                     take = calculateTakeProfit(symbol, OP_BUY, sendPrice);
                     sendLots = Lot;
                     //Lot size calculated by risk
                     if (!closeEnough(RiskPercent, 0)) sendLots = calculateLotSize(symbol, sendPrice, stop );
                     //Lot size calculated by lots per dollop dollop
                     if (closeEnough(RiskPercent, 0))
                        if (!closeEnough(LotsPerDollopOfCash, 0) )
                        {
                           calculateLotAsAmountPerCashDollops();
                           sendLots = Lot;
                        }//if (!closeEnough(LotsPerDollopOfCash, 0) )
                    
                     
    
                     result = sendSingleTrade(symbol, OP_BUYSTOP, TradeComment, sendLots, sendPrice, stop, take);
                  }//if (ask <= target)
                  
               }//if (ask < price)
            
            }//if (buyStopsCount > 0 || marketBuysCount > 0)
         
            //Examine sells
            //if (sellStopsCount > 0 || marketSellsCount > 0)
            if (sellStopsCount > 0 || marketSellsCount > 0)
            {
               //Is the market lower than the lowest buy/stop price
               price = MathMax(highestSellPrice, highestSellStopPrice);
               if (bid > price)
               {
                  //Atr for grid size
                  if (UseAtrForGrid)
                  {
                     val = getAtr(symbol, GridAtrTimeFrame, GridAtrPeriod, 0);
                     distanceBetweenTrades = (val * factor) / GridAtrDivisor;
                  }//if (UseAtrForGrid)
                  target = price + ((distanceBetweenTrades * 2) / factor);
                  
                  //Is there a gap to fill?
                  if (bid >= target)
                  {
                     sendPrice = NormalizeDouble(price + (distanceBetweenTrades / factor), digits);
                     //Yes, so set the parameters and send a trade
                     stop = calculateStopLoss(symbol, OP_SELL, sendPrice);
                     take = calculateTakeProfit(symbol, OP_SELL, sendPrice);
                     sendLots = Lot;
                     //Lot size calculated by risk
                     if (!closeEnough(RiskPercent, 0)) sendLots = calculateLotSize(symbol, sendPrice, stop );
                     //Lot size calculated by lots per dollop dollop
                     if (closeEnough(RiskPercent, 0))
                        if (!closeEnough(LotsPerDollopOfCash, 0) )
                        {
                           calculateLotAsAmountPerCashDollops();
                           sendLots = Lot;
                        }//if (!closeEnough(LotsPerDollopOfCash, 0) )
   
                     
                        
                     result = sendSingleTrade(symbol, OP_SELLSTOP, TradeComment, sendLots, sendPrice, stop, take);
                  }//if (ask <= target)
                  
               }//if (bid >= target)
               
            
            }//if (sellStopsCount > 0 || marketSellsCount > 0)
         
         
         
         }//if (GridSize > 0)
            
     }//if (UseGridTradingMethod)
     */                    
         
         
     
   }//for (int cc = 0; cc <= ArraySize(tradePair); cc++)

   Comment("");
   
}//void readIndicatorValues()

void initialiseVariables(string symbol, int pairIndex)
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

}//End void initialiseVariables()


void countOpenTrades(string symbol, int pairIndex)
{
   
   initialiseVariables(symbol, pairIndex);
   int buyLoser = 0, sellLoser = 0;//For working out if the position is in Recovery.

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
               buyLoser++;
             
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
               sellLoser++;
            
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
      
      if (OrderType() < 2)
      {   
         TradeWasClosed = false;
         if (!areWeAtRollover())
            TradeWasClosed = lookForTradeClosure(OrderTicket(), pairIndex);
         if (TradeWasClosed) 
         {
            cc = OrdersTotal();//Restart the loop as the position has changed
            initialiseVariables(symbol, pairIndex);
            pips = 0;
            buyLoser = 0; 
            sellLoser = 0;
            continue;
         }//if (TradeWasClosed)
   
         //Profitable trade management
         if (OrderProfit() > 0) 
         {
            tradeManagementModule(OrderTicket() );
         }//if (OrderProfit() > 0) 
         
         //Scale out stop loss
         if (UseScaleOutStopLoss)
            if (scaleOutStopLoss(OrderTicket()) )
            {
               cc = OrdersTotal();//Restart the loop as the position has changed
               initialiseVariables(symbol, pairIndex);
               pips = 0;
               buyLoser = 0; 
               sellLoser = 0;
               continue;
            }//if (scaleOutStopLoss(OrderTicket()) )
         
      }//if (OrderType() < 2)
                
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)

   //Are we in Recovery?
   if (UseRecovery)
   {
      if (marketBuysCount >= TradesToStartLookingForRecovery)//Minimum trades to constitute Recovery
         if (buyLoser >= MinimumLosersToTriggerRecovery)//Minimum must be losers or we do not need Recovery
            buysInRecovery = true;
            
      if (marketSellsCount >= TradesToStartLookingForRecovery)//Minimum trades to constitute Recovery
         if (sellLoser >= MinimumLosersToTriggerRecovery)//Minimum must be losers or we do not need Recovery
            sellsInRecovery = true;
            
   }//if (UseRecovery[index] )

   //There are global variables holding the hidden tpsl. Delete them if the orders are no longer open
   //if (UseScaleBackIn)
   if (HideStopLossAndTakeProfit)
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
      
   //Earlier code intended to delete stop orders following
   //an opposite direction cross is not working. Call a function
   //to correct this.
   if (marketBuysCount > 0)
      if (sellStopOpen)
         sortOutTheMess(symbol);
         
   if (marketSellsCount > 0)
      if (buyStopOpen)
         sortOutTheMess(symbol);
         
   if (buyStopOpen)
      if (sellStopOpen)
         sortOutTheMess(symbol);
         
   //Delete the globals if no longer needed
   if (openTrades == 0)
   {
      string name = symbol + lotSizeGvName;
      if (GlobalVariableCheck(name) )
         GlobalVariableDel(name);
      name = symbol + stopLossGvName;
      if (GlobalVariableCheck(name) )
         GlobalVariableDel(name);
      name = symbol + takeProfitGvName;
      if (GlobalVariableCheck(name) )
         GlobalVariableDel(name);
   }//if (openTrades == 0)
            
      
}//End void countOpenTrades();
//+------------------------------------------------------------------+


bool scaleOutStopLoss(int ticket)
{

   /*
   Called from countOpenTrades()
   
   This function examines an open trade to see if the phased stop loss should be used.
   Returns 'true' if there is a part-closure, else false.
   
   This cannot be applied to hedged trades.
   */
   
   //Check the order is still open
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return(false);
   
   //Save stuff for easier typing
   int type = OrderType();
   string symbol = OrderSymbol();
   double price = OrderOpenPrice();
   //For scaling back in
   double take = OrderTakeProfit();
   double stop = OrderStopLoss();
   
   
   getBasics(symbol);
   
   
   //Nothing to do if the order is in pips profit
   if (type == OP_BUY)
      if (bid > price)
         return(false);
   
   if (type == OP_SELL)
      if (ask < price)
         return(false);  
         
   
   //Replace a missing Global in case something went wrong.
   //This is not perfect, but better than nothing.
   string name = symbol + lotSizeGvName;
   if (!GlobalVariableCheck(name) )
      GlobalVariableSet(name, OrderLots() );
      
      
   //Read the original order size. This was stored when the order was sent.
   double originalLot = GlobalVariableGet(name);
   
   //The trade is losing, so we need to know by how many pips
   double lossPips = 0;      
   if (type == OP_BUY)
      lossPips = (price - bid) * factor;
   else
      lossPips = (ask - price) * factor;  
   
   //Calculate the number of levels the price has dropped by.
   int levels = (int) (lossPips / DistanceBetweenLevels);   
//Alert(symbol, "  ", DoubleToStr(lossPips, 2), "  ", levels);

   //Not losing by a big enough margin to call for part-closure?
   if (levels < 1)
     return(false);
     
   //Calculate the lot size to close if necessary.
   double closeLots = normalizeLots(symbol, (originalLot * PercentToClose) / 100);   

   bool closeNeeded = false;
   
   //The existing lot size should be originalLot - (closeLots * levels)
   double remainLots = originalLot - (closeLots * levels);
   //Is this bigger than it should be?
   if (OrderLots() > remainLots)
   {
      closeNeeded = true;
   }//if (OrderLots() > remainLots)
   
   
   
   //Close part of the order
   if (closeNeeded)
   {
      bool result = OrderClose(ticket, closeLots, OrderClosePrice(), 0, clrNONE);
      if (result)
      {
         //Scaling back in
         if (UseScaleBackIn)
         {
            int tries = 0;
            bool success = false;
            while (!success)
            {
               if (type == OP_BUY)
                  success = sendSingleTrade(symbol, OP_BUYSTOP, ScaleBackInTradeComment, closeLots, price, stop, take);
               else   
                  success = sendSingleTrade(symbol, OP_SELLSTOP, ScaleBackInTradeComment, closeLots, price, stop, take);
               if (!success)
               {
                  tries++;
                  if (tries >= 100)//something has gone wrong
                     return(true);
                  Sleep(1000);                  
               }//if (! success)
               
            }//while (!success)
            
         }//if (UseScaleBackIn)
         
      }//if (result)
      
   }//if (closeNeeded)
   



   //Got here, so no closure
   return(false);

}//End bool scaleOutStopLoss(int ticket)

void sortOutTheMess(string symbol)
{

   //Earlier code intended to delete stop orders following
   //an opposite direction cross is not working. This function is
   //an attempt to sort out the mess. Nothing else has bloody well worked.
   
   deletePendings = true;
   
   double val = getMa(symbol, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 0);
   
   getBasics(symbol);
   
   if (bid > val)
   {
      closeAllTrades(symbol, OP_SELL);
      closeAllTrades(symbol, OP_SELLSTOP);
   }//if (bid > val)
   
   if (bid < val)
   {
      closeAllTrades(symbol, OP_BUY);
      closeAllTrades(symbol, OP_BUYSTOP);
   }//if (bid < val)
   
   
   deletePendings = false;

}//void sortOutTheMess(string symbol)


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
   
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (OrderStopLoss() > 0) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double stop = 0;
   
   if (OrderType() == OP_BUY)
   {
      stop = calculateStopLoss(OrderSymbol(), OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      stop = calculateStopLoss(OrderSymbol(), OP_SELL, OrderOpenPrice());
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
   
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (!closeEnough(OrderTakeProfit(), 0) ) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double take = 0;
   
   if (OrderType() == OP_BUY)
   {
      take = calculateTakeProfit(OrderSymbol(), OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      take = calculateTakeProfit(OrderSymbol(), OP_SELL, OrderOpenPrice());
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

bool lookForTradeClosure(int ticket, int pairIndex)
{
   //Close the trade if the close conditions are met.
   //Called from within countOpenTrades(). Returns true if a close is needed and succeeds, so that COT can increment cc,
   //else returns false
 
 
   if (!betterOrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (betterOrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   bool CloseThisTrade = false;
   
   double take = OrderTakeProfit();
   double stop = OrderStopLoss();
   
   //Hidden tpsl
   if (HideStopLossAndTakeProfit)
   {
      string symbol = OrderSymbol();
      int type = OrderType();
      double price = OrderOpenPrice();
      //Stored tp
      if (GlobalVariableCheck(symbol + takeProfitGvName) )
         take = GlobalVariableGet(symbol + takeProfitGvName);
      else   
         take = calculateTakeProfit(symbol, type, price);
      
      //Stored sl
      if (GlobalVariableCheck(symbol + stopLossGvName) )
         stop = GlobalVariableGet(symbol + stopLossGvName);
      else   
         stop = calculateStopLoss(symbol, type, price);
   }//if (HideStopLossAndTakeProfit)

   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
   {
      //TP
      if (bid >= take && !closeEnough(take, 0) && !closeEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
      //SL
      if (bid <= stop && !closeEnough(stop, 0)  && !closeEnough(stop, OrderStopLoss())) CloseThisTrade = true;
 
               
   }//if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
   {
      //TP
      if (bid <= take && !closeEnough(take, 0) && !closeEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
      //SL
      if (bid >= stop && !closeEnough(stop, 0)  && !closeEnough(stop, OrderStopLoss())) CloseThisTrade = true;
 
   }//if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (CloseThisTrade)
   {
      bool result = false;
     
      if (OrderType() < 2)//Market orders
         result = closeOrder(ticket);
      else
         result = OrderDelete(ticket, clrNONE);
           
      //Actions when trade close succeeds
      if (result)
      {
         ticketNo = -1;//ticketNo is the most recently trade opened, so this might need editing in a multi-trade EA
         openTrades--;//Rather than openTrades = 0 to cater for multi-trade EA's
         return(true);//Makes countOpenTrades increment cc to avoid missing out ccounting a trade
      }//if (result)
   
      //Actions when trade close fails
      if (!result)
      {
         return(false);//Do not increment cc
      }//if (!result)
   }//if (CloseThisTrade)
   
   //Got this far, so no trade closure
   return(false);//Do not increment cc
   
}//End bool lookForTradeClosure()

double calculateStopLoss(string symbol, int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop = 0, atrVal = 0;

   getBasics(symbol);
   
   double maval = 0;
   
   if (type == OP_BUY)
   {
      if (!closeEnough(stopLoss, 0) ) 
      {
         stop = price - (stopLoss / factor);
         //HiddenStopLoss = stop;
      }//if (!closeEnough(stopLoss, 0) ) 

      //SL on the other side of the moving average
      if (!closeEnough(oppositeSideStopLoss, 0))
      {
         maval = getMa(symbol, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 0);
         stop = maval - (oppositeSideStopLoss / factor);
      }//if (!closeEnough(oppositeSideStopLoss, 0))
      

      //ATR sl
      if (UseAtrForStopLoss)
      {
         atrVal = getAtr(symbol, AtrSlTimeFrame, AtrSlPeriod, 0);
         atrVal = NormalizeDouble((atrVal * AtrSlMultiplier), digits );
         stop = NormalizeDouble((price - atrVal), digits);
      }//if (UseAtrForStopLoss)

      //if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop - (HiddenPips / factor), Digits);
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!closeEnough(stopLoss, 0) ) 
      {
         stop = price + (stopLoss / factor);
         //HiddenStopLoss = stop;         
      }//if (!closeEnough(stopLoss, 0) ) 


      //SL on the other side of the moving average
      if (!closeEnough(oppositeSideStopLoss, 0))
      {
         maval = getMa(symbol, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 0);
         stop = maval + (oppositeSideStopLoss / factor);
      }//if (!closeEnough(oppositeSideStopLoss, 0))
      
      
      //ATR sl
      if (UseAtrForStopLoss)
      {
         atrVal = getAtr(symbol, AtrSlTimeFrame, AtrSlPeriod, 0);
         atrVal = NormalizeDouble((atrVal * AtrSlMultiplier), digits );
         stop = NormalizeDouble((price + atrVal), digits);
      }//if (UseAtrForStopLoss)

      //if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop + (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   //Store the sl
   GlobalVariableSet(stopLossGvName, stop);

   return(stop);
   
}//End double calculateStopLoss(int type)

double calculateTakeProfit(string symbol, int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double take = 0, atrVal=0;;

   getBasics(symbol);
   
   
   if (type == OP_BUY)
   {
      if (!closeEnough(takeProfit, 0) )
      {
         take = price + (takeProfit / factor);
         //HiddenTakeProfit = take;
      }//if (!closeEnough(takeProfit, 0) )

      //ATR tp
      if (UseAtrForTakeProfit)
      {
         atrVal = getAtr(symbol, AtrTpTimeFrame, AtrTpPeriod, 0);
         atrVal = NormalizeDouble((atrVal * AtrTpMultiplier), digits );
         take = NormalizeDouble((price + atrVal), digits);
      }//if (UseAtrForTakeProfit)
      
               
      //if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take + (HiddenPips / factor), Digits);

   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!closeEnough(takeProfit, 0) )
      {
         take = price - (takeProfit / factor);
         //HiddenTakeProfit = take;         
      }//if (!closeEnough(takeProfit, 0) )
      
      if (UseAtrForTakeProfit)
      {
         atrVal = getAtr(symbol, AtrTpTimeFrame, AtrTpPeriod, 0);
         atrVal = NormalizeDouble((atrVal * AtrTpMultiplier), digits );
         take = NormalizeDouble((price - atrVal), digits);
      }//if (UseAtrForTakeProfit)
      
      
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
         if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
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
            if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy  
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
             NewStop = NormalizeDouble(sl + (trailingStopPips / factor), digits);
             if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
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
             NewStop = NormalizeDouble(sl - (trailingStopPips / factor), digits);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
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

void minimiseAllCharts()
{

   long chartID = ChartFirst();
   
   while( chartID >= 0 ) {
      if ( !chartMinimize( chartID ) ) {
      
         PrintFormat("Couldn't minimize %I64d (Symbol: %s, Timeframe: %s)", chartID, ChartSymbol(chartID), EnumToString(ChartPeriod(chartID)) );
         //break;
      }
      chartID = ChartNext( chartID );
   }


}//void minimiseAllCharts()


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
//| Chart Event function. Code courtesy of Thomas.                   |
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
         
         pair = StringConcatenate(PairPrefix, pair, PairSuffix);//Code added by biobier. Thanks Alex.
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

      /*else if(StringFind(sparam,"OAM-MINIMISE")>=0)
      {
         ObjectSetInteger(0,sparam,OBJPROP_STATE,0);
         
         shrinkCharts();
         return;
      }
      */

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

   
   double take = 0, stop = 0, price = 0;
   int type = 0;
   bool SendTrade = false, result = false;

   double sendLots = Lot;
   

   //Check filters
   if (!isTradingAllowed(symbol, pairIndex) ) return;
   getBasics(symbol);

   
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
       
      //Single trading
      if (UseSingleTradingMethod)
      {
         type=OP_BUY;
         price = NormalizeDouble(MarketInfo(symbol, MODE_ASK), digits);
         
         if (TypeOfOrder == StopOrder)
         {
            type = OP_BUYSTOP;
            price = NormalizeDouble(price + (stopOrderDistance / factor), digits );
         }//if (TypeOfOrder == StopOrder)
         
         stop = calculateStopLoss(symbol, OP_BUY, price);
            
            
         take = calculateTakeProfit(symbol, OP_BUY, price);
         
      }//if (UseSingleTradingMethodr)
      
      //Grid trading
      if (UseGridTradingMethod)
      {
         //Immediate market order
         type = OP_BUY;
         price = NormalizeDouble(MarketInfo(symbol, MODE_ASK), digits);
         
         //Stop order only
         if (!SendImmediateMarketTrade)
         {
            type = OP_BUYSTOP;
            price = NormalizeDouble(price + (pendingDistanceToFirstTrade / factor), digits );
         }//if (!SendImmediateMarketTrade)
         
         stop = calculateStopLoss(symbol, OP_BUY, price);
            
         take = calculateTakeProfit(symbol, OP_BUY, price);
      }//if (UseGridTradingMethod)
      
      
      //Lot size calculated by risk
      if (!closeEnough(RiskPercent, 0)) sendLots = calculateLotSize(symbol, price, stop );

               
      SendTrade = true;
      
   }//if (SendLong)
   
   //Short
   if (SendShort)
   {
      
      if (UseSingleTradingMethod)
      {
         //Immediate market order
         type=OP_SELL;
         price = NormalizeDouble(MarketInfo(symbol, MODE_BID), digits);
   
         if (TypeOfOrder == StopOrder)
         {
            type = OP_SELLSTOP;
            price = NormalizeDouble(price - (stopOrderDistance / factor), digits );
         }//if (TypeOfOrder == StopOrder)

         stop = calculateStopLoss(symbol, OP_SELL, price);
            
         take = calculateTakeProfit(symbol, OP_SELL, price);
         
      }//if (UseSingleTradingMethod)

      //Grid trading
      if (UseGridTradingMethod)
      {
         //Immediate market order
         type = OP_SELL;
         price = NormalizeDouble(MarketInfo(symbol, MODE_BID), digits);
         
         //Stop order only
         if (!SendImmediateMarketTrade)
         {
            type = OP_SELLSTOP;
            price = NormalizeDouble(price - (pendingDistanceToFirstTrade / factor), digits );
         }//if (!SendImmediateMarketTrade)
         
         stop = calculateStopLoss(symbol, OP_SELL, price);
            
         take = calculateTakeProfit(symbol, OP_SELL, price);
      }//if (UseGridTradingMethod)
      
      //Lot size calculated by risk
      if (!closeEnough(RiskPercent, 0)) sendLots = calculateLotSize(symbol, price, stop);

      
         
      SendTrade = true;      
   
      
   }//if (SendShort)
   

   if (SendTrade)
   {
      string name = "";
      
      //Single trading method
      if (UseSingleTradingMethod)
      {
         //The tp and sl calculation functions store the tpsl in global variables,
         //so cancel sending these with the order.
         if (HideStopLossAndTakeProfit)
         {
            take = 0;
            stop = 0;
         }//if (HideStopLossAndTakeProfit)
         
         result = sendSingleTrade(symbol, type, TradeComment, sendLots, price, stop, take);
      
         if (result)
         {
            //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so tell the
            //ea not to trade for a while, to give time for the trade receipt to return from the server.
            timeToStartTrading[pairIndex] = TimeCurrent() + PostTradeAttemptWaitSeconds;
            //Prevent multiple trades
            buySignal[pairIndex] = false;
            sellSignal[pairIndex] = false;
            
            name = symbol + lotSizeGvName;
            //Save the order size for scaling out
            GlobalVariableSet(name, sendLots);
            //Also sltp for hidden stops
            name = symbol + stopLossGvName;
            GlobalVariableSet(name, stop);
            name = symbol + takeProfitGvName;
            GlobalVariableSet(name, take);
                 
            if (betterOrderSelect(ticketNo, SELECT_BY_TICKET, MODE_TRADES) )
               checkTpSlAreCorrect(type);
            
         
         }//if (result)    
         
         //Force a rety on the next tick if the order send failed
         if (!result)
         {
            timeToStartTrading[pairIndex] = 0;
         }//if (!result)
               
      }//if (UseSingleTradingMethod)
      
      
      //Grid trading method
      if (UseGridTradingMethod)
      {
         if (GridSize > 0)
         {
            if (buySignal[pairIndex])
               type = OP_BUYSTOP;
            else
               type = OP_SELLSTOP;   
               
            if (SendImmediateMarketTrade)
            {
               if (type == OP_BUYSTOP)
                  result = sendSingleTrade(symbol, OP_BUY, TradeComment, sendLots, price, stop, take);
               else
                  result = sendSingleTrade(symbol, OP_SELL, TradeComment, sendLots, price, stop, take);
            }//if (SendImmediateMarketTrade)
            
            if (!SendImmediateMarketTrade)
            {
               if (type == OP_BUYSTOP)
                  result = sendSingleTrade(symbol, OP_BUYSTOP, TradeComment, sendLots, price, stop, take);
               else
                  result = sendSingleTrade(symbol, OP_SELLSTOP, TradeComment, sendLots, price, stop, take);
            }//if (SendImmediateMarketTrade)
            
               
            if (result)
            {
               //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so tell the
               //ea not to trade for a while, to give time for the trade receipt to return from the server.
               timeToStartTrading[pairIndex] = TimeCurrent() + PostTradeAttemptWaitSeconds;
               //Prevent multiple trades
               buySignal[pairIndex] = false;
               sellSignal[pairIndex] = false;
               
                    
               if (betterOrderSelect(ticketNo, SELECT_BY_TICKET, MODE_TRADES) )
                  checkTpSlAreCorrect(type);

               //Save the order size for scaling out
               name = symbol + lotSizeGvName;
               //Save the order size for scaling out
               GlobalVariableSet(name, sendLots);
               //Also sltp for hidden stops
               name = symbol + stopLossGvName;
               GlobalVariableSet(name, stop);
               name = symbol + takeProfitGvName;
               GlobalVariableSet(name, take);
               
         
               
            }//if (result)    
            
            //Force a rety on the next tick if the order send failed
            if (!result)
            {
               timeToStartTrading[pairIndex] = 0;
            }//if (!result)
               
               
            
            //Send the grid
            getBasics(symbol);
            if (type == OP_BUYSTOP)
               sendBuyGrid(symbol, OP_BUYSTOP, price, sendLots, TradeComment);
            else
               sendSellGrid(symbol, OP_SELLSTOP, price, sendLots, TradeComment);
               
         }//if (GridSize > 0)

      }//if (UseGridTradingMethod)
         
      
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

   //Max trades allowed by broker check.
   if (!checkBrokerMaxTradesOnPlatform(GridSize) )
      return;


   //Send a grid of stop orders using the passed parameters
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
   
   int tries=0;//To break out of an infinite loop

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
         cc--;
         continue;
      }//if (doesTradeExist(OP_BUYSTOP, price))

      //In case the global variable read failed
      if (closeEnough(stop, 0) )
         stop = calculateStopLoss(symbol, OP_BUY, price);
      
      //In case the global variable read failed,
      //but only if not hidden.
      if (!HideStopLossAndTakeProfit)
         if (closeEnough(take, 0) )
         {
            if (!UseNextLevelForTP)
               take = calculateTakeProfit(symbol, OP_BUY, price);
            if (UseNextLevelForTP)//Set the tp at the open price of the next trade
               take = NormalizeDouble(price + (distanceBetweenTrades/factor), digits);
         }//if (closeEnough(take, 0) )
               
         

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


   //Max trades allowed by broker check.
   if (!checkBrokerMaxTradesOnPlatform(GridSize) )
      return;


   //Send a grid of stop orders using the passed parameters
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
   price = NormalizeDouble(price - (distanceBetweenTrades / factor), digits);
   //price = NormalizeDouble(bid - (distanceBetweenTrades / factor), digits);
   
   int tries=0;//To break out of an infinite loop

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
         cc--;

         continue;
      }//if (doesTradeExist(OP_SELLSTOP, price))

      //In case the global variable read failed
      if (closeEnough(stop, 0) )
         stop = calculateStopLoss(symbol, OP_SELL, price);
      
      //In case the global variable read failed,
      //but only if not hidden.
      if (!HideStopLossAndTakeProfit)
         if (closeEnough(take, 0) )
         {
            if (!UseNextLevelForTP)
               take = calculateTakeProfit(symbol, OP_SELL, price);
            if (UseNextLevelForTP)//Set the tp at the open price of the next trade
               take = NormalizeDouble(price - (distanceBetweenTrades/factor), digits);
         }//if (closeEnough(take, 0) )
            

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
            stop = calculateStopLoss(OrderSymbol(), OP_BUY, OrderOpenPrice());
         }//if (!closeEnough(diff, stopLoss) )          
      }//if (!closeEnough(OrderStopLoss(), 0) )      

      if (!closeEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderTakeProfit() - OrderOpenPrice()) * factor;
         if (!closeEnough(diff, takeProfit) ) 
         {
            ModifyTake = true;
            take = calculateTakeProfit(OrderSymbol(), OP_BUY, OrderOpenPrice());
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
            stop = calculateStopLoss(OrderSymbol(), OP_SELL, OrderOpenPrice());

         }//if (!closeEnough(diff, stopLoss) )          
      }//if (!closeEnough(OrderStopLoss(), 0) )      

      if (!closeEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderOpenPrice() - OrderTakeProfit() ) * factor;
         if (!closeEnough(diff, takeProfit) ) 
         {
            ModifyTake = true;
            take = calculateTakeProfit(OrderSymbol(), OP_SELL, OrderOpenPrice());
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
         if (type != AllTrades)
         {
            if (type == OP_BUY)
               if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
                  continue;
            
            if (type == OP_SELL)
               if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
                  continue;
         
         }//if (type != AllTrades)
         
         
         //if (OrderType() != type) 
         //   if (type != AllTrades)
         //      continue;
         
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
      if (type != AllTrades)
      {
            if (type == OP_BUY)
               if (OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP)
                  continue;
            
            if (type == OP_SELL)
               if (OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP)
                  continue;
      
      }//if (type != AllTrades)
         
      
      //if (OrderType() != type) 
         //if (type != AllTrades)
           // continue;
      
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

bool isPairAlreadyCounted(string symbol)
{

   if (ArraySize(pairsTraded) == 0)
      return(false);

   for (int cc = ArraySize(pairsTraded) - 1; cc >= 0; cc--)
   {
      if (symbol == pairsTraded[cc] )
         return(true);
   }//for (int cc = ArraySize(pairsTraded) - 1; cc >= 0; cc--)
   

   //Pair not counted yet
   return(false);
   
}//End bool isPairAlreadyCounted(string symbol)



bool maxPairsCheck()
{

   //Returns false if the max pairs have been reahed, else returns true
   
   if (MaxPairsAllowed == 0)//Zero input turns this filter off
      return(true);

   if (OrdersTotal() == 0)
      return(true);
      
   int index =0;
   ArrayResize(pairsTraded, 0);
      
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!isPairAlreadyCounted(OrderSymbol() ))
      {
         ArrayResize(pairsTraded, index + 1);
         pairsTraded[index] = OrderSymbol();
         index++;
         if (index > MaxPairsAllowed)
            return(false);
      }//if (!isPairAlreadyCounted(OrderSymbol() ))
    
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
      

   //Got this far, so OK to trade
   return(true);

}//End bool maxPairsCheck()

bool isTradingAllowed(string symbol, int pairIndex)
{
   //Returns false if any of the filters should cancel trading, else returns true to allow trading.

   //Max trades allowed by broker check.
   if (!checkBrokerMaxTradesOnPlatform(1) )
      return(false);
   
   //Max pairs allowed
   if (!maxPairsCheck() )
      return(false);
   
   getBasics(symbol);
   
   if (buySignal[pairIndex] )
   {
      //Min distance between trades check.
      //Not used yet but leave in place for possible use later.
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

   //Pips target
   if (IndividualBasketTargetPips > 0)
      if (pipsUpl[pairIndex] >= IndividualBasketTargetPips)
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
            //Store the D1 candle open time for stop trading for the day after a basket closure
            if (KnockOffForDayAfterClosure)
               GlobalVariableSet(basketClosureTimeGV, iTime(Symbol(), PERIOD_D1, 0) );
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
            //Store the D1 candle open time for stop trading for the day after a basket closure
            if (KnockOffForDayAfterClosure)
               GlobalVariableSet(basketClosureTimeGV, iTime(Symbol(), PERIOD_D1, 0) );
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
         //Store the D1 candle open time for stop trading for the day after a basket closure
         if (KnockOffForDayAfterClosure)
            GlobalVariableSet(basketClosureTimeGV, iTime(Symbol(), PERIOD_D1, 0) );
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
         //Store the D1 candle open time for stop trading for the day after a basket closure
         if (KnockOffForDayAfterClosure)
            GlobalVariableSet(basketClosureTimeGV, iTime(Symbol(), PERIOD_D1, 0) );
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
   
   
   //Rolling grid.
   if (RollingGrid)//Are we using this feature?
      if (isTradingAllowed(symbol, pairIndex) )//Make sure there is nothing to stop us trading eg spread
         if (marketTradesTotal > 0)//There are open trades
            if (marketTradesTotal + GridSize <= (MaxRolledTrades - GridSize) )//A new grid will not exceed our maximum allowed
            {   
               //Buy grid
               if (buyOpen)//There are market buy trades 
                  if (buyStopsCount == 0)
                  {
                     sendBuyGrid(symbol, OP_BUYSTOP, ask, Lot, TradeComment); 
                  }//if (buyStopsCount == 0)
               
               //Sell grid
               if (sellOpen)//There are market sell trades
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
               closeAllTrades(symbol, OP_BUY);
               if (forceTradeClosure)//In case a trade close/delete failed
               {
                  closeAllTrades(symbol, OP_BUY);
                  if (forceTradeClosure)
                  {
                     closeAllTrades(symbol, OP_BUY);
                     if (forceTradeClosure)
                     {
                        closeAllTrades(symbol, OP_BUY);
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
               closeAllTrades(symbol, OP_SELL);
               if (forceTradeClosure)//In case a trade close/delete failed
               {
                  closeAllTrades(symbol, OP_SELL);
                  if (forceTradeClosure)
                  {
                     closeAllTrades(symbol, OP_SELL);
                     if (forceTradeClosure)
                     {
                        closeAllTrades(symbol, OP_SELL);
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

void autoTrading()
{
   //Think of this being the equivalent to OnTimer() in a multi-pair
   //EA without the dashboard element.


   //Trading done for the week stuff.
   //This allows doneForTheWeek to reset to 'false' if the bot was left running over the weekend.
   if (GlobalVariableCheck(DoneForTheWeekGV))//Is there a GV?
   {
      //Extract the time.
      datetime WeekStartTime = (datetime) GlobalVariableGet(DoneForTheWeekGV);

      //Is it a previous week?
      if (WeekStartTime < iTime(Symbol(), PERIOD_W1, 0) )
      {
         doneForTheWeek = false;//Reset the bool
         GlobalVariableDel(DoneForTheWeekGV);//Delete the GV
      }//if (WeekStartTime < iTime(Symbol(), PERIOD_W1, 0) )
      
   }//if (GlobalVariableCheck(DoneForTheWeekGV))
   else
      doneForTheWeek = false;
      
   //No need to go any further if we have reached our weekly profit target.
   if (doneForTheWeek)
      return;

   //In case an entire basket closure failure happened
   if (forceWholePositionClosure)
   {
      closeAllTrades(AllSymbols, AllTrades);
      if (forceWholePositionClosure)
      {
         closeAllTrades(AllSymbols, AllTrades);
         if (forceWholePositionClosure)
         {
            return;//Still failed, so try again at the next timer event
         }//if (forceWholePositionClosure)                     
      }//if (forceWholePositionClosure)  
      forceWholePositionClosure = false;//Closure succeeded       
   }//if (forceWholePositionClosure)    
   
   //Has a basket closure suspended trading for the day?
   if (KnockOffForDayAfterClosure)
   {
      if (GlobalVariableCheck(basketClosureTimeGV) )
      {
         datetime openTime = (int) GlobalVariableGet(basketClosureTimeGV);
         if (openTime == iTime(Symbol(), PERIOD_D1, 0) )
         {
            tradingSuspendedAfterBasketClosure = true;//For chart feedback
            return;//Not a new trading day
         }//if (openTime == iTime(Symbol(), PERIOD_D1, 0) )
         else
         {
            tradingSuspendedAfterBasketClosure = false;
            GlobalVariableDel(basketClosureTimeGV);
         }//else
      }//if (GlobalVariableCheck(basketClosureTimeGV) )
   }//if (KnockOffForDayAfterClosure)
   
   
   //Some variables to use in case order closures fail
   bool forceBuyClosure = false, forceSellClosure = false;

   
      
   //Calculate a dynamic whole basket TP for initial display
   if (UseDynamicCashTP)
   {
      //Applied to a fixed lot size
      if (closeEnough(LotsPerDollopOfCash, 0))
         if (closeEnough(RiskPercent, 0))
            calculateDynamicBasketCashTP(Lot);
   
      //LotsPerDollop
      if (!closeEnough(LotsPerDollopOfCash, 0))
      {
         calculateLotAsAmountPerCashDollops();
         calculateDynamicBasketCashTP(Lot);
      }//if (!closeEnough(LotsPerDollopOfCash, 0))
         
      //RiskPercent   
      if (!closeEnough(RiskPercent, 0))
      {
         //Simulate a trade to calculate the lot size for a RiskPercent-based trade.
         double stop = 0, price = 0;
         string symbol = tradePair[0];
         price = MarketInfo(symbol, MODE_ASK);
         stop = calculateStopLoss(symbol, OP_BUY, price);
         double sendLots = calculateLotSize(symbol, price, stop);
      
         calculateDynamicBasketCashTP(sendLots);
      
      }//if (!closeEnough(RiskPercent, 0))
      
      
   }//if (UseDynamicCashTP)
   
   //This code added by John (SHF 1of3)
   if(StringLen(BasketFridayCashTargets) > 0 || StringLen(BasketFridayPipsTargets) > 0)
     setFridayBasketTP();   

   //Spread calculation for dashboard
   for (int pairIndex = 0; pairIndex < ArraySize(tradePair); pairIndex++)
   {
      getBasics(tradePair[pairIndex]);
      runningSpreadCalculation(tradePair[pairIndex], pairIndex);
   }//for (int pairIndex = 0; pairIndex < ArraySize(tradePair); pairIndex++)

   //mptm and my order closure scripts sets a Global Variable when it is closing the trades.
   //This tells this ea not to send any fresh trades.
   if (GlobalVariableCheck(gvName))
      return;
   //'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(localGvName))
      return;
   //'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(nuclearGvName))
      return;
      
   bool result = false;   

   countTotalsForDisplay();
   //Protect the account when the margin level drops below our comfort zone.
   if (shirtProtection() )
   {
      deletePendings = true;
      //In case an order close/delete failed
      if (forceWholePositionClosure)
         return;
         
      //Closure/deletion succeeded
      countTotalsForDisplay();
      displayUserFeedback();
      return;   
   }//if (ShirtProtection() )
   
     
   
   
   //Trading done for the week stuff
   //Set doneForTheWeek if we have reached our weekly target
   if (UseTradingDoneForTheWeek)
   {
      haveWeDoneForTheWeek();
      if (doneForTheWeek)
         return;
   }//if (UseTradingDoneForTheWeek)
      
   //Has the position reached its entire basket profit target
   if (TreatAllPairsAsBasket)
   {
      deletePendings = true;
      if (LeaveAllPairsBasketPendingsOpen)
         deletePendings = false;
         
      if (canEntirePositionClose() )
         return;//Start again at next timer event
      
      if (forceTradeClosure)
      {
         closeAllTrades(AllSymbols, AllTrades);
         if (forceTradeClosure)
         {
            closeAllTrades(AllSymbols, AllTrades);
            if (forceTradeClosure)
            {
               forceWholePositionClosure = true;
               return;//Still failed, so try again at the next timer event
            }//if (forceTradeClosure)                     
         }//if (forceTradeClosure)         
      }//if (forceTradeClosure)    
         
   
   }//if (TreatAllPairsAsBasket)
   
   //Can we shut down for the weekend
   if (totalOpenTrades > 0)
      shutDownForTheWeekend();
      
   
   
   //Rollover
   if (DisableEaDuringRollover)
   {
      rolloverInProgress = false;
      if (areWeAtRollover())
      {
         rolloverInProgress = true;
         return;
      }//if (AreWeAtRollover)
   }//if (DisableEaDuringRollover)
      
   //Trading times
   tradeTimeOk = checkTradingTimes();
   if(!tradeTimeOk)
   {
      displayUserFeedback();
      Sleep(1000);
      return;
   }//if (!tradeTimeOk)

   //Sunday trading, Monday start time, Friday stop time, Thursday trading
   tradeTimeOk = sundayMondayFridayStuff();
   if (!tradeTimeOk)
   {
      displayUserFeedback();
      return;
   }//if (!tradeTimeOk)

   for (int pairIndex = 0; pairIndex < ArraySize(tradePair); pairIndex++)
   {
      string symbol = tradePair[pairIndex];
      getBasics(symbol);
      
      //Opposite direction closure. The if (forceTradeClosure) code block will take care of closure failure.
      if (buyCloseSignal[pairIndex])
      {
         closeAllTrades(symbol, OP_BUY);
         if (!forceTradeClosure)//Cancel the signal as it is no longer needed
            buyCloseSignal[pairIndex] = false;
      }//if (buyCloseSignal[pairIndex])
      
      if (sellCloseSignal[pairIndex])
      {
         closeAllTrades(symbol, OP_SELL);
         if (!forceTradeClosure)//Cancel the signal as it is no longer needed
            sellCloseSignal[pairIndex] = false;
      }//if (sellCloseSignal[pairIndex])
      
         
         

      //In case an individual basket closure failed. pairIndex has been
      //adjusted, so try again. Also adapted for Recovery closure failure
      if (forceTradeClosure)
      {
         closeAllTrades(symbol, AllTrades);
         if (forceTradeClosure)
         {
            if (forceBuyClosure)
               closeAllTrades(symbol, OP_BUY);
            else   
            if (forceSellClosure)
               closeAllTrades(symbol, OP_SELL);
            else
               closeAllTrades(symbol, AllTrades);
            if (forceTradeClosure)
            {
               pairIndex--;
               continue;
            }//if (forceTradeClosure)                     
         }//if (forceTradeClosure)         
      }//if (forceTradeClosure)      
      
      //For the swap filter. It will set these variable to false if the swap filter fails.
      //The variables are left behind from the conversion of the single pair trading EA
      //to the multi-pair one. This seems to me to be the easiest way of dealing with the problem
      //that the filter causes of not resetting here.
      tradeLong = true;
      tradeShort = true;
      
      
      //Average spread
      runningSpreadCalculation(symbol, pairIndex);
      //Is spread ok to allow actions on this pair
      if (!spreadCheck(pairIndex) )
         continue;

      countOpenTrades(symbol, pairIndex);
      
      //Deal with opposite direction cross closure
      if (buySignal[pairIndex])
      {
         if (sellOpen || sellStopOpen || sellLimitOpen)
         {
            closeAllTrades(symbol, AllTrades);
            if (forceTradeClosure)
            {
               pairIndex--;
               continue;
            }//if (forceTradeClosure)
         }//if (sellOpen || sellStopOpen || sellLimitOpen)
      }//if (buySignal[pairIndex])
      
      if (sellSignal[pairIndex])
      {
         if (buyOpen || buyStopOpen || buyLimitOpen)
         {
            closeAllTrades(symbol, AllTrades);
            if (forceTradeClosure)
            {
               pairIndex--;
               continue;
            }//if (forceTradeClosure)
         }//if (buyOpen || buyStopOpen || buyLimitOpen)
      }//if (sellSignal[pairIndex])
      
      
      //Individual pair basket closure
      if (TreatIndividualPairsAsBasket)
      {
         deletePendings = true;
         if (LeaveIndividualBasketPendingsOpen)
            deletePendings = false;
         if (canIndividualPairBasketBeClosed(symbol, pairIndex) )
            continue;

         if (forceTradeClosure)
         {
            closeAllTrades(symbol, AllTrades);
            if (forceTradeClosure)
            {
               closeAllTrades(symbol, AllTrades);
               if (forceTradeClosure)
               {
                  pairIndex--;
                  continue;
               }//if (forceTradeClosure)                     
            }//if (forceTradeClosure)         
         }//if (forceTradeClosure)      

      }//if (TreatIndividualPairsAsBasket)
      
      //Check for hitting our Recovery target
      //Variables to use in case order closures fail
      forceBuyClosure = false;
      forceSellClosure = false;
      if (UseRecovery)
      {
         doRecoveryClosure(symbol, pairIndex);
         //Deal with order closure failures
         if (forceTradeClosure)
         {
            if (buysInRecovery)
               forceBuyClosure = true;
            if (sellsInRecovery)
               forceSellClosure = true;
            pairIndex--;
            continue;   
         }//if (forceTradeClosure)
         
      }//if (UseRecovery[tfIndex] )

      
      //Lot size based on account size
      if (!closeEnough(LotsPerDollopOfCash, 0))
         calculateLotAsAmountPerCashDollops();
      
      //Differential lot sizing
      if (UseDifferentialLotSizing)
         Lot = getDifferentialLotSize(symbol);

      
      
      //Deal with pending orders when the margin level drops below our minimum
      bool marginOK = marginCheck();
      if (!marginOK)
      {
         deletePendings = true;
         canPendingsBeDeleted();
         return;
      }//if (!marginOK)
      
      //Rolling grid
      if (RollingGrid)
      {
         doRollingGridStuff(symbol, pairIndex);
         if (CloseGridAtMrtPlusOneLevel)
         {
            doRollingGridClosure(symbol, pairIndex);
            if (forceTradeClosure)
            {
               pairIndex--;
               continue;
            }//if (forceTradeClosure)
            
         }//if (CloseGridAtMrtPlusOneLevel)
         
      }//if (RollingGrid)
      
           
      if (TimeCurrent() >= timeToStartTrading[pairIndex])
      {
         if (!StopTrading)              
         {
            if (marginOK)
            {
               lookForTradingOpportunities(symbol, pairIndex);
               timeToStartTrading[pairIndex] = 0;//Set to TimeCurrent() + (PostTradeAttemptWaitMinutes * 60) 
                                                 //when there is an OrderSend() attempt)
            }//if (marginOK)
         }//if (!StopTrading)
      }//if (TimeCurrent() >= timeToStartTrading[pairIndex])
   
   }//for (int pairIndex = 0; pairIndex < ArraySize(tradePair); pairIndex++)

}//void autoTrading()



//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

   updateTradeArrows();
   
   
   if (removeExpert)
   {
      ExpertRemove();
      return;
   }//if (removeExpert)
   
   //mptm sets a Global Variable when it is closing the trades.
   //This tells this ea not to send any fresh trades.
   if (GlobalVariableCheck(gvName))
      return;
   //'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(localGvName))
      return;
   //'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(nuclearGvName))
      return;

   if (!IsTradeAllowed() )
   {
      Comment("                          THIS EXPERT HAS LIVE TRADING DISABLED");
      return;
   }//if (!IsTradeAllowed() )
   
   
   timerCount++;
   if (timerCount>=ChartCloseTimerMultiple)//Now we have a chart closing cycle
      timerCount=0;



   readIndicatorValues();
   
   
   //Using the EA to trade
   if (AutoTradingEnabled)
      autoTrading();
   
   displayUserFeedback();
   
}
//+------------------------------------------------------------------+
