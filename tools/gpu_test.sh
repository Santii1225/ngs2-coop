#!/bin/bash
# gpu_test.sh NAME 'KEY=VAL;KEY=VAL'  -- launch the game with Proton user_settings env, report whether frames render.
T=$(dirname "$(realpath "$0")"); PD="$HOME/.local/share/Steam/steamapps/common/Proton 11.0"
NAME=$1; ENVS=$2
{ echo "# gpu_test $NAME"; echo "user_settings = {"; IFS=';'; for kv in $ENVS; do [ -n "$kv" ] && echo "    \"${kv%%=*}\": \"${kv#*=}\","; done; echo "}"; } > "$PD/user_settings.py"
$T/game.sh stop >/dev/null; $T/game.sh start >/dev/null
best=0
for i in $(seq 12); do sleep 3; $T/game.sh focus
  out=$($T/shot.sh /tmp/ngs2coop/gpu_$NAME.png 2>/dev/null) || continue
  mx=$(python3 -c "from PIL import Image; print(Image.open('/tmp/ngs2coop/gpu_$NAME.png').convert('L').getextrema()[1])")
  [ "$mx" -gt "$best" ] && best=$mx; [ "$best" -gt 50 ] && break
done
dev=$(grep -a -E "Using device|D3D11InternalCreateDevice: Using|DxgiAdapter|Device name" ~/steam-1580790.log | tail -2 | tr '\n' ' ')
gpus=$(grep -a -o "Found device: [^(]*" ~/steam-1580790.log | sort -u | tr '\n' ',')
echo "[$NAME] max_luma=$best  $( [ $best -gt 50 ] && echo RENDERS || echo BLACK )  | env: $ENVS"
nvidia-smi --query-compute-apps=pid,process_name --format=csv,noheader 2>/dev/null | grep -i ninja && echo "  -> running on NVIDIA" || echo "  -> not on NVIDIA (nvidia-smi)"
