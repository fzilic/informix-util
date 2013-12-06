#!/bin/ksh

_dirty_read=
_ifmx_configured=
_verbose=
_inc_sys=
_order='d'
_databases=
_format=DMY4/

_options=":dso:f:vh"

_query=

usage() {
  echo """
Usage $0 -d
  -d - use dirty read - useful when trying to list databases during import/export
  -s - include system tables
  -o - order [a/d] - ascending or descending by create time - default descending
  -f - informix DBDATE format - defaults to DMY4/
  -v - verbose
  -h - this help
""" >&2
}

while getopts $_options _option; do
  case $_option in
    d )
      _dirty_read="t'"
      ;;
    s )
      _inc_sys="t"
      ;;
    o )
      case $OPTARG in
        [aA] )
          _order='a'
          ;;
        [dD] )
          _order='d'
          ;;
        * )
          _order='d'
          ;;
      esac
      ;;
    f )
      _format=$OPTARG
      ;;
    v )
      _verbose="t"
      ;;
    h )
      usage 
      exit 0
      ;;
    \? )
      echo "Error. Unknown option: -$OPTARG" >&2
      exit 1
      ;;
    : )
      echo "Error. Missing option argument for -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ -n "$(which dbaccess)" -a -n "$INFORMIXSERVER" ]; then
  _ifmx_configured="t"
elif [ -n "$_verbose" ]; then
  echo "Basic Informix variables not configured" >&2
fi

if [ -n "$_dirty_read" ]; then
  _query="""SET ISOLATION TO DIRTY READ;
"""
fi

_query=$_query"""SELECT TRIM(name) || ':' || created FROM sysdatabases
WHERE 1=1
"""

if [ -z "$_inc_sys" ]; then
  _query=$_query"""AND name NOT LIKE 'sys%'
AND name NOT LIKE 'onpl%'
"""
fi

case $_order in
  a )
    _query=$_query"""ORDER BY created ASC
"""
  ;;
  d )
    _query=$_query"""ORDER BY created DESC
"""
  ;;
  * )
  ;;
esac

if [ -n "$_verbose" ]; then
  echo $_query
fi

export DBDATE=$_format

_databases=($(echo $_query | dbaccess sysmaster 2>/dev/null | sed '/^$/d' | sed 's/(expression) *//g'))

tput clear
tput cup 5 25
tput rev
echo "  D A T A B A S E S  "
tput sgr0

tput cup 8 15
echo "INFORMIX SERVER:"
tput cup 8 40
echo $INFORMIXSERVER
tput sgr0

tput cup 9 15
echo "Executed at:"
tput cup 9 40
echo $(date +%Y"/"%m"/"%d" - "%H":"%m":"%S)
tput sgr0

tput cup 10 15
echo "Hostname:" 
tput cup 10 40
echo $(hostname)
tput sgr0

tput cup 11 15
echo "IP Address:"
tput cup 11 40
echo $(ifconfig  | grep inet | grep -v inet6 | grep -v 127.0.0.1 | awk '{print $2}' | cut -d ":" -f 2)
tput sgr0

tput cup 14 15
tput rev
echo "Name"
tput cup 14 40 
echo "Created"
tput sgr0

_line_idx=16
for _database in ${_databases[@]}; do
  tput cup $_line_idx 15
  echo ${_database%%:*}
  tput cup $_line_idx 40
  echo ${_database##*:}
  ((_line_idx++))
done

echo ""
