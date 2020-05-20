These scripts can be used by the MetaTrader system to build executables for automatically initiating
stop or limit orders when a certain signal is detected.

The "C_" file needs to be placed within the include directory and the "EA_" file needs to be placed within the Experts
directory and then compiled into an executable.

The EA has the following characteristics:
I_MagicNumber					- Unique identifier for the EA
I_ATRPeriod					- ATR Period used when looking for the break-out.
I_AtRisk=20					- The amount put at risk in the account currency.
I_StoplossMethod				- Method for calculating the stoploss (low/high of previous 2 candles or ATR Multiplier)
I_ReversionPercent				- Where the stop/limit order is placed relative to the previous 2 candles.
I_StoplossATRMultiplier				- When ATR is used to calculate the stoploss, this multiplier is also used.
I_TypicalSpread					- Typical spread of the symbol and used to add an extra stoploss adjustment to the SL calculation.
I_MaxLotSize					- Maximum Lot Size for any trade.
I_RiskRewardRatio=1.5				- Risk/Rewards used when calculating the TakeProfit level.
I_LimitStopOrderExpiryMins			- Duration of the stoploss in minutes.
I_HiddenStoplossOffset				- Extra offset added for a Hidden Stoploss.
I_TradingStartHour				- Start hour for trading
I_TradingEndHour				- End hour for trading
I_LogResultsInFile				- Determines if a summary of the EA is stored in a log file once the EA finishes.
