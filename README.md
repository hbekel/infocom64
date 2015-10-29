$Id$

infocom64
=========

Traditional Infocom Commodore 64 interpreters, updated for modern hardware

These interpreters (one each for v3, v4, and v5) were  disassembled from latest
officially released interpreters, and modified as follows:

* The 1541/1571 fastload routines were removed.
* The story file is loaded from "STORY.DAT" instead of raw blocks.
* To accomodate the above, RAM expansion or a uIEC is now required.
* "RAM expansion" means Commodore REU, Geo/NeoRAM, and EasyFlash.
* The number of save slots has been increased from five to nine.
* Save games are 49-block seq files named "SAVEn", where n is 1 through 9
* The game can be run from any device number, not just device 8.
* REU mirrored register access has been fixed.
* The v4 interpreter will play *all* v4 games (N&B, Trinity, AMFV, Bureaucracy)

These changes were made so that games could be easily played using an uIEC,
but would also be useful with any larger-capacity drive (1581, FD-2000, etc)
plus RAM expansion.  Thanks to Jim Brain's file-seek addition to the uIEC
firmware, a uIEC-equipped system does not need RAM expansion (but the game
will run considerably faster with extra RAM).

Trivia:

The v4 interpreter, as sourced from the "Nord and Bert" d64, does something
really interesting with the resident size when setting up the virtual memory
scheme. If you look at a non-C64-sourced version of N&B with infodump, you'll
see that the resident size is hardcoded to $AEFF.

Forcing that value with all other v4 games results in a working game, even if
the resident size overflows available physical memory. The interpreter already
assumes that anything over $F900 (start of $3A00, skipping $D000-DFFF) needs to
be paged in from REU/DISK, even if it is "resident".

This implies that the lack of support for v4 on a stock C64 was *not* due to
lack of physical memory, but rather lack of available disk space. Infocom could
have supported the C64 on *all* of the eight-bit titles that it released, if
they'd embraced the 1581 or went to a multi-disk scheme.

The were orphaned code fragments in v3/v4, a "Test1" string referenced nowhere
in v5, and I'm still trying to understand why the author(s) went to separate
hi/lo jump tables in v4/v5 rather than continuing with the unified tables in
v3. 

Also, the guy(s) who hacked the Commodore code into the v4 (and by extension
v5) interpreter was probably an intern, not terribly familiar with rational
code flow. And I do mean "hacked" -- subroutines will suddenly jump past a
bunch of unrelated code, the elegant word-based jump tables were deprecated in
favor of split-byte jump tables, and there was some unholy stuff going on in
the virtual-to-physical-address logic. Most memorable was the bit that asked
which of seven slots the printer was at.

I've concluded that the Apple ][ target was the reference platform, and other
6502 ports were derived from it with differing degrees of Apple-specific code
accidentally left in the Commodore versions.
