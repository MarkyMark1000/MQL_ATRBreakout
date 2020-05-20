//+------------------------------------------------------------------+
//|                                     C_BASIC_OPTIMIZATION_LOG.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
//| C_BASIC_OPTIMIZATION_LOG Class                                                      |
//+------------------------------------------------------------------+
class C_BASIC_OPTIMIZATION_LOG
{
private:
   //Private Variables
   string m_strFileName;
   string m_strWhereIsTheLog;
   string m_strWhereIsTheStrategyTesterLog;
   string m_strEATitles[];
   
   //Private Functions
   string GenerateDefaultFileName();
   void WriteLogFileTitles();
   void AppendStringToLog(const string strInput);
   void CalculateTradeHistoryCharacteristics(int intMagicNumber, int &intNoTrades, 
                                 int &intNoWins,double &dblMaxDrawdown, double &dblTotalTradeProfit);
public:
   //Public Variables
   
   //Constructor and Destructor
   C_BASIC_OPTIMIZATION_LOG(string & strEATitles[]);
   ~C_BASIC_OPTIMIZATION_LOG();
   
   //Public Functions
   void UpdateLog(int intMagicNumber, string & strEAParameterValues[]);
   void PrintLocationOfLogFiles();
   void RemoveLogFile();
   void ArchiveAndRemoveLogFile();
   bool FileExists();
};
//+------------------------------------------------------------------+
//|  Constructor                                                     |
//+------------------------------------------------------------------+
void C_BASIC_OPTIMIZATION_LOG::C_BASIC_OPTIMIZATION_LOG(string & strEATitles[])
{
   //-- Generate the default filename for this log
   this.m_strFileName = GenerateDefaultFileName();
   
   //Update WhereIsTheLog so that the developer can find out where the live log
   //and tester log file should be.
   string strTerminalPath = TerminalInfoString(TERMINAL_DATA_PATH);
   this.m_strWhereIsTheLog=strTerminalPath+"\\MQL4\\Files\\"+this.m_strFileName;
   this.m_strWhereIsTheStrategyTesterLog=strTerminalPath+"\\tester\\files\\"+this.m_strFileName;

   //-- In Constructor you must pass in an array of the EA Parameter Titles.
   int intNoTitles = ArraySize(strEATitles);
   ArrayResize(this.m_strEATitles,intNoTitles,intNoTitles);
   ArrayCopy(this.m_strEATitles,strEATitles);
   
   //-- If the log file does not exist, then write the EA Titles to the log file
   if(!this.FileExists())
   {
      this.WriteLogFileTitles();
   }
   
}
//+------------------------------------------------------------------+
//|  Destructor                                                     |
//+------------------------------------------------------------------+
C_BASIC_OPTIMIZATION_LOG::~C_BASIC_OPTIMIZATION_LOG()
{

   //-- Free up the array
   ArrayFree(this.m_strEATitles);
   
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  Private Functions                                               |
//+------------------------------------------------------------------+
string C_BASIC_OPTIMIZATION_LOG::GenerateDefaultFileName()
{
   //-- Defines strings
   string strSymbol, strRet = "Opt_";
   
   //-- Remove unusual characters from the symbol
   strSymbol = Symbol();
   StringReplace(strSymbol,"+","");
   StringReplace(strSymbol,"-","");
   StringReplace(strSymbol,".","");
   StringReplace(strSymbol,"=","");
   
   //-- Add symbol to filename
   strRet += strSymbol;
   
   //-- Now add the timeframe
   strRet += IntegerToString(PeriodSeconds()/60);
   
   strRet += ".txt";
   
   return strRet;
   
}
void C_BASIC_OPTIMIZATION_LOG::WriteLogFileTitles()
{
   /*
   This generates the first line of the log file that should be generated
   when the log file is first created.   We use the EA Parameters then
   add extra ones calculated by the optimization log.
   */
   
   string strWrite="";
   
   //--Add EA Parameters
   for(int i=0;i<ArraySize(this.m_strEATitles);i++)
   {
      strWrite += (this.m_strEATitles[i] + ";");
   }
   
   //--Now add extra log titles
   strWrite += "End_Account_Balance;End_Account_Equity;Total P&L;NoTrades;NoWinTrades;";
   strWrite += "WinRatio;MaxDrawdown;TotalTradeProfit;P&L_DD_Ratio;P&L_NoTrades_Ratio";
   
   //--Now write the files
   this.AppendStringToLog(strWrite);
   
}

void C_BASIC_OPTIMIZATION_LOG::AppendStringToLog(const string strInput)
{
   //This function opens the Log File, moves to the end of the file and then appends the input
   //string to the file.   Returns (ie \r\n) are added by this routine onto the end of the string.
   
   //Reset the last error
   ResetLastError();
   
   //Open the file - must be read and write for appending to files.
   int intFileHandle=FileOpen(this.m_strFileName,FILE_READ|FILE_WRITE|FILE_TXT);
   
   //If the file has been opened successfully, write to it
   if(intFileHandle!=INVALID_HANDLE)
   {
      //Find the End of the file
      if(!FileSeek(intFileHandle,0,SEEK_END))   Print(__FUNCTION__,"File Seek Error ",GetLastError());
      
      //Write the String
      if(FileWriteString(intFileHandle,strInput+"\r\n")<=0) Print(__FUNCTION__,"File Write Error ",GetLastError());
      
      //Close the file
      FileClose(intFileHandle);
   }
   else
   {
      Print(__FUNCTION__,"Failed to open file ",this.m_strFileName," ",GetLastError());
   }
   
   return;
}
void C_BASIC_OPTIMIZATION_LOG::CalculateTradeHistoryCharacteristics(int intMagicNumber, int &intNoTrades, 
                                 int &intNoWins,double &dblMaxDrawdown, double &dblTotalTradeProfit)
{
   //-- update orders history total
   intNoTrades = OrdersHistoryTotal();
   
   //-- update number of wins and drawdown
   int intCount=0, intCountWin=0;
   double dblIndex=0, dblMax=0, dblMin=0;
   dblMaxDrawdown = 0;
   
   for(int i=0;i<intNoTrades;i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==intMagicNumber &&
            (OrderType()==OP_BUY || OrderType()==OP_SELL))
         {  
            //-- Update count of actual trades (not limit/stop)
            intCount++;
            
            //-- Update the trade p&L
            double dblProfit = OrderProfit()+OrderCommission()+OrderSwap();
            
            //-- Update count wins
            if(dblProfit>0)  intCountWin++;
            
            //-- update profit index
            dblIndex += dblProfit;
           
            //--If index goes above max index, reset the minimum figure
            //--encountered to the index level, otherwise min is lowest index
            dblMin = (dblIndex > dblMax) ? dblIndex : MathMin(dblIndex, dblMin);
            
            //--Update max index
            dblMax = MathMax(dblIndex, dblMax);
            
            dblMaxDrawdown = (dblMax-dblMin) > dblMaxDrawdown ? (dblMax-dblMin) : dblMaxDrawdown;   
            
         }
      }
   }
   
   //-- update the final no wins and no trades
   intNoTrades = intCount;
   intNoWins = intCountWin;
   
   //-- update the final maximum drawdown
   dblMaxDrawdown = (dblMax-dblMin) > dblMaxDrawdown ? (dblMax-dblMin) : dblMaxDrawdown;
                     
   //-- Update the total trade profit with dblIndex.
   dblTotalTradeProfit = dblIndex;

}
//+------------------------------------------------------------------+
//|  Public Functions                                                |
//+------------------------------------------------------------------+
void C_BASIC_OPTIMIZATION_LOG::UpdateLog(int intMagicNumber, string & strEAParameterValues[])
{
   //-- Check the array size is sensible
   if(ArraySize(strEAParameterValues) != ArraySize(this.m_strEATitles))
   {
      Print("*** ERROR - PARAMETER VALUE ARRAY SIZE DIFFERENT TO PARAMETER TITLE ARRAY SIZE");
   }
   
   //-- Variable dec to write to file
   string strWrite = "";
   
   //-- Add the parameter values
   for(int i=0;i<ArraySize(strEAParameterValues);i++)
   {
      strWrite += (strEAParameterValues[i] + ";");
   }
   
   //-- Now add End_Account_Balance;End_Account_Equity;Total P&L
   strWrite += DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE))+";";
   strWrite += DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY))+";";
   strWrite += DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT))+";";
   
   //-- Calculate no trades, no wins and max drawdown
   double dblMaxDrawdown, dblTotalTradeProfit=0;
   int intNoTrades, intNoWins;
   this.CalculateTradeHistoryCharacteristics(intMagicNumber, intNoTrades,
                                          intNoWins, dblMaxDrawdown, dblTotalTradeProfit);
   
   //-- Now update NoTrades;NoWinTrades;MaxDrawdown
   strWrite += IntegerToString(intNoTrades)+";";
   strWrite += IntegerToString(intNoWins)+";";
   strWrite += DoubleToString((double)intNoWins/(double)intNoTrades,2)+";";
   strWrite += DoubleToString(dblMaxDrawdown,4)+";";
   strWrite += DoubleToString(dblTotalTradeProfit,4)+";";
   strWrite += DoubleToString(dblTotalTradeProfit/dblMaxDrawdown,4)+";";
   strWrite += DoubleToString(dblTotalTradeProfit/(double)intNoTrades,6);   
   //-- Finally update the log
   this.AppendStringToLog(strWrite);
   
}

