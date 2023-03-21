//+------------------------------------------------------------------+
//|                                                       Signal.mq4 |
//|                  Copyright 2023, MetaQuotes Software Corp. |
//|                                           https://www.mql5.com |
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
    mastatus[4] = "";

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

// Main function
void OnTick() {
    // Check for new long or short cross
    if (checkLongCross()) {
        longCross = true;
        shortCross = false;
        mastatus[4] = "Long cross detected";
    }
    else if (checkShortCross()) {
        shortCross = true;
        longCross = false;
        mastatus[4] = "Short cross detected";
    }

    // Close open trades and open new trades
    if (longCross) {
        // Close all open sell trades
        int totalSellTrades = 0;
        int sellTrades = OrdersTotal();
        for (int i = 0; i < sellTrades; i++) {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                if (OrderType() == OP_SELL) {
                    if (OrderClose(OrderTicket(), OrderLots(), Bid, 3, Red)) {
                        totalSellTrades++;
                    }
                }
            }
        }

        // Open a buy trade
        openBuyTrade();
    }
    else if (shortCross) {
        // Close all open buy trades
        int totalBuyTrades = 0;
        int buyTrades = OrdersTotal
        
// Main function to check for signals and manage trades
void OnTick() {
if (EveryTickMode || Time[0] != Time[1]) {
// Check for long cross
if (checkLongCross()) {
longCross = true;
shortCross = false;
mastatus[3] = "";
mastatus[2] = mastatus[2] + " (" + TimeToStr(TimeCurrent(), TIME_DATE | TIME_MINUTES) + ")";
}

    // Check for short cross
    if (checkShortCross()) {
        shortCross = true;
        longCross = false;
        mastatus[2] = "";
        mastatus[3] = mastatus[3] + " (" + TimeToStr(TimeCurrent(), TIME_DATE | TIME_MINUTES) + ")";
    }

    // Close sell trades and open buy trade on long cross
    if (longCross) {
        if (OrdersTotal() > 0) {
            for (int i = OrdersTotal() - 1; i >= 0; i--) {
                if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderType() == OP_SELL) {
                    if (!OrderDelete(OrderTicket())) {
                        mastatus[4] = "Error closing sell trade";
                        return;
                    }
                }
            }
        }
        openBuyTrade();
        longCross = false;
    }

    // Close buy trades and open sell trade on short cross
    if (shortCross) {
        if (OrdersTotal() > 0) {
            for (int i = OrdersTotal() - 1; i >= 0; i--) {
                if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderType() == OP_BUY) {
                    if (!OrderDelete(OrderTicket())) {
                        mastatus[4] = "Error closing buy trade";
                        return;
                    }
                }
            }
        }
        openSellTrade();
        shortCross = false;
    }
}
}

// Function to display status messages on the chart
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
if (id == CHARTEVENT_OBJECT_CREATE || id == CHARTEVENT_OBJECT_CHANGE) {
for (int i = 0; i < ArraySize(mastatus); i++) {
ObjectDelete("mastatus_" + i);
ObjectCreate("mastatus_" + i, OBJ_LABEL, 0, 0, 0);
ObjectSetText("mastatus_" + i, mastatus[i], 9, "Arial", White);
ObjectSet("mastatus_" + i, OBJPROP_CORNER, 1);
ObjectSet("mastatus_" + i, OBJPROP_XDISTANCE, 10);
ObjectSet("mastatus_" + i, OBJPROP_YDISTANCE, 10 + i * 20);
}
}
}

//+------------------------------------------------------------------+

