function tickPeriod = GetTicksTick%  tickPeriod = GetTicksTick%% OS X and 9: ___________________________________________________________________%%  Return the period of the GetTicks clock. The period is always 1/60.15%  seconds.%% WINDOWS: ________________________________________________________________% % GetTicksTick does not exist in Windows.% % _________________________________________________________________________%%% SEE ALSO: GetTicks, GetSecs, GetSecsTick, GetBusTicks, GetBusTicksTick. %   HISTORY:%   07/10/04    awi     Wrote GetBusTick.m%   07/12/05    awi     Added platform sections.tickPeriod=1/60.15;