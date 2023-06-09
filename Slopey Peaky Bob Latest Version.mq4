//+------------------------------------------------------------------+
//|                                             Slopey Peaky Bob.mq4 |
//|                                                 Steve and Tomele |
//|                                https://www.stevehopwoodforex.com |
//+------------------------------------------------------------------+
#property copyright "Steve Hopwood"
#property link      "https://www.stevehopwoodforex.com"
#property strict
#define version "Version 2w"

#include <SPB core library.mqh>

extern string  cau="---- Chart automation ----";
//These inputs tell the ea to automate opening/closing of charts and
//what to load onto them
extern bool             AutomateChartOpeningAndClosing      =false;
extern bool             MinimiseChartsAfterOpening          =false;
extern string           ReservedPair                        ="XAUUSD";
extern string           TemplateName                        ="SPB";
extern string           tra                                 ="-- Trade arrows --";
extern bool             drawTradeArrows                     = true;
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
extern bool             WriteFileForTestDatabase=false;
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
string         tradingTimeFramedisplay="";
int            timerCount=0;//Count timer events for closing charts
bool           forceTradeClosure=false;
datetime       oldHtfIndiReadBarTime[];
datetime       oldMtfIndiReadBarTime[];
datetime       oldLtfIndiReadBarTime[];
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
extern int     TakeProfitPips=0;
extern int     StopLossPips=0;
extern bool    HideStopLossAndTakeProfit=false;
extern int     MagicNumber=0;
extern string  TradeComment="SPB";
extern bool    IsGlobalPrimeOrECNCriminal=false;
extern int     MaxSlippagePips=5;
extern string  PairPrefix="";
extern string  PairSuffix="";
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitSeconds seconds, whether OR detects a receipt return or not.
extern int     PostTradeAttemptWaitSeconds=60;
////////////////////////////////////////////////////////////////////////////////////////
datetime       timeToStartTrading[];//Re-start calling lookForTradingOpportunities() at this time.
double         takeProfit, stopLoss;
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

extern string  sep2v="================================================================";
extern string  psl="-- Scale out stop loss --";
extern bool    UseScaleOutStopLoss=false;
extern int     NoOfLevels=4;
extern bool    UseScaleBackIn=false;
extern string  ScaleBackInTradeComment="Scale in";

extern string  sep1="================================================================";
extern string  lsz="---- Lot sizing ----";
extern string  hls="-- 'Hard' lot sizing --";
extern double  Lot=0.01;
extern string  prc="-- Percentage based lot sizing --";
//Set RiskPercent to zero to disable and use Lot
extern double  RiskPercent=0;
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

