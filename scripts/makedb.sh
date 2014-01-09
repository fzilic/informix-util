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

print_usage() {
  echo """Usage $0 -f [*.tar.Z file] -n [name] -r [name] -s [dbspace]
  - mandatory
    -f - source file - a tar compressed database export (*.tar.Z)
    -n - source database name
    -r - rename to
    -s - destination dbspace
    -g - grant dba to group
    -x - abort cleanup
""" >&2
}

if [ "$#" -eq 0 ]; then
  print_usage
  exit 1
fi

_options="f:n:r:s:g:xh"

_source_file=
_source_db_name=
_dest_db_name=
_dest_dbs=
_dba_group=

_abort_clean=

while getopts $_options _option; do
  case $_option in
    f )
      _source_file=$OPTARG
    ;;
    n )
      _source_db_name=$OPTARG
    ;;
    r )
      _dest_db_name=$OPTARG
    ;;
    s )
      _dest_dbs=$OPTARG
    ;;
    g )
      _dba_group=$OPTARG
    ;;
    x )
      _abort_clean="x"
    ;;
    h )
      print_usage
      exit 0
    ;;
    \? )
      echo "Unknown option -$OPTARG" >&2
      print_usage
      exit 1
    ;;
  esac
done

if [ -z "$_source_file" -o -z "$_source_db_name" ]; then
  print_usage
  exit 1
fi

echo $_source_file
echo $_source_db_name
echo $_dest_db_name
echo $_dest_dbs

if [ ! -e "$_source_file" ]; then
  echo "Missing source file" >&2
  exit 1
fi

if [ -e "$_source_db_name.exp" ]; then
  echo """Another import could be running.
Wait for it to complete or delete $_source_db_name.exp directory and re-run.""" >&2
  exit 1
fi

uncompress -c $_source_file | tar xvf - 

if [ "$?" -ne "0" -o ! -e "$_source_db_name.exp" ]; then
  echo "Uncompression failed." >&2
  exit 1
fi

if [ -n "$_dest_db_name" ]; then
  mv $_source_db_name.exp/$_source_db_name.sql $_source_db_name.exp/$_dest_db_name.sql
  mv $_source_db_name.exp $_dest_db_name.exp 
else
  _dest_db_name=$_source_db_name
fi

if [ -z "$_dest_dbs" ]; then 
  echo """WARNING

Importing databse in root databse space."
  read -p "Do you wish to continue Y/[N]? " _cont
else
  _cont='Y'
fi 

if [ "$_cont" = "Y" -o "$_cont" = "y" ]; then
  if [ -n "$_dest_dbs" ]; then
    _dbspace_option="-d $_dest_dbs"
  fi
  
  dbimport $_dest_db_name $_dbspace_option \
  && ontape -s -U $_dest_db_name -t /dev/null
else 
  echo "Aborting import to root databse space." >&2
  exit 1
fi

if [ -n "$_dba_group" ]; then
  ./scripts/grant_dba_to_group.sh $_dest_db_name $_dba_group
fi

echo "UPDATE STATISTICS HIGH" | dbaccess $_dest_db_name

if [ -z "$_abort_clean" ]; then
  rm -r $_dest_db_name.exp
fi
