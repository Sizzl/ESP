//=====================================================================//
// Enhanced Spawn Protection for LeagueAS ©2021 timo@utassault.net		 //
//																																		 //
// ProtectionOverrides adhere to the following format:								 //
//																																		 //
//	 AS-MapName;A|D;X;[optional tag]																	 //
//																																		 //
//	 - Where A is attackers or D is defenders													//
//	 - X is protection in seconds																			//
//	 - [optional tag] only applies to tagged playerstarts							//
//					(empty value or * will apply to all PlayerStarts					 //
//						for that team)																					 //
//																																		 //
//	 See examples in defaultproperties{} section											 //
//																																		 //
//=====================================================================//

class ESP expands Mutator config;

var bool Initialized, bDebug;
var float	CheckRate;
var string AppString, ValidAttackerOverrides[64], ValidDefenderOverrides[64]; 
var int VA, VD, VC, VF;

// Config
var() config bool bEnabled;
var() config bool bAlwaysUseDefaults;
var() config int LogLevel; // 0 = No debug, 1 = Basic debug, 2 = Verbose, 3 = Trace
var() config int ProtectAttackers;
var() config int ProtectDefenders;
var() config string ProtectionOverrides[64]; // 

event PreBeginPlay()
{

	if(!Initialized && bEnabled)
	{
		if(Level.Game.IsA('LeagueAssault'))
		{
			if (bAlwaysUseDefaults)
				StaticSaveConfig();
			else
				SaveConfig();
			if (LogLevel > 0)
				bDebug = true;
			PopulateVOs();
			VF = VF*(1/CheckRate);
			SetTimer(CheckRate,true);
			log(AppString@"initialization complete. (Mode = "$String(Level.NetMode)$"; Always Use Defaults:"@bAlwaysUseDefaults$").");
			Initialized = true;
		} else {
			log(AppString@"running, but disabled (not AS gametype).",'ESP');
			Initialized = true;
		}
		Initialized = true;
	}
	else
	{
		if (!bEnabled)
		{
			log(AppString@"running, but disabled (bEnabled = false).",'ESP');
			Initialized = true;
		}
	}
}

function PopulateVOs()
{
	// Determine if current map has any protection overrides and store for quick usage
	local string MapName, ValidEntry, MapCheck;
	local int i;
	local bool bIsAtt;

	MapName = Left(Self, InStr(Self, "."));
	for (i = 0; i < 64; i++)
	{
		if (bDebug && LogLevel > 2)
			log("Checking override "$i$"/63 for "$MapName$":"@ProtectionOverrides[i],'ESP');

		ValidEntry = "";
		if (Left(ProtectionOverrides[i],(Len(MapName)+1)) ~= (MapName$";"))
			ValidEntry=Mid(ProtectionOverrides[i],(Len(MapName)+1));
		else if (Left(ProtectionOverrides[i],(Len(MapName)+5)) ~= (MapName$".unr;"))
			ValidEntry=Mid(ProtectionOverrides[i],(Len(MapName)+5));

		if (InStr(ProtectionOverrides[i],"*;") > 0)
		{
			MapCheck = Left(ProtectionOverrides[i],InStr(ProtectionOverrides[i],"*;"));
			if (bDebug && LogLevel > 2)
				log(" - Override "$i$"/63 wildcard detected:"@ProtectionOverrides[i]$", looking for maps beginning with:"@MapCheck,'ESP');
			// handle partial map name matching
			if (Left(MapName,Len(MapCheck)) ~= MapCheck)
			{
				if (bDebug && LogLevel > 1)
					log("Matched partial map"@MapCheck@"to"@MapName,'ESP');
				ValidEntry=Mid(ProtectionOverrides[i],(Len(MapCheck)+2));
			}
		}
		if (Len(ValidEntry) > 0)
		{
			if (bDebug && LogLevel > 2)
				log("Caching a spawn protection override:"@ValidEntry,'ESP');

			if (Left(ValidEntry,1)=="D")
				bIsAtt = false;
			else
				bIsAtt = true;

			ValidEntry = Mid(ValidEntry,2);

			if (bIsAtt)
			{
				if (bDebug && LogLevel > 1)
					log("Adding Attacker override:"@ValidEntry,'ESP');

				ValidAttackerOverrides[VA] = ValidEntry;
				VA++;
			}
			else
			{
				if (bDebug && LogLevel > 1)
					log("Adding Defender override:"@ValidEntry,'ESP');

				ValidDefenderOverrides[VA] = ValidEntry;
				VD++;
			}
		}
	}

}

