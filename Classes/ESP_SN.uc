class ESP_SN expands SpawnNotify;

var ESP Mutator;
var LeagueAS_Inventory LASInvs[32];


auto state InitialDelay
{
Begin:
	Sleep(0.0);
	Mutator.bSNSpawned = true;
}

event Actor SpawnNotification( actor A)
{
	local int i;
	if (A.isA('LeagueAS_Inventory') && Mutator.bNoClipProtection)
	{
		// Hook the LAS inventory, keep track during timer
		for (i = 0; i < 32; i++)
		{
			if (LASInvs[i]==None)
			{
				LASInvs[i] = LeagueAS_Inventory(A);
				SetTimer(Mutator.CheckRate,true);
				break;
			}
		}
	}
	return A;
}

event Timer()
{
	local int i;
	local bool bTracking;
	for (i = 0; i < 32; i++)
	{
		if (LASInvs[i]!=None)
		{
			// Grab the PlayerOwner and set bBlockPlayers to false while SpawnProtectActive is true
			if (LASInvs[i].PlayerOwner != None && LASInvs[i].LeagueAssaultGame != None)
			{
				if (LASInvs[i].SpawnProtectActive == true)
				{
					LASInvs[i].PlayerOwner.bBlockPlayers = false;
				}
				else
				{
					LASInvs[i].PlayerOwner.bBlockPlayers = true;
					LASInvs[i] = None; // drop tracking of this inv
				}
			}
		}
	}
	// Check whether timer is still needded
	bTracking = false;
	for (i = 0; i < 32; i++)
	{
		if (LASInvs[i]!=None)
		{
			bTracking = true;
		}
	}
	if (!bTracking)
	{
		SetTimer(0,false);
	}
}

defaultproperties
{
	ActorClass=class'LeagueAS_Inventory'
	RemoteRole=ROLE_None
}