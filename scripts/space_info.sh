#!/bin/bash

declare -a _spaces
declare -a _valid_nums
_line_idx="7"

_resp=""

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}


for _space in $(echo """SELECT sdbs.dbsnum || '-' || sdbs.name 
  FROM sysdbspaces sdbs""" | dbaccess sysmaster 2> /dev/null | sed 's/.expression. *//')
do
  _spaces+=($_space)
  echo $_space
done

tput clear 
tput cup 5 17
tput rev
echo "S E L E C T   D B S p a c e"
tput sgr0

for _space in "${_spaces[@]}"; do 
  tput cup $_line_idx 15
  _space=${_space/-/ }
  echo $_space
  ((_line_idx++))
  _valid_nums+=(${_space%% *})
done


((_line_idx++))
tput cup $_line_idx 15
read -p "Eneter space number: " _resp

containsElement $_resp "${_valid_nums[@]}"
if [ "1" == "$?" ]; then
  exit
fi

_space_info="$(echo """SELECT sdbs.dbsnum, 
  sdbs.name, 
  ROUND( SUM( schk.chksize * schk.pagesize / 1024 / 1024 ), 4 ) AS _size_mib,
  ROUND( SUM( schk.nfree * schk.pagesize / 1024 / 1024 ), 4 ) AS _free_mib
FROM sysdbspaces sdbs 
JOIN syschunks schk ON schk.dbsnum = sdbs.dbsnum
WHERE sdbs.dbsnum = $_resp
GROUP BY sdbs.dbsnum, sdbs.name
ORDER BY sdbs.dbsnum """ | dbaccess sysmaster 2> /dev/null | sed '/^$/d')"

_dbs_name=$(echo $_space_info | cut -d \  -f 4)
_size_mib=$(echo $_space_info | cut -d \  -f 6)
_free_mib=$(echo $_space_info | cut -d \  -f 8)

for i in {1..3}; do 
  ((_line_idx++))
done

tput cup $_line_idx 17
tput rev
echo "D B S p a c e    S i z e"
tput sgr0

((_line_idx++))
((_line_idx++))
tput cup $_line_idx 15
echo "DbSpace: $_dbs_name"
((_line_idx++))
tput cup $_line_idx 15
echo "Size: $_size_mib"
((_line_idx++))
tput cup $_line_idx 15
echo "Free: $_free_mib"

echo ""