event Timer()
{
	local LeagueAS_Inventory LASI;
	local PlayerStart PS;
	local int i, vDFinal, vAFinal, v;
	local string vATag, vDTag, ValidEntry, t;

	vDFinal = ProtectDefenders;
	vAFinal = ProtectAttackers;
	
	if (bDebug)
		VC++;

	if (VA > 0 || VD > 0)
	{
		// Determine active playerstarts as there may be a valid override
		foreach AllActors(Class'PlayerStart',PS)
		{
			if (PS.bEnabled)
			{
				if (PS.TeamNumber==1) // Attacker starts
				{
					if (Len(PS.Tag) == 0 && Len(vATag)==0)
						vATag = "None";
					else
						vATag = string(PS.Tag);
				}
				if (PS.TeamNumber==0) // Defender starts
				{
					if (Len(PS.Tag) == 0 && Len(vDTag)==0)
						vDTag = "None";
					else
						vDTag = string(PS.Tag);
				}
			}
		}

		if (VC > VF && LogLevel > 2)
			log("Current Att PS tag:"@vATag$", current Def PS tag:"@vDTag,'ESP');

		if (VA > 0) // Check valid attacker values and set vAFinal
		{
			for (i = 0; i < VA; i++)
			{
				ValidEntry = ValidAttackerOverrides[i];
				t="";
				if (InStr(ValidEntry, ";") > 0)
				{
					v = int(Left(ValidEntry,InStr(ValidEntry, ";")));
					t = Mid(ValidEntry,InStr(ValidEntry, ";")+1);
				}
				else
				{
					v = int(ValidEntry);
				}
				if (VC > VF && LogLevel > 2)
					log("Qualifying VA entry:"@ValidEntry$", v="$v$",t="$t,'ESP');

				if (Len(t) > 0 && vATag ~= t || t=="*")
				{
					if (VC > VF && LogLevel > 2)
						log("Overriding tagged vAFinal:"@vAFinal@"->"@v,'ESP');
					vAFinal = v;
					break; // treat this value as final
				}
				else if (Len(t)==0)
				{
					if (VC > VF && LogLevel > 2)
						log("Overriding untagged vAFinal:"@vAFinal@"->"@v,'ESP');
					vAFinal = v;
				}
				else
				{
					// do nothing
				}
			}
		}
		if (VD > 0) // Check valid defender values and set vDFinal
		{
			for (i = 0; i < VD; i++)
			{
				ValidEntry = ValidDefenderOverrides[i];
				t = "";
				if (InStr(ValidEntry, ";") > 0)
				{
					v = int(Left(ValidEntry,InStr(ValidEntry, ";")));
					t = Mid(ValidEntry,InStr(ValidEntry, ";")+1);
				}
				else
				{
					v = int(ValidEntry);
				}
				if (VC > VF && LogLevel > 2)
					log("Qualifying VD entry:"@ValidEntry$", v="$v$",t="$t,'ESP');
				if (Len(t) > 0 && vDTag ~= t || t=="*")
				{
					if (VC > VF && LogLevel > 2)
						log("Overriding tagged vDFinal:"@vDFinal@"->"@v,'ESP');
					vDFinal = v;
					break; // treat this value as final
				}
				else if (Len(t)==0)
				{
					if (VC > VF && LogLevel > 2)
						log("Overriding untagged vDFinal:"@vDFinal@"->"@v,'ESP');
					vDFinal = v;
				}
				else
				{
					// do nothing
				}
			}
		}
	}

	foreach AllActors(Class'LeagueAS_Inventory',LASI)
	{
		if (LASI.AttackerSpawnProt != vAFinal)
		{
			if (bDebug)
				log("Updating Attacker Spawn Protection to:"@vAFinal$"s",'ESP');
			LASI.default.AttackerSpawnProt = vAFinal;
			LASI.AttackerSpawnProt = vAFinal;
		}
		if (LASI.DefenderSpawnProt != vDFinal)
		{
			if (bDebug)
				log("Updating Defender Spawn Protection to:"@vDFinal$"s",'ESP');
			LASI.default.DefenderSpawnProt = vDFinal;
			LASI.DefenderSpawnProt = vDFinal;
		}
	}

	if (VC > VF)
		VC = 0;
}

