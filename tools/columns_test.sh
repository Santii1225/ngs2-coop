#!/bin/bash
# columns_test.sh -- at the character screen: friend joins, then each player presses only RIGHT on the
# top row; the exclusive-columns logic must route the friend to COMPAÑERO and P1 to JUGADOR.
T=$(dirname "$(realpath "$0")"); cd "$T"
rd() { python3 -c "import ngs2mem as n; m=n.Mem(); print('$1: column', m.u8(0x141e65458), 'screen', m.u8(0x1421544fa))"; }
./pad.sh r hold BACK 200; sleep 1.5; rd joined
./shot.sh /tmp/ngs2coop/col_0.png >/dev/null
./pad.sh r tap RIGHT 120; sleep 1.2; rd friend_right; ./shot.sh /tmp/ngs2coop/col_1.png >/dev/null
./pad.sh p1 tap RIGHT 120; sleep 1.2; rd p1_right; ./shot.sh /tmp/ngs2coop/col_2.png >/dev/null
./pad.sh r tap LB 120; sleep 1; ./pad.sh r tap RIGHT 120; sleep 1.2; rd friend_LB_right; ./shot.sh /tmp/ngs2coop/col_3.png >/dev/null
python3 -c "
from PIL import Image
ims=[Image.open('/tmp/ngs2coop/col_%d.png'%i).resize((480,300)) for i in range(4)]
W=Image.new('RGB',(960,600)); [W.paste(im,((i%2)*480,(i//2)*300)) for i,im in enumerate(ims)]; W.save('/tmp/ngs2coop/col_cmp.png')"
