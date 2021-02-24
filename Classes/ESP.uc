//======================================================================//
// Enhanced Spawn Protection for LeagueAS ©2021 timo@utassault.net		//
//																		//
// ProtectionOverrides adhere to the following format:					//
//																		//
//	 AS-MapName;A|D;X;[optional tag]									//
//																		//
//	 - Where A is attackers or D is defenders							//
//	 - X is protection in seconds										//
//	 - [optional tag] only applies to tagged playerstarts				//
//					(empty value or * will apply to all PlayerStarts	//
//						for that team)									//
//																		//
//	 See examples in defaultproperties{} section						//
//																		//
//======================================================================//

class ESP expands Mutator config;

var bool bInitialized, bTagsFetched;
var float CheckRate;
var string AppString, ValidAttackerOverrides[64], ValidDefenderOverrides[64], vATag, vDTag; 
var int VA, VD, VC, VF;

// Config
var() config bool bEnabled;
var() config bool bDebug;
var() config bool bAlwaysUseDefaults;
var() config bool bFirstRun;
var() config int LogLevel; // 0 = No debug, 1 = Basic debug, 2 = Verbose, 3 = Trace
var() config int ProtectAttackers;
var() config int ProtectDefenders;
var() config string ProtectionOverrides[64]; // 

event PreBeginPlay()
{

	if(!bInitialized && bEnabled)
	{
		if(Level.Game.IsA('LeagueAssault'))
		{
			if (bAlwaysUseDefaults || bFirstRun)
			{
				log("Restoring defaults...",'ESP');
				RestoreESPDefaults();
				bAlwaysUseDefaults=true;
				bFirstRun=false;
				log("Restoring defaults complete.",'ESP');
			}
			SaveConfig();
			if (LogLevel > 0)
				bDebug = true;
			PopulateVOs();
			VF = VF*(1/CheckRate);
			SetTimer(CheckRate,true);
			log(AppString@"initialization complete. (Mode = "$String(Level.NetMode)$"; Always Use Defaults:"@bAlwaysUseDefaults$").");
			if (bDebug)
			{
				log("- Debugging: true; LogLevel:"@LogLevel,'ESP');
			}
			bInitialized = true;
		} else {
			log(AppString@"running, but disabled (not AS gametype).",'ESP');
			bInitialized = true;
		}
		bInitialized = true;
	}
	else
	{
		if (!bEnabled)
		{
			log(AppString@"running, but disabled (bEnabled = false).",'ESP');
			bInitialized = true;
		}
	}
}
function RestoreESPDefaults()
{
	// Using this, since StaticSaveConfig isn't working as expected
	local int i;
	ProtectAttackers = class'ESP_Defaults'.Default.ProtectAttackers;
	ProtectDefenders = class'ESP_Defaults'.Default.ProtectDefenders;
	for (i = 0; i < 64; i++)
	{
		if (bDebug && LogLevel > 1 && (ProtectionOverrides[i]!="" || class'ESP_Defaults'.Default.ProtectionOverrides[i] != ""))		
			log("Restoring current value:"@ProtectionOverrides[i]@"->"@class'ESP_Defaults'.Default.ProtectionOverrides[i],'ESP');
		ProtectionOverrides[i] = class'ESP_Defaults'.Default.ProtectionOverrides[i];
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
function GetActivePSTags()
{
	local PlayerStart PS;
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
	bTagsFetched = true;
}
event Timer()
{
	local LeagueAS_Inventory LASI;

	local int i, vDFinal, vAFinal, v;
	local string ValidEntry, t;

	vDFinal = ProtectDefenders;
	vAFinal = ProtectAttackers;
	
	if (bDebug)
		VC++;

	if (VA > 0 || VD > 0)
	{
		// Determine active playerstarts as there may be a valid override
		GetActivePSTags();

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
		if (!bTagsFetched)
		{
			GetActivePSTags();
		}
		foreach AllActors(Class'LeagueAS_Inventory',LASI)
		{
			cVA = LASI.default.AttackerSpawnProt;
			cVD = LASI.default.DefenderSpawnProt;
		}
		Sender.ClientMessage("Current attacker protection:"@cVA$"s; current spawn point tag:"@vATag);
		Sender.ClientMessage("Current defender protection:"@cVD$"s; current spawn point tag:"@vDTag);
	}
	else if (Sender.bAdmin && MutateString ~= "esp reset")
	{
		RestoreESPDefaults();
		Sender.ClientMessage("Reset protection overrides to defaults.");
		MutateString = "esp refresh";
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
	bFirstRun=true
	LogLevel=0
	CheckRate=0.5
	ProtectAttackers=2
	ProtectDefenders=1
	VF=4
}