function Mutate(string MutateString, PlayerPawn Sender)
{
	local LeagueAS_Inventory LASI;
	local int cVA, cVD;
	if(MutateString~="esp")
	{
		foreach AllActors(Class'LeagueAS_Inventory',LASI)
		{
			cVA = LASI.default.AttackerSpawnProt;
			cVD = LASI.default.DefenderSpawnProt;
		}
		Sender.ClientMessage("Current attacker protection:"@cVA$"s");
		Sender.ClientMessage("Current defender protection:"@cVD$"s");
	}
	else if (MutateString ~= "esp refresh")
	{
		PopulateVOs();
		Sender.ClientMessage("Refreshed Override List...");
		MutateString = "esp";
	}

	if ( NextMutator != None )
		NextMutator.Mutate(MutateString, Sender);
}

defaultproperties
{
	AppString="Enhanced Spawn Protection for LAS140:"
	bEnabled=true
	bAlwaysUseDefaults=false
	LogLevel=0
	CheckRate=0.5
	ProtectAttackers=2
	ProtectDefenders=1
	VF=4
	// Bridge
	ProtectionOverrides(0)="AS-Bridge*;D;2;PlayerStart"
	ProtectionOverrides(1)="AS-Bridge*;A;4;sp2"
	ProtectionOverrides(2)="AS-Bridge*;A;4;sp3"
	// DesertStorm
	ProtectionOverrides(3)="AS-DesertStorm;A;3;at5"
	ProtectionOverrides(4)="AS-DesertStorm;A;4;at1"
	ProtectionOverrides(5)="AS-DesertStorm;D;2;def3"
	// Asthenosphere
	ProtectionOverrides(6)="AS-Asthenosphere*;A;4;"// all att spawns to 4s
	ProtectionOverrides(7)="AS-Asthenosphere*;D;2;startspawn"
	ProtectionOverrides(8)="AS-Asthenosphere*;D;2;spawn2"
	// Ballistic
	ProtectionOverrides(9)="AS-Ballistic*;D;2;startspawn"
	ProtectionOverrides(10)="AS-Ballistic*;A;3;secspawn"
	ProtectionOverrides(11)="AS-Ballistic*;A;3;thspawn"
	// GolgothaAL
	ProtectionOverrides(12)="AS-GolgothaAL;A;3;at3"
	ProtectionOverrides(13)="AS-GolgothaAL;A;4;at4"
	ProtectionOverrides(14)="AS-GolgothaAL;A;4;at5"
	ProtectionOverrides(15)="AS-GolgothaAL;A;4;at6"
	// Riverbed3
	ProtectionOverrides(16)="AS-Riverbed]l[*;D;2;def3"
	ProtectionOverrides(17)="AS-Riverbed]l[*;D;2;def5"
	ProtectionOverrides(18)="AS-Riverbed]l[*;A;4;at1"
	ProtectionOverrides(19)="AS-Riverbed]l[*;A;3;at6"
	//GekokujouAL][
	ProtectionOverrides(20)="AS-GekokujouAL][*;A;3;PlayerStart"
}