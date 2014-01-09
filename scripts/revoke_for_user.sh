#
#  Revoke user permission on selected databse or all databases for Informix server
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

_user=
_database=
_all=

_query=

_options=":u:d:a"

usage() {
  echo """
Usage: $0 -u <username> [-d <database> | -a ]
  -u - user to revoke all privileges
  -d - single databse - database name will be converted to lowercase and matched using LIKE operator
  -a - all databases
         Options -a and -d are exclusive, -a overrides -d option
""" >&2
}

while getopts $_options _option; do
  case $_option in
    u )
      _user=$OPTARG
      ;;
    d ) 
      _database=$OPTARG
      ;;
    a ) 
      _all='t'
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

if [ -z "$_user" ]; then
  usage
  echo """ 
User parameter missing""" >&2
  exit 1
fi

if [ -n "$_all" ]; then
  _database=""
elif [ -z "$_database" ]; then
  usage
  echo """
Database parametar not set""" >&2
  exit 1
fi

_database=`echo $_database | awk '{print tolower($0)}'`

_query="SELECT name FROM sysdatabases"

if [ -n "$_database" ]
then
	_query=$_query" WHERE name LIKE '"$_database"'"
else 
	_query=$_query" WHERE name NOT LIKE 'sys%'"
fi

_databaseS=`echo $_query | dbaccess sysmaster 2>/dev/null | sed '/^$/d' | sed 's/name *//g'`

for _db in ${_databaseS[@]}
do
	_perm_type=`echo "SELECT usertype FROM sysusers WHERE username = '$_user'" | dbaccess $_db 2>/dev/null | sed '/^$/d' | sed '/^user/d'`

	if [ -z "$_perm_type" ]
	then
		continue
	fi
	echo "REVOKE DBA FROM $_user; REVOKE RESOURCE FROM $_user; REVOKE CONNECT FROM $_user" | dbaccess $_db
done
