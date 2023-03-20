//+------------------------------------------------------------------+
//|                                                        TDesk.mqh |
//| Include file for indicators and experts sending signals to TDesk |
//|             See the TDesk Manual for detailed usage instructions |
//+------------------------------------------------------------------+

#property copyright "Copyright 2020, tomele"
#property version   "1.00"


// Signal states TDesk can receive

enum TDESKSIGNALS
{
   NONE,
   FLAT,
   LONG,
   SHORT
};


// Global variables

string TDeskProvider;
int    TDeskMagic;


// Function to initialize the interface
// To be called in OnInit()

void InitializeTDesk(string provider, int magic=0)
{
   StringReplace(provider,"/","");
   TDeskProvider="TDSIG/"+provider;
   TDeskMagic=magic;
}


// Function to send actual signal values
// To be called in every EA main cycle

void PublishTDeskSignal(string name, ENUM_TIMEFRAMES timeframe, string symbol, TDESKSIGNALS signal, string tfoverwrite="")
{
   StringReplace(name,"/","");

   if(timeframe==PERIOD_CURRENT) timeframe=ChartPeriod();
   string tftext=EnumToString(timeframe);
   StringReplace(tftext,"PERIOD_","");
   
   string GVName=StringFormat("%s/%d/%s/%s/%s/%s",TDeskProvider,TDeskMagic,name,tftext,symbol,tfoverwrite);
   if(!GlobalVariableCheck(GVName)) GlobalVariableTemp(GVName);
   GlobalVariableSet(GVName,(double)signal);
}


// Function to delete delete sent signals
// To be called in OnDeinit()
// Parameters only needed if program is running in multiple instances

void DeleteTDeskSignals(string symbol="ALL", string timeframe="ALL", string name="ALL", string magic="ALL")
{
   for(int i=GlobalVariablesTotal()-1; i>=0; i--) 
   {
      string gvString=GlobalVariableName(i);

      if(StringFind(gvString,TDeskProvider)!=0) continue;
      if(StringFind(gvString,"/"+symbol+"/")<0 && symbol!="ALL") continue;
      if(StringFind(gvString,"/"+timeframe+"/")<0 && timeframe!="ALL") continue;
      if(StringFind(gvString,"/"+magic+"/")<0 && magic!="ALL") continue;
      if(StringFind(gvString,"/"+name+"/")<0 && name!="ALL") continue;
      
      GlobalVariableDel(gvString);
   }
}