These scripts can be used by the MetaTrader system to build executables for automatically initiating
stop or limit orders when a certain signal is detected.

Please note that this is not a production version of the file and so may be missing updates.

The "C_" file needs to be placed within the include directory and the "EA_" file needs to be placed within the Experts
directory and then compiled into an executable.

The EA has the following characteristics:<br>
I_MagicNumber					- Unique identifier for the EA<br>
I_ATRPeriod					- ATR Period used when looking for the break-out.<br>
I_AtRisk=20					- The amount put at risk in the account currency.<br>
I_StoplossMethod				- Method for calculating the stoploss (low/high of previous 2 candles or ATR Multiplier)<br>
I_ReversionPercent				- Where the stop/limit order is placed relative to the previous 2 candles.<br>
I_StoplossATRMultiplier				- When ATR is used to calculate the stoploss, this multiplier is also used.<br>
I_TypicalSpread					- Typical spread of the symbol and used to add an extra stoploss adjustment to the SL calculation.<br>
I_MaxLotSize					- Maximum Lot Size for any trade.<br>
I_RiskRewardRatio=1.5				- Risk/Rewards used when calculating the TakeProfit level.<br>
I_LimitStopOrderExpiryMins			- Duration of the stoploss in minutes.<br>
I_HiddenStoplossOffset				- Extra offset added for a Hidden Stoploss.<br>
I_TradingStartHour				- Start hour for trading<br>
I_TradingEndHour				- End hour for trading<br>
I_LogResultsInFile				- Determines if a summary of the EA is stored in a log file once the EA finishes.<br>
