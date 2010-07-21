#!/bin/sh

OUTFILE=transmutate.sh

echo '#!/bin/sh' >  $OUTFILE
echo '#'         >> $OUTFILE
cat variables.sh >> $OUTFILE
echo '#'         >> $OUTFILE
cat functions.sh >> $OUTFILE
echo '#'         >> $OUTFILE
cat main.sh      >> $OUTFILE

chmod +x $OUTFILE
