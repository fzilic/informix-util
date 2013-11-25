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
tput cup 5 17
tput rev
echo "  D A T A B A S E S  "
tput sgr0

tput cup 7 15
echo "Name"
tput cup 7 40 
echo "Created"

_line_idx=8
for _database in ${_databases[@]}; do
  tput cup $_line_idx 15
  echo ${_database%%:*}
  tput cup $_line_idx 40
  echo ${_database##*:}
  ((_line_idx++))
done

echo ""