void C_BASIC_OPTIMIZATION_LOG::PrintLocationOfLogFiles()
{
   //Call this function at the end of an EA to let the developer/user know where the log file is stored.
   Print(this.m_strWhereIsTheStrategyTesterLog); 
   Print("Location of Strategy Tester Log File:");
   Print(this.m_strWhereIsTheLog);
   Print("Location of Standard Log File:");
     
   return;
}
void C_BASIC_OPTIMIZATION_LOG::RemoveLogFile()
{
   //This just deletes the log file
   FileDelete(this.m_strFileName);
   return;
}
void C_BASIC_OPTIMIZATION_LOG::ArchiveAndRemoveLogFile()
{
   //If there is not a BUP directory it creates it.   It then deletes any BUP versions of the filename from this directory
   //and copys the file over it.   A new log file is then created.
   //It is best if this is called during the Init stage of an EA so that we have prepaired a new log file for data
   
   if(!FileIsExist("BUP"))
   {
      FolderCreate("BUP");
   }
   
   FileDelete("Bup\\"+this.m_strFileName);
   FileCopy(this.m_strFileName,0,"BUP\\"+this.m_strFileName,FILE_REWRITE);
   FileDelete(this.m_strFileName);
   return;
   
}
bool C_BASIC_OPTIMIZATION_LOG::FileExists()
{
   string strFile=this.m_strFileName;
   bool boolRet=FileIsExist(strFile);
   return boolRet;
}