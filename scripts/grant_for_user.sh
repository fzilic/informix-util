#
#  Grant user privilege on selected databse or all databases for Informix server
#
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

#_USAGE="Usage: $0 username CONNECT|RESOURCE|DBA [database|all]"

_user=
_access=
_database=
_all=

usage() {
  echo """
Usage: $0 -u <username> -p <privilege> [ -d <database> | -a ] 
  -u - user to grant privilege for
  -p - premission to grant, see <privilege> and examples
  -d - databse to grant privilege on, matches database name in lowercase with LIKE operator
  -a - grant privilege on all databases

  Privilege option
    Single character denoting privilege type, valid options are c C r R d D
    - c|C - connect privilege
    - r|R - resource privilege
    - d|D - dba privilege

  Examples
    Grant connect privilege to user 'demo' on all databases
      ./grant_for_user.sh -u demo -p c -a

    Grant dba privilege to user 'admin' on database 'stores'
      ./grant_for_user.sh -u admin -p D -d stores

    Grant resource privilege to user 'joe' on all database whose name starts with stor
      ./grant_for_user.sh -u joe -p r -d stor%

""" >&2
}

_options=":u:p:d:a"

while getopts $_options _option; do
  case $_option in 
    u )
      _user=$OPTARG
      ;;
    p )
      case $OPTARG in
        [cC] )
          _access="CONNECT"
          ;;
        [rR] )
          _access="RESOURCE"
          ;;
        [dD] )
          _access="DBA"
          ;;
        * )
          usage 
          echo """
Unknown permission type, check usage instructions.
""" >&2
          exit 1
          ;;
      esac
      ;;
    d )
      _database=$OPTARG
      ;;
    a )
      _all='t'
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

if [ -z "$_user" -o -z "$_access" ]; then
  usage
	exit 1
fi

if [ -n "$_all" ]; then
  _database=""
elif [ -z "$_database" ]; then
  usage
  echo """
Database parameter missing""" >&2
  exit 1
fi

_database=`echo $_database | awk '{print tolower($0)}'`

_query="SELECT name FROM sysdatabases"

if [ "$_database" != "all" ]
then
	_query=$_query" WHERE name LIKE '"$_database"'"
else 
	_query=$_query" WHERE name NOT LIKE 'sys%'"
fi

_databases=`echo $_query | dbaccess sysmaster 2>/dev/null | sed '/^$/d' | sed 's/name *//g'`

_grant="GRANT $_access TO $_user"

for _db in ${_databases[@]}
do
	_perm_type=`echo "SELECT usertype FROM sysusers WHERE username = '$_user'" | dbaccess $_db 2>/dev/null | sed '/^$/d' | sed '/^user/d'`

	if [ -n "$_perm_type" ]
	then
    case $_perm_type in 
      D )
        continue
          echo "DBA privilege granted to $_user on $_db"
        ;;
      R )
        if [ "${_access:0:1}" != "D" ]; then
          echo "RESOURECE privilege granted to $_user on $_db"
          continue
        fi
        ;;
      C )  
        if [ "${_access:0:1}" != "D" -a "${_access:0:1}" != "R" ]; then
          echo "CONNECT privilege granted to $_user on $_db"
          continue
        fi
    esac
	fi

  echo "Granting $_access to $_user on $_db" 

  echo $_grant | dbaccess $_db 2>/dev/null
done
