class ESP_Defaults expands Actor config;
var int ProtectAttackers, ProtectDefenders;
var config string ProtectionOverrides[64];

defaultproperties
{
	ProtectAttackers=2
	ProtectDefenders=1
	ProtectionOverrides(0)="AS-Bridge*;D;2;PlayerStart"
	ProtectionOverrides(1)="AS-Bridge*;A;4;sp2"
	ProtectionOverrides(2)="AS-Bridge*;A;4;sp3"
	ProtectionOverrides(3)="AS-DesertStorm;A;3;at5"
	ProtectionOverrides(4)="AS-DesertStorm;A;4;at1"
	ProtectionOverrides(5)="AS-DesertStorm;D;2;def3"
	ProtectionOverrides(6)="AS-Asthenosphere*;A;4;"
	ProtectionOverrides(7)="AS-Asthenosphere*;D;2;startspawn"
	ProtectionOverrides(8)="AS-Asthenosphere*;D;2;spawn2"
	ProtectionOverrides(9)="AS-Ballistic*;D;2;startspawn"
	ProtectionOverrides(10)="AS-Ballistic*;A;3;secspawn"
	ProtectionOverrides(11)="AS-Ballistic*;A;3;thspawn"
	ProtectionOverrides(12)="AS-GolgothaAL;D;2;def1"
	ProtectionOverrides(13)="AS-GolgothaAL;D;2;def2"
	ProtectionOverrides(14)="AS-GolgothaAL;A;3;at3"
	ProtectionOverrides(15)="AS-GolgothaAL;A;4;at4"
	ProtectionOverrides(16)="AS-GolgothaAL;A;4;at5"
	ProtectionOverrides(17)="AS-GolgothaAL;A;4;at6"
	ProtectionOverrides(18)="AS-Riverbed]l[*;D;2;def3"
	ProtectionOverrides(19)="AS-Riverbed]l[*;D;2;def5"
	ProtectionOverrides(20)="AS-Riverbed]l[*;A;4;at1"
	ProtectionOverrides(21)="AS-Riverbed]l[*;A;3;at6"
	ProtectionOverrides(22)="AS-GekokujouAL][*;A;3;PlayerStart"
	ProtectionOverrides(23)="AS-TheDungeon]l[AL;D;2;"
}