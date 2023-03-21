//+------------------------------------------------------------------+
//|                                                           MD.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// User-defined input variables
extern ENUM_TIMEFRAMES TradingTimeFrame = PERIOD_H1;
extern ENUM_TIMEFRAMES MaTimeFrame = PERIOD_D1;
extern bool EveryTickMode = false;
extern int MaPeriod = 20;
extern ENUM_MA_METHOD MaMethod = MODE_EMA;
extern ENUM_APPLIED_PRICE MaAppliedPrice = PRICE_CLOSE;
extern int StopOrderDistancePips = 20;

// Global variables
int MaShift = 0;
double lastMaValue = 0;
bool longCross = false;
bool shortCross = false;

// Status messages
string mastatus[];

// Initialization function
int init() {
    // Set up status messages
    mastatus[0] = "EMA not initialized";
    mastatus[1] = "EMA initialized";
    mastatus[2] = "Long cross detected";
    mastatus[3] = "Short cross detected";

    // Set up moving average shift
    MaShift = MaPeriod * 24;

    // Set up EMA on higher timeframe
    int MaHandle = iMA(NULL, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice);
    if (MaHandle != INVALID_HANDLE) {
        lastMaValue = iMA(NULL, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 1);
        mastatus[0] = mastatus[1];
    }

    return 0;
}

// Function to check for a long cross
bool checkLongCross() {
    double currentMaValue = iMA(NULL, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 1);

    if (lastMaValue < 0 && currentMaValue > 0) {
        lastMaValue = currentMaValue;
        return true;
    }

    lastMaValue = currentMaValue;
    return false;
}

// Function to check for a short cross
bool checkShortCross() {
    double currentMaValue = iMA(NULL, MaTimeFrame, MaPeriod, MaShift, MaMethod, MaAppliedPrice, 1);

    if (lastMaValue > 0 && currentMaValue < 0) {
        lastMaValue = currentMaValue;
        return true;
    }

    lastMaValue = currentMaValue;
    return false;
}

// Function to open a buy trade
void openBuyTrade() {
    double price = Ask + StopOrderDistancePips * Point;
    int ticket = OrderSend(Symbol(), OP_BUYSTOP, 0.1, price, 3, Bid - StopOrderDistancePips * Point, 0, "", 0, 0, Green);
    if (ticket > 0) {
        mastatus[4] = "Buy trade opened";
    }
    else {
        mastatus[4] = "Error opening buy trade";
    }
}

// Function to open a sell trade
void openSellTrade() {
    double price = Bid - StopOrderDistancePips * Point;
    int ticket = OrderSend(Symbol(), OP_SELLSTOP, 0.1, price, 3, Ask + StopOrderDistancePips * Point, 0, "", 0, 0, Red);
    if (ticket > 0) {
        mastatus[4] = "Sell trade opened";
    }
    else {
        mastatus[4] = "Error opening sell trade";
    }
}

// Function to close all open trades
void closeAllTrades() {
for (int i = OrdersTotal() - 1; i >= 0; i--) {
if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
if (OrderSymbol() == Symbol()) {
if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
bool success = OrderClose(OrderTicket(), OrderLots(), Bid, 3, Yellow);
if (success) {
mastatus[5] = "All trades closed";
}
else {
mastatus[5] = "Error closing trades";
}
}
}
}
}
}

// Main function
void OnTick() {
// Exit if in every tick mode and not on a new tick
if (EveryTickMode && !IsNewBar()) {
return;
}

// Check for long and short crosses
longCross = checkLongCross();
shortCross = checkShortCross();

// If a long cross is detected, close all trades and open a buy trade
if (longCross) {
    closeAllTrades();
    openBuyTrade();
    mastatus[2] = "Long cross detected, opened buy trade";
}

// If a short cross is detected, close all trades and open a sell trade
if (shortCross) {
    closeAllTrades();
    openSellTrade();
    mastatus[3] = "Short cross detected, opened sell trade";
}

// Function to handle chart events
void OnChartEvent(const int id,
const long& lparam,
const double& dparam,
const string& sparam) {
// If the user clicks the chart, print the current status
if (id == CHARTEVENT_CLICK) {
string status = "";
for (int i = 0; i < ArraySize(mastatus); i++) {
status += mastatus[i] + "\n";
}
Comment(status);
}
}

// Function to handle initialization errors
void OnDeinit(const int reason) {
if (reason == REASON_REMOVE) {
Print("Expert removed from chart");
}
else if (reason == REASON_RECOMPILE) {
Print("Expert recompiled");
}
else {
Print("Expert deinitialized for reason ", reason);
}
}