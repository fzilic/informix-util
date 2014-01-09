#  Copyright (c) 2014, Franjo Žilić
#  All rights reserved.
#  
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met: 
#  
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer. 
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution. 
#  
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#  
#  The views and conclusions contained in the software and documentation are those
#  of the authors and should not be interpreted as representing official policies, 
#  either expressed or implied, of the FreeBSD Project.

#!/bin/ksh

_line_idx="7"

_resp=""

containsElement () {
  for e in "$@"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}


for _space in $(echo """SELECT sdbs.dbsnum || '-' || sdbs.name 
  FROM sysdbspaces sdbs""" | dbaccess sysmaster 2> /dev/null | sed 's/.expression. *//')
do
  set -A _spaces ${_spaces[@]} $_space
done

tput clear 
tput cup 5 17
tput rev
echo "S E L E C T   D B S p a c e"
tput sgr0

for _space in "${_spaces[@]}"; do 
  tput cup $_line_idx 15
  _space=$(echo $_space | sed 's/-/ /g')
  echo $_space
  ((_line_idx=_line_idx+1))
  set -A _valid_nums ${_valid_nums[@]} ${_space%% *}
done


((_line_idx=_line_idx+1))
tput cup $_line_idx 15
read _resp?"Eneter space number: "
((_line_idx=_line_idx+1))

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
  ((_line_idx=_line_idx+1))
done

tput cup $_line_idx 17
tput rev
echo "D B S p a c e    S i z e"
tput sgr0

((_line_idx=_line_idx+1))
((_line_idx=_line_idx+1))
tput cup $_line_idx 15
echo "DbSpace: $_dbs_name"
((_line_idx=_line_idx+1))
tput cup $_line_idx 15
echo "Size: $_size_mib"
((_line_idx=_line_idx+1))
tput cup $_line_idx 15
echo "Free: $_free_mib"

echo ""
