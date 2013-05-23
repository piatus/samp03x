// ----------------
// Simple kick_fix that fixes kick priority error(a.k.a not showing messages and gui sended before kick).
// Author: promsters a.k.a Tomasz Ptak
// --------------------------

#include <a_samp>
#define Kick(%0) SetTimerEx("promsters_KickTimer", 0, false, "i", %0)
native promsters_Kick(playerid) = Kick;

forward promsters_KickTimer(playerid);
public promsters_KickTimer(playerid)
{
	promsters_Kick(playerid);
}

