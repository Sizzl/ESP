# ESP

### Enhanced Spawn Protection for League Assault.
![Build Status](https://github.com/Sizzl/ESP/actions/workflows/ucc-make.yml/badge.svg)



Requires:

 - LeagueAS140.
   - For building this from source, utilise headers at [Sizzl/LeagueAS140](https://github.com/Sizzl/LeagueAS140) to compile.
   - For general client and server usage, simply download the compiled LeagueAS files from [utassault.net](https://www.utassault.net/leagueas/files/LeagueAS140.zip)

Start-up:
 - Add "ESP140.ESP" to your mutator startup line, MapVote or DynamicPackageLoader configuration.
   - e.g. AS-Submarinebase][?game=LeagueAS140.LeagueAssault?mutator=ESP140.ESP

Usage:

 - `mutate ESP` -- provides information on the current spawn protection times for Attackers and Defenders