extern string  sep1a="================================================================";
extern string  ssl="---- highest time frame Super Slope ----";
extern bool    UseHtfSs=true;
extern ENUM_TIMEFRAMES HtfSsTimeFrame=PERIOD_D1;
extern double  HtfSsDifferenceThreshold  = 1.0;
extern int     HtfSsSlopeMAPeriod        = 7; 
extern int     HtfSsSlopeATRPeriod       = 50; 
//Allow the user to select a candle shift
extern int     HtfSsBarShift=0;
//A couple of inputs to stop trading if SS does not indicate sufficient strength
extern double  HtfSsSlopeBuyAbove=1;
extern double  HtfSsSlopeSellBelow=-1;
extern string  Htfcch="-- Colour change --";
extern bool    HtfCloseMarketTradesOnOppositeSignal=false;
//HtfCloseMarketTradesOnOppositeSignal has to be enabled for the next two inputs to come into operation.
extern double  HtfCloseBuysBelow=-0.5;
extern double  HtfCloseSellsAbove=0.5;
extern bool    HtfDeletePendingTradesOnOppositeSignal=true;
////////////////////////////////////////////////////////////////////////////////////////
string         htfSsStatus[];//Colours defined at top of file
double         htfSsVal[];
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2a="================================================================";
extern string  mssl="---- Medium time frame Super Slope ----";
extern bool    UseMtfSs=false;
extern ENUM_TIMEFRAMES MtfSsTimeFrame=PERIOD_H4;
extern double  MtfSsDifferenceThreshold  = 1.0;
extern int     MtfSsSlopeMAPeriod        = 7; 
extern int     MtfSsSlopeATRPeriod       = 50; 
//Allow the user to select a candle shift
extern int     MtfSsBarShift=0;
//A couple of inputs to stop trading if SS does not indicate sufficient strength
extern double  MtfSsSlopeBuyAbove=1;
extern double  MtfSsSlopeSellBelow=-1;
extern string  Mtfcch="-- Colour change --";
extern bool    MtfCloseMarketTradesOnOppositeSignal=false;
//MtfCloseMarketTradesOnOppositeSignal has to be enabled for the next two inputs to come into operation.
extern double  MtfCloseBuysBelow=-0.5;
extern double  MtfCloseSellsAbove=0.5;
extern bool    MtfDeletePendingTradesOnOppositeSignal=false;
////////////////////////////////////////////////////////////////////////////////////////
string         mtfSsStatus[];//Colours defined at top of file
double         mtfSsVal[];
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep3a="================================================================";
extern string  lssl="---- lowest time frame Super Slope ----";
extern bool    UseLtfSs=false;
extern ENUM_TIMEFRAMES LtfSsTimeFrame=PERIOD_H1;
extern double  LtfSsDifferenceThreshold  = 1.0;
extern int     LtfSsSlopeMAPeriod        = 7; 
extern int     LtfSsSlopeATRPeriod       = 50; 
//Allow the user to select a candle shift
extern int     LtfSsBarShift=0;
//A couple of inputs to stop trading if SS does not indicate sufficient strength
extern double  LtfSsSlopeBuyAbove=1;
extern double  LtfSsSlopeSellBelow=-1;
extern string  Ltfcch="-- Colour change --";
extern bool    LtfCloseMarketTradesOnOppositeSignal=false;
//LtfCloseMarketTradesOnOppositeSignal has to be enabled for the next two inputs to come into operation.
extern double  LtfCloseBuysBelow=-0.5;
extern double  LtfCloseSellsAbove=0.5;
extern bool    LtfDeletePendingTradesOnOppositeSignal=false;
////////////////////////////////////////////////////////////////////////////////////////
string         ltfSsStatus[];//Colours defined at top of file
double         ltfSsVal[];
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1e="================================================================";
extern string  pea="---- Peaky inputs ----";
extern bool    UsePeaky=true;
extern ENUM_TIMEFRAMES PeakyTimeFrame=PERIOD_H4;
extern int     NoOfBarsOnChart=1682;
extern bool    CloseAllWhenPeakyChanges=false;
////////////////////////////////////////////////////////////////////////////////////////
string         peakyStatus[];//Up or down 
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1b="================================================================";
extern string  gri="---- Grid inputs ----";
//Send a market trade as soon as there is a signal
extern bool    SendImmediateMarketTrade=false;
extern int     GridSize=5;
extern int     DistanceBetweenTradesPips=30;
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
extern bool    UseNextLevelForTP=false;
////////////////////////////////////////////////////////////////////////////////////////
double         distanceBetweenTrades=0;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1c="================================================================";
extern string  bas="---- Basket trading ----";
//Pips and cash inputs will not be considered when = 0
extern string  ind="-- Individual pairs --";
extern bool    TreatIndividualPairsAsBasket=false;
extern int     IndividualBasketTargetPips=0;
extern double  IndividualBasketTargetCash=0;
extern bool    LeaveIndividualBasketPendingsOpen=false;
extern bool    UseAtrForBasketTP=false;
extern ENUM_TIMEFRAMES TpAtrTimeFrame=PERIOD_H4;
extern int     TpAtrPeriod=14;
extern double  TpPercentOfAtrToUse=100;
extern string  dbi="-- Dynamic individual pair basket take profit --";
//Individual Pair Basket cash TP based on lot size. Lucky64 added this function. Many thanks Luciano.
extern bool    UseDynamicCashTPIndividualPair=false;
extern double  CashTakeProfitIndividualePairPerLot=1000;
extern string  all="-- All trades belong to a single basket --";
extern bool    TreatAllPairsAsBasket=true;
extern int     BasketTargetPips=0;
extern double  BasketTargetCash=0;
extern bool    LeaveAllPairsBasketPendingsOpen=false;
extern string  dbt="-- Dynamic basket take profit --";
//Basket cash TP based on lot size
extern bool    UseDynamicCashTP=false;
extern double  CashTakeProfitPerLot=3000;
////////////////////////////////////////////////////////////////////////////////////////
bool           forceWholePositionClosure=false;
bool           deletePendings=false;//Set in OnInit()
////////////////////////////////////////////////////////////////////////////////////////
//The basket cash trailing stop feature was added by 1of3. Fabulous contribution John; many thanks.
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
extern bool    UseRecovery=true;
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
extern int     FridayCloseAllHour=20;
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
extern string  BasketFridayCashTargets="10,30,12,20,14,10,16,5,18,1";
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
extern bool    UseForexKiwi=false;
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
extern int     fontSize          = 10;
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


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

   if(WriteFileForTestDatabase) 
      ChartSaveTemplate(0,StringFormat("ZZT2MTPL-%s-%s-%s-%d-%d-%d-%d","SHF","SPB","MULSYM",Period(),AccountNumber(),TimeCurrent(),MagicNumber));

   // TDesk code
   if (SendToTDesk)
      InitializeTDesk(TradeComment,MagicNumber);

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
   
   //Extract the pairs traded by the user
   extractPairs();

   
   StringInit(gap, displaygapSize, ' ' );
   
   //Idiot check for HtfSsSlopeSellBelow
   if (HtfSsSlopeSellBelow > 1)
      HtfSsSlopeSellBelow*= -1;//Needs to be a negative number
   
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
         price = MarketInfo(symbol, MODE_ASK);
         stop = calculateStopLoss(OP_BUY, price);
         double sendLots = calculateLotSize(symbol, price, stop);
      
         calculateDynamicBasketCashTP(sendLots);
      
      }//if (!closeEnough(RiskPercent, 0))
      
      
   }//if (UseDynamicCashTP)

   originalBasketTargetCash=BasketTargetCash;
   originalBasketTargetPips=BasketTargetPips;   
      

   if (MinimiseChartsAfterOpening)
      shrinkCharts();

   
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

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    
   ArrayFree(tradePair);
   ArrayFree(ttfCandleTime);
   ArrayFree(oldHtfIndiReadBarTime);
   ArrayFree(oldMtfIndiReadBarTime);
   ArrayFree(oldLtfIndiReadBarTime);
   ArrayFree(htfSsStatus);
   ArrayFree(htfSsVal);
   ArrayFree(mtfSsStatus);
   ArrayFree(mtfSsVal);
   ArrayFree(ltfSsStatus);
   ArrayFree(ltfSsVal);
   ArrayFree(buySignal);
   ArrayFree(sellSignal);
   ArrayFree(timeToStartTrading);
   ArrayFree(pipsUpl);
   ArrayFree(cashUpl);
   ArrayFree(buyTradeTotals);
   ArrayFree(sellTradeTotals);
   ArrayFree(closedBuyTradeTotals);
   ArrayFree(closedSellTradeTotals);
   ArrayFree(peakyStatus);
   ArrayFree(buyOnlyPairs);
   ArrayFree(sellOnlyPairs);
   ArrayFree(longOnlyPairs);
   ArrayFree(shortOnlyPairs);
   ArrayFree(buyCashUpl);
   ArrayFree(sellCashUpl);
   


   removeAllObjects();
   
   // TDesk code
   DeleteTDeskSignals();
   
   //--- destroy timer
   EventKillTimer();
       
}//End void OnDeinit(const int reason)


