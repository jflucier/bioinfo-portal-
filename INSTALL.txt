
Note: These scripts were only tested under linux (Ubuntu).

1 - install mysql and perl version 5.8 or above

2 - go to the path path/to/HTP_bsp_x.x/designs/Tool and run the following commands:
swig -perl5 oligotm.i; gcc -O3 -march=pentium4 -fomit-frame-pointer -pipe -c oligotm.c oligotm_wrap.c `perl -MExtUtils::Embed -e ccopts`; ld -G oligotm.o oligotm_wrap.o -o OligoTm.so
mv OligoTm.so ../..

3 - install the following cpan modules:
DBIx::Class::Schema
Config::Record
Data::Dump (gentoo: see bug #189865)
File::Temp
Storable
Term::ANSIColor
Error
Text::Wrap
List::Util
Bio::Tools::Primer3
use Bio::SearchIO

4 - install the following program:
Unafold: version 3.8 available in code/designs/Tool/unafold/ folder.
blastall (http://www.ncbi.nlm.nih.gov/BLAST/download.shtml). Use apt-get.


