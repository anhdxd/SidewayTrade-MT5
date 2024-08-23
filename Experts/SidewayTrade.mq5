//+------------------------------------------------------------------+
//|                                                 SidewayTrade.mq5 |
//|                                            Copyright 2024, Anhdz |
//|                                        https://github.com/anhdxd |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2024, Anhdz"
#property link        "https://github.com/anhdxd"
#property version     "1.0"
#property description "Sideway Trade"
#property description "XAUUSD"

#include <EAUtils.mqh>

input group "Indicator Parameters"
// input int CeAtrPeriod = 1; // CE ATR Period
// input double CeAtrMult = 0.75; // CE ATR Multiplier
// input int ZlPeriod = 50; // ZLSMA Period

input group "General"
input int SLDev = 650; // SL Deviation (Points)
input bool CloseOrders = true; // Check For Closing Conditions
input bool Reverse = false; // Reverse Signal

input group "Risk Management"
input double Risk = 3; // Risk
input ENUM_RISK RiskMode = RISK_DEFAULT; // Risk Mode
input bool IgnoreSL = true; // Ignore SL
input bool Trail = true; // Trailing Stop
input double TrailingStopLevel = 50; // Trailing Stop Level (%) (0: Disable)
input double EquityDrawdownLimit = 0; // Equity Drawdown Limit (%) (0: Disable)

// input group "Strategy: Grid"
// input bool Grid = true; // Grid Enable
// input double GridVolMult = 1.5; // Grid Volume Multiplier
// input double GridTrailingStopLevel = 0; // Grid Trailing Stop Level (%) (0: Disable)
// input int GridMaxLvl = 50; // Grid Max Levels

// input group "News"
// input bool News = false; // News Enable
// input ENUM_NEWS_IMPORTANCE NewsImportance = NEWS_IMPORTANCE_MEDIUM; // News Importance
// input int NewsMinsBefore = 60; // News Minutes Before
// input int NewsMinsAfter = 60; // News Minutes After
// input int NewsStartYear = 0; // News Start Year to Fetch for Backtesting (0: Disable)

input group "Open Position Limit"
input bool OpenNewPos = true; // Allow Opening New Position
input bool MultipleOpenPos = false; // Allow Having Multiple Open Positions
input double MarginLimit = 300; // Margin Limit (%) (0: Disable)
input int SpreadLimit = -1; // Spread Limit (Points) (-1: Disable)

input group "Auxiliary"
input int Slippage = 30; // Slippage (Points)
input int TimerInterval = 30; // Timer Interval (Seconds)
input ulong MagicNumber = 2000; // Magic Number
input ENUM_FILLING Filling = FILLING_DEFAULT; // Order Filling

int BuffSize = 4;

GerEA ea;
datetime lastCandle;
datetime tc;

#define PATH_ZZ "Indicators\\zigzag.ex5" // Zigzag path
#define I_ZZ "::" + PATH_ZZ // Zigzag indicator
#resource "\\" + PATH_ZZ // Zigzag resource
int ZZ_handle;
double ZZ_Z[];
double ZZ_H[];
double ZZ_L[];

// #define PATH_CE "Indicators\\ChandelierExit.ex5"
// #define I_CE "::" + PATH_CE
// #resource "\\" + PATH_CE
// int CE_handle;
// double CE_B[], CE_S[];

// #define PATH_ZL "Indicators\\ZLSMA.ex5"
// #define I_ZL "::" + PATH_ZL
// #resource "\\" + PATH_ZL
// int ZL_handle;
// double ZL[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BuySignal() {
    // bool c = CE_B[1] != 0 && HA_C[1] > ZL[1];
    // if (!c) return false;

    // double in = Ask();
    // double sl = CE_B[1] - SLDev * _Point;
    // double tp = 0;
    // ea.BuyOpen(in, sl, tp, IgnoreSL, true);
    return true;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SellSignal() {
    // bool c = CE_S[1] != 0 && HA_C[1] < ZL[1];
    // if (!c) return false;

    // double in = Bid();
    // double sl = CE_S[1] + SLDev * _Point;
    // double tp = 0;
    // ea.SellOpen(in, sl, tp, IgnoreSL, true);
    return true;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckClose() {
    double p = getProfit(ea.GetMagic()) - calcCost(ea.GetMagic());
    if (p < 0) return;

    if (HA_C[2] >= ZL[2] && HA_C[1] < ZL[1])
        ea.BuyClose();

    if (HA_C[2] <= ZL[2] && HA_C[1] > ZL[1])
        ea.SellClose();
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    ea.Init();
    ea.SetMagic(MagicNumber);
    ea.risk = Risk * 0.01;
    ea.reverse = Reverse;
    ea.trailingStopLevel = TrailingStopLevel * 0.01;
    // ea.grid = Grid;
    // ea.gridVolMult = GridVolMult;
    // ea.gridTrailingStopLevel = GridTrailingStopLevel * 0.01;
    // ea.gridMaxLvl = GridMaxLvl;
    ea.equityDrawdownLimit = EquityDrawdownLimit * 0.01;
    ea.slippage = Slippage;
    // ea.news = News;
    // ea.newsImportance = NewsImportance;
    // ea.newsMinsBefore = NewsMinsBefore;
    // ea.newsMinsAfter = NewsMinsAfter;
    ea.filling = Filling;
    ea.riskMode = RiskMode;

    if (RiskMode == RISK_FIXED_VOL || RiskMode == RISK_MIN_AMOUNT) ea.risk = Risk;
    // if (News) fetchCalendarFromYear(NewsStartYear);

    HA_handle = iCustom(NULL, 0, I_HA);
    // CE_handle = iCustom(NULL, 0, I_CE, CeAtrPeriod, CeAtrMult);
    // ZL_handle = iCustom(NULL, 0, I_ZL, ZlPeriod, true);

    if (HA_handle == INVALID_HANDLE || CE_handle == INVALID_HANDLE || ZL_handle == INVALID_HANDLE) {
        Print("Runtime error = ", GetLastError());
        return(INIT_FAILED);
    }

    EventSetTimer(TimerInterval);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    datetime oldTc = tc;
    tc = TimeCurrent();
    if (tc == oldTc) return;

    if (Trail) ea.CheckForTrail();
    if (EquityDrawdownLimit) ea.CheckForEquity();
    // if (Grid) ea.CheckForGrid();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (lastCandle != Time(0)) {
        lastCandle = Time(0);

//    SetIndexBuffer(0,ZigzagBuffer,INDICATOR_DATA);
//    SetIndexBuffer(1,HighMapBuffer,INDICATOR_CALCULATIONS);
//    SetIndexBuffer(2,LowMapBuffer,INDICATOR_CALCULATIONS);
        if (CopyBuffer(ZZ_handle, 0, 0, BuffSize, ZZ_Z) <= 0) return;
        ArraySetAsSeries(ZZ_Z, true);
        if (CopyBuffer(ZZ_handle, 1, 0, BuffSize, ZZ_H) <= 0) return;
        ArraySetAsSeries(ZZ_H, true);
        if (CopyBuffer(ZZ_handle, 2, 0, BuffSize, ZZ_L) <= 0) return;
        ArraySetAsSeries(ZZ_L, true);
        


        if (CloseOrders) CheckClose();

        if (!OpenNewPos) return;
        if (SpreadLimit != -1 && Spread() > SpreadLimit) return;
        if (MarginLimit && PositionsTotal() > 0 && AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < MarginLimit) return;
        // if ((Grid || !MultipleOpenPos) && ea.OPTotal() > 0) return;

        if (BuySignal()) return;
        SellSignal();
    }
}

//+------------------------------------------------------------------+