void readIndicatorValues()
{

   
   for (int pairIndex = 0; pairIndex <= ArraySize(tradePair) - 1; pairIndex++)
   {
      int cc = 0;
      double val = 0;
      
      string symbol = tradePair[pairIndex];//Makes typing easier
      getBasics(symbol);//Bid etc
  
      countOpenTrades(symbol, pairIndex);
      //Prevent multiple trades
      buySignal[pairIndex] = false;
      sellSignal[pairIndex] = false;

      int barReadingPeriod = 0;//A variable that allows indis to be read once a candle if need be
      
      //Htf SS
      if (UseHtfSs)
      {
         if (HtfSsBarShift > 0)
            barReadingPeriod = HtfSsTimeFrame;
         else
            barReadingPeriod = PERIOD_M5;//Read the Htf SS every 5 minutes to save cpu
               
         if (oldHtfIndiReadBarTime[pairIndex] != iTime(symbol, barReadingPeriod, 0) )
         { 
            oldHtfIndiReadBarTime[pairIndex] = iTime(symbol, barReadingPeriod, 0);
            
            
            //Read SuperSlope at the open of each new trading time frame candle
            htfSsVal[pairIndex] = getSuperSlope(symbol, HtfSsTimeFrame,HtfSsSlopeMAPeriod,HtfSsSlopeATRPeriod,HtfSsBarShift);
                  
            //Changed by tomele. Many thanks Thomas.
            //Set the colours
            htfSsStatus[pairIndex] = white;
            
            if (htfSsVal[pairIndex] > 0)  //buy
               if (htfSsVal[pairIndex] - HtfSsDifferenceThreshold/2 > 0) //blue
                  htfSsStatus[pairIndex] = blue;
   
            if (htfSsVal[pairIndex] < 0)  //sell
               if (htfSsVal[pairIndex] + HtfSsDifferenceThreshold/2 < 0) //red
                  htfSsStatus[pairIndex] = red;
            // TDesk code
            if (SendToTDesk)
            {
               if(htfSsStatus[pairIndex]==white) PublishTDeskSignal("SS",HtfSsTimeFrame,symbol,FLAT); else
               if(htfSsStatus[pairIndex]==blue)  PublishTDeskSignal("SS",HtfSsTimeFrame,symbol,LONG); else
               if(htfSsStatus[pairIndex]==red)   PublishTDeskSignal("SS",HtfSsTimeFrame,symbol,SHORT);
            }//if (SendToTDesk)
         }//if (oldHtfIndiReadBarTime != iTime(symbol, barReadingPeriod, 0) )
      }//if (UseHtfSs)
         
      //Mtf SS
      if (UseMtfSs)
      {
         if (MtfSsBarShift > 0)
            barReadingPeriod = MtfSsTimeFrame;
         else
            barReadingPeriod = PERIOD_M5;//Read the Htf SS every 5 minutes to save cpu
               
         if (oldMtfIndiReadBarTime[pairIndex] != iTime(symbol, barReadingPeriod, 0) )
         { 
            oldMtfIndiReadBarTime[pairIndex] = iTime(symbol, barReadingPeriod, 0);
            
            
            //Read SuperSlope at the open of each new trading time frame candle
            mtfSsVal[pairIndex] = getSuperSlope(symbol, MtfSsTimeFrame,MtfSsSlopeMAPeriod,MtfSsSlopeATRPeriod,MtfSsBarShift);
                  
            //Changed by tomele. Many thanks Thomas.
            //Set the colours
            mtfSsStatus[pairIndex] = white;
            
            if (mtfSsVal[pairIndex] > 0)  //buy
               if (mtfSsVal[pairIndex] - MtfSsDifferenceThreshold/2 > 0) //blue
                  mtfSsStatus[pairIndex] = blue;
   
            if (mtfSsVal[pairIndex] < 0)  //sell
               if (mtfSsVal[pairIndex] + MtfSsDifferenceThreshold/2 < 0) //red
                  mtfSsStatus[pairIndex] = red;

            // TDesk code
            if (SendToTDesk)
            {
               if(mtfSsStatus[pairIndex]==white) PublishTDeskSignal("SS",MtfSsTimeFrame,symbol,FLAT); else
               if(mtfSsStatus[pairIndex]==blue)  PublishTDeskSignal("SS",MtfSsTimeFrame,symbol,LONG); else
               if(mtfSsStatus[pairIndex]==red)   PublishTDeskSignal("SS",MtfSsTimeFrame,symbol,SHORT);
            }//if (SendToTDesk)
            
         }//if (oldMtfIndiReadBarTime != iTime(symbol, barReadingPeriod, 0) )
      }//if (UseMtfSs)
         
      //Ltf SS
      if (UseLtfSs)
      {   
         if (LtfSsBarShift > 0)
            barReadingPeriod = LtfSsTimeFrame;
         else
            barReadingPeriod = PERIOD_M5;//Read the Htf SS every 5 minutes to save cpu
               
         if (oldLtfIndiReadBarTime[pairIndex] != iTime(symbol, barReadingPeriod, 0) )
         { 
            oldLtfIndiReadBarTime[pairIndex] = iTime(symbol, barReadingPeriod, 0);
            
            
            //Read SuperSlope at the open of each new trading time frame candle
            ltfSsVal[pairIndex] = getSuperSlope(symbol, LtfSsTimeFrame,LtfSsSlopeMAPeriod,LtfSsSlopeATRPeriod,LtfSsBarShift);
                  
            //Changed by tomele. Many thanks Thomas.
            //Set the colours
            ltfSsStatus[pairIndex] = white;
            
            if (ltfSsVal[pairIndex] > 0)  //buy
               if (ltfSsVal[pairIndex] - LtfSsDifferenceThreshold/2 > 0) //blue
                  ltfSsStatus[pairIndex] = blue;
   
            if (ltfSsVal[pairIndex] < 0)  //sell
               if (ltfSsVal[pairIndex] + LtfSsDifferenceThreshold/2 < 0) //red
                  ltfSsStatus[pairIndex] = red;

            // TDesk code
            if (SendToTDesk)
            {
               if(ltfSsStatus[pairIndex]==white) PublishTDeskSignal("SS",LtfSsTimeFrame,symbol,FLAT); else
               if(ltfSsStatus[pairIndex]==blue)  PublishTDeskSignal("SS",LtfSsTimeFrame,symbol,LONG); else
               if(ltfSsStatus[pairIndex]==red)   PublishTDeskSignal("SS",LtfSsTimeFrame,symbol,SHORT);
            }//if (SendToTDesk)
            
         }//if (oldLtfIndiReadBarTime != iTime(symbol, barReadingPeriod, 0) )
      }//if (UseLtfSs)
       
      //Combine the timeframes into one variable
      if (UseHtfSs || UseMtfSs || UseLtfSs)
      {       
         string AllColours = "";//Holds the combined value of all SS readings. Will be mixed, red or blue;
         AllColours = mixed;

         if (!UseHtfSs || htfSsStatus[pairIndex] == blue)
            if (!UseMtfSs || mtfSsStatus[pairIndex] == blue )
               if (!UseLtfSs || ltfSsStatus[pairIndex] == blue )
                  AllColours = blue;
               
         if (!UseHtfSs || htfSsStatus[pairIndex] == red )
            if (!UseMtfSs || mtfSsStatus[pairIndex] == red)
               if (!UseLtfSs || ltfSsStatus[pairIndex] == red)
                  AllColours = red;
         
      }//if (UseHtfSs || UseMtfSs || UseLtfSs)
      
         
      //Peaky
      if (UsePeaky)
      {
         getPeaky(symbol, pairIndex);
         // TDesk code
         if (SendToTDesk)
         { 
            if(peakyStatus[pairIndex]==peakylongtradable) PublishTDeskSignal("PK",PeakyTimeFrame,symbol,LONG); else
            if(peakyStatus[pairIndex]==peakyshorttradable) PublishTDeskSignal("PK",PeakyTimeFrame,symbol,SHORT); else
            PublishTDeskSignal("PK",PeakyTimeFrame,symbol,FLAT);
         }//if (SendToTDesk)            
      }//if (UsePeaky)
         
      //Make the initial trading decision
               
      //Buy
      if (!UseHtfSs || (htfSsStatus[pairIndex] == blue && htfSsVal[pairIndex] > HtfSsSlopeBuyAbove))
         if (!UseMtfSs || (mtfSsStatus[pairIndex] == blue && mtfSsVal[pairIndex] > MtfSsSlopeBuyAbove))
            if (!UseLtfSs || (ltfSsStatus[pairIndex] == blue && ltfSsVal[pairIndex] > LtfSsSlopeBuyAbove))
               if (!UsePeaky || peakyStatus[pairIndex] == peakylongtradable)   
                  if (marketBuysCount == 0)
                     if (buyStopsCount == 0)
                        buySignal[pairIndex] = true;
                           
      //Sell
      if (!UseHtfSs || (htfSsStatus[pairIndex] == red && htfSsVal[pairIndex] < HtfSsSlopeSellBelow))
         if (!UseMtfSs || (mtfSsStatus[pairIndex] == red && mtfSsVal[pairIndex] < MtfSsSlopeSellBelow))
            if (!UseLtfSs || (ltfSsStatus[pairIndex] == red && ltfSsVal[pairIndex] < LtfSsSlopeSellBelow))         
               if (!UsePeaky || peakyStatus[pairIndex] == peakyshorttradable)
                  if (marketSellsCount == 0)
                     if (sellStopsCount == 0)
                        sellSignal[pairIndex] = true;
                        
      //Fill in gaps if the market is moving in the wrong direction.
      //This is only needed if we are grid trading.
      if (GridSize > 0 && marginCheck() )
      {
         double price = 0, target = 0, sendPrice = 0;
         double stop = 0, take = 0, sendLots = 0;
         bool result = true;
         
         //Examine buys
         //if (buyStopsCount > 0 || marketBuysCount > 0 )
         if ((buyStopsCount > 0 || marketBuysCount > 0) && (!HtfDeletePendingTradesOnOppositeSignal || htfSsStatus[pairIndex] != red)
            && (!MtfDeletePendingTradesOnOppositeSignal || mtfSsStatus[pairIndex] != red)
            && (!LtfDeletePendingTradesOnOppositeSignal || ltfSsStatus[pairIndex] != red))
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
                  //Stop the gap filling from exceeding the broker's trade limit.
                  //Delete the highest pending order.
                  if (!checkBrokerMaxTradesOnPlatform(1) )
                  {
                     //Rebuild a picture of the position.
                     countOpenTrades(symbol, pairIndex);
                     result = OrderDelete(highestbuyStopTicketNo);
                     //In case something went wrong
                     if (!result)
                        return;//Cannot send the new pending order, so no use continuing.
                  }//if (!checkBrokerMaxTradesOnPlatform(1) )
                  
                  sendPrice = NormalizeDouble(price - (distanceBetweenTrades / factor), digits);
                  //Yes, so set the parameters and send a trade
                  stop = calculateStopLoss(OP_BUY, sendPrice);
                  take = calculateTakeProfit(OP_BUY, sendPrice);
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
         if ((sellStopsCount > 0 || marketSellsCount > 0) && (!HtfDeletePendingTradesOnOppositeSignal || htfSsStatus[pairIndex] != blue)
            && (!MtfDeletePendingTradesOnOppositeSignal || mtfSsStatus[pairIndex] != blue)
            && (!LtfDeletePendingTradesOnOppositeSignal || ltfSsStatus[pairIndex] != blue))
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
                  //Stop the gap filling from exceeding the broker's trade limit.
                  //Delete the lowest pending order.
                  if (!checkBrokerMaxTradesOnPlatform(1) )
                  {
                     //Rebuild a picture of the position.
                     countOpenTrades(symbol, pairIndex);
                     result = OrderDelete(lowestSellStopTicketNo);
                     //In case something went wrong
                     if (!result)
                        return;//Cannot send the new pending order, so no use continuing.
                  }//if (!checkBrokerMaxTradesOnPlatform(1) )
                  
                  sendPrice = NormalizeDouble(price + (distanceBetweenTrades / factor), digits);
                  //Yes, so set the parameters and send a trade
                  stop = calculateStopLoss(OP_SELL, sendPrice);
                  take = calculateTakeProfit(OP_SELL, sendPrice);
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
         
      
         
     //Chart automation
     // if (tradingStatus[pairIndex] == tradablelong || tradingStatus[pairIndex] == tradableshort)
         if (AutomateChartOpeningAndClosing)
            chartAutomation(symbol, pairIndex);
            
      
   }//for (int cc = 0; cc <= ArraySize(tradePair); cc++)

   Comment("");
   
}//void readIndicatorValues()



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
      take = calculateTakeProfit(type, price);
      stop = calculateStopLoss(type, price);
   }//if (HideStopLossAndTakeProfit)
      
   
       
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
   {
      //TP
      if (bid >= take && !closeEnough(take, 0) && !closeEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
      //SL
      if (bid <= stop && !closeEnough(stop, 0)  && !closeEnough(stop, OrderStopLoss())) CloseThisTrade = true;
 
      //Complete opposite direction signal on highest timeframe
      if (!CloseThisTrade)
         if (htfSsStatus[pairIndex] == red)
            if (peakyStatus[pairIndex] == peakyshorttradable)
               CloseThisTrade = true;
   
      //Peaky opposite signal
      if (!CloseThisTrade)
         if (UsePeaky)
            if (peakyStatus[pairIndex] == peakyshorttradable)
               if (CloseAllWhenPeakyChanges)
                  CloseThisTrade = true;
 
      //Market trade
      if (OrderType() < 2)
      {
         //Htf
         if (!CloseThisTrade)
            if (UseHtfSs && HtfCloseMarketTradesOnOppositeSignal)
               if (htfSsVal[pairIndex] < HtfCloseBuysBelow)
                  CloseThisTrade = true;
     
         //Mtf
         if (!CloseThisTrade)
            if (UseMtfSs && MtfCloseMarketTradesOnOppositeSignal)
               if (mtfSsVal[pairIndex] < MtfCloseBuysBelow)
                  CloseThisTrade = true;
     
         //Ltf
         if (!CloseThisTrade)
            if (UseLtfSs && LtfCloseMarketTradesOnOppositeSignal)
               if (ltfSsVal[pairIndex] < LtfCloseBuysBelow)
                  CloseThisTrade = true;
     
      }//if (OrderType() < 2)
               
      //Pending trade
      if (OrderType() > 1 && OrderType() < 6)//6 is a deposit into the account
      {
         //Htf
         if (!CloseThisTrade)
            if (UseHtfSs && HtfDeletePendingTradesOnOppositeSignal)
               if (htfSsStatus[pairIndex] == red)
                  CloseThisTrade = true;
               
         //Mtf
         if (!CloseThisTrade)
            if (UseMtfSs && MtfDeletePendingTradesOnOppositeSignal)
               if (mtfSsStatus[pairIndex] == red)
                  CloseThisTrade = true;
               
         //Ltf
         if (!CloseThisTrade)
            if (UseLtfSs && LtfDeletePendingTradesOnOppositeSignal)
               if (ltfSsStatus[pairIndex] == red)
                  CloseThisTrade = true;
                 
      }//if (OrderType() > 1 && OrderType() < 6)
               
   }//if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
   {
      //TP
      if (bid <= take && !closeEnough(take, 0) && !closeEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
      //SL
      if (bid >= stop && !closeEnough(stop, 0)  && !closeEnough(stop, OrderStopLoss())) CloseThisTrade = true;
 
      //Complete opposite direction signal on highest timeframe
      if (!CloseThisTrade)
         if (htfSsStatus[pairIndex] == blue)
            if (peakyStatus[pairIndex] == peakylongtradable)
               CloseThisTrade = true;
   
      //Peaky opposite signal
      if (!CloseThisTrade)
         if (UsePeaky)
            if (peakyStatus[pairIndex] == peakylongtradable)
               if (CloseAllWhenPeakyChanges)
                  CloseThisTrade = true;
 
      //Market trade
      if (OrderType() < 2)
      {
         //Htf
         if (!CloseThisTrade)
            if (UseHtfSs && HtfCloseMarketTradesOnOppositeSignal)
               if (htfSsVal[pairIndex] > HtfCloseSellsAbove)
                  CloseThisTrade = true;
     
         //Mtf
         if (!CloseThisTrade)
            if (UseMtfSs && MtfCloseMarketTradesOnOppositeSignal)
               if (mtfSsVal[pairIndex] > MtfCloseSellsAbove)
                  CloseThisTrade = true;
     
         //Ltf
         if (!CloseThisTrade)
            if (UseLtfSs && LtfCloseMarketTradesOnOppositeSignal)
               if (ltfSsVal[pairIndex] > LtfCloseSellsAbove)
                  CloseThisTrade = true;
     
      }//if (OrderTyp() < 2)
     
      //Pending trade
      if (OrderType() > 1 && OrderType() < 6)//6 is a deposit into the account
      {
         //Htf
         if (!CloseThisTrade)
            if (UseHtfSs && HtfDeletePendingTradesOnOppositeSignal)
               if (htfSsStatus[pairIndex] == blue)
                  CloseThisTrade = true;
               
         //Mtf
         if (!CloseThisTrade)
            if (UseMtfSs && MtfDeletePendingTradesOnOppositeSignal)
               if (mtfSsStatus[pairIndex] == blue)
                  CloseThisTrade = true;
               
         //Ltf
         if (!CloseThisTrade)
            if (UseLtfSs && LtfDeletePendingTradesOnOppositeSignal)
               if (ltfSsStatus[pairIndex] == blue)
                  CloseThisTrade = true;
                 
      }//if (OrderType() > 1 && OrderType() < 6)
           
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
      
   if (UseHtfSs)
      TTLength+=SSLength;
   if (UseMtfSs)
      TTLength+=SSLength;
   if (UseLtfSs)
      TTLength+=SSLength;

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
   
   if (UseHtfSs)
   {
      TextXPos+=SSLength;
      text1 = getTimeFramedisplay(HtfSsTimeFrame);
      displayTextLabel(text1,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("SS",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }//if (UseHtfSs)
   
   if (UseMtfSs)
   {
      TextXPos+=SSLength;
      text1 = getTimeFramedisplay(MtfSsTimeFrame);
      displayTextLabel(text1,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("SS",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }//if (UseMtfSs)
         
   if (UseLtfSs)
   {
      TextXPos+=SSLength;
      text1 = getTimeFramedisplay(LtfSsTimeFrame);
      displayTextLabel(text1,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
      displayTextLabel("SS",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   }//if (UseLtfSs)
   
   TextXPos+=SSLength;
   text1 = getTimeFramedisplay(PeakyTimeFrame);
   displayTextLabel(text1,TextXPos,TextYPos,ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   displayTextLabel("PK",TextXPos,TextYPos+(int)(FactorY*1.5),ANCHOR_RIGHT_UPPER,"", 0, ActTitleColor);
   
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
      if (whatToShow=="TradablePairs" && (peakyStatus[pairIndex]==peakylonguntradable || peakyStatus[pairIndex]==peakyshortuntradable
          || htfSsStatus[pairIndex] == white))
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
      if (UseHtfSs)
      {
         TextXPos+=SSLength;
         displayTextLabel(htfSsStatus[pairIndex],TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      }//if (UseHtfSs)
      
      if (UseMtfSs)
      {  
         TextXPos+=SSLength;
         displayTextLabel(mtfSsStatus[pairIndex],TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      }//if (UseMtfSs)
      
      if (UseLtfSs)
      {  
         TextXPos+=SSLength;
         displayTextLabel(ltfSsStatus[pairIndex],TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      }//if (UseMtfSs)
      
      
      TextXPos+=SSLength;
      displayTextLabel(peakyStatus[pairIndex],TextXPos,TextYPos,ANCHOR_RIGHT_UPPER);
      
      
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
   
   if (UseHtfSs)
      TextXPos+=SSLength;
   
   if (UseMtfSs)
      TextXPos+=SSLength;
         
   if (UseLtfSs)
      TextXPos+=SSLength;

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

   TextXPos+=TRLength;
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
   
   sm(NL);

   //Trading done for the week stuff
   if (doneForTheWeek)
      sm("---------- WE HAVE REACHED OUR WEEKLY PROFIT TARGET. I HAVE STOPPED TRADING UNTIL NEXT WEEK. ----------" + NL);
   
   if (AutoTradingEnabled)
      if(rolloverInProgress)
      {
         sm(NL);
         sm("---------- ROLLOVER IN PROGRESS. I am taking no action until "+RollOverEnds+" ----------"+NL);
      }//if (RolloverInProgress)
   
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
      sizingInfo += " , Individual pair basket cash take profit = " + AccountCurrency() + " " + DoubleToStr(IndividualBasketTargetCash, 2)
      + ", Individual pair basket pips take profit = " + " " + IntegerToHexString(IndividualBasketTargetPips) + " pips";
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
   
   int maxAllowedByBroker = (int) AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
   sm("Maximum no of trades allowed on the platform, by your broker: " + IntegerToString(maxAllowedByBroker) );
      
   // TDesk
   if(ShowDashboard)
   {   
      sm("Click a pair to open its chart, the table name to switch between views, the headers to show/hide details, the labels at the bottom to let them do what they offer."+NL);
      displayMatrix();
   }
 
   //Comment(screenMessage);


}//End void displayUserFeedback()

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
         stop = calculateStopLoss(OP_BUY, price);
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
   
   if (MinimiseChartsAfterOpening)
      shrinkCharts();
   
   //Using the EA to trade
   if (AutoTradingEnabled)
      autoTrading();
   
   displayUserFeedback();
   
}
//+------------------------------------------------------------------+
