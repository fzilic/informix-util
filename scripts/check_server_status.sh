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

# This script is used to test some of the server performance statistics.

# Be nice, have help option
_help="Informix server performance statistics monitor.
Use this tool to check the possible performance bottlenecks on your server.
	-a	  Check everything
	-b	  Check buffer usage
	-c	  Check read and write hit percentages
	-l	  Check LRU queues by bufwaits ratio
	-h	  Prints this help
	-H	  Same as -h
	-v	  Verbose output. Mostly used to debug the script, and for detailed information.
	--version Prints version information
	Options to be added here
"

# If there are no arguments, put -h on first one and continue

if [ "$#" -eq 0 ]
then
	echo "$_help"
	exit 0
fi 

# Check how we where called

for _param in "$@"
do
	case "$_param" in 
		"-h" )
			echo "$_help"
			exit 0
		;;
		"-H" )
			echo "$_help"
			exit 0
		;;
		"--version" )
			echo "Version #unknown#"
			exit 0
		;;
		"-v" )
			_verbose='t'
		;;
		"-a" )
			_check_buff='t'
			_check_hit_cache='t'
			_check_buf_waits='t'
		;;
		"-b" )
			_check_buff='t'
		;;
		"-c" )
			_check_hit_cache='t'
		;;
		"-l" )
			_check_buf_waits='t'
		;;
		*)
			echo "Invalid option: $_param"
			echo "Usage: $0 [options]"
			echo "For valid options run $0 -h"
			exit 1
		;;
	esac
done

echo "Informix server performance check utility."
echo ""


# Check if Informix is configured correctly

if [ -n "$_verbose" ]
then
	echo -e "\nChecking enviorment varliables"
	echo "INFORMIXDIR="$INFORMIXDIR
	echo "INFORMIXSERVER="$INFORMIXSERVER
	echo "ONCONFIG="$ONCONFIG
	echo "INFORMIXSQLHOSTS="$INFORMIXSQLHOSTS
	echo ""
fi

if [ -z "$INFORMIXDIR" -o -z "$INFORMIXSERVER" -o -z "$ONCONFIG" -o -z "$INFORMIXSQLHOSTS" ]
then
        echo "ERROR"
        echo -e "Informix enviorment variables are not configured!\n"

        exit 1
elif [ -n "$_verbose" ]
then
	echo -e "Enviorment variables OK.\n"
fi

# Check is there onstat program in the path

_ONSTAT_LOC=`which onstat`

if [ -n "$_verbose" ]
then
	echo -e "\nChecking for onstat in path."
	echo "Onstat: $_ONSTAT_LOC"
	echo ""
fi

if [ -z "$_ONSTAT_LOC" -o ! -x "$_ONSTAT_LOC" ]
then
        echo "ERROR"
        echo -e "Unable to find onstat program\n"
	exit 1

elif [ -n "$_verbose" ]
then
	echo -e "\nFound onstat, and it is executable.\n"
fi

# Check if database server is in correct mode

_ONSTAT_STAT=`onstat -`

if [ -n "$_verbose" ]
then
	echo -e "\nChecking for \"onstat -\" output."
	echo "Onstat: $_ONSTAT_STAT"
	echo ""
fi

if [[ "$_ONSTAT_STAT" =~ .*(not initialized).* ]]
then
        echo -e "Database not in valid mode\n"
        exit 1
elif [ -n "$_verbose" ]
then
	echo -e "\nDatabase in valid mode.\n"
fi

# Check how we use our buffers
if [ -n "$_check_buff" ]
then
	_BUFF_STAT=`onstat -P | tail -n 5`

	if [ -n "$_verbose" ]
	then
		echo -e "\nExecuted command \"onstat -P | tail -n 5\" with result:\n"
		echo "$_BUFF_STAT"
		echo ""
	fi

	# If there is more then 5% of buffers in other warn user

	_other_perc=`echo "$_BUFF_STAT" | grep Other | awk '{print $2}'`
	_other_int=`echo "$_other_perc" | sed 's/\..*//'`

	if [ "$_other_int" -gt "5" ]
	then 
		if [ "$_other_int" -gt "50" ]
		then
			echo -e "\nCRITICAL: More then 50% of buffers are free ($_other_perc%).\n"
		else
			echo -e "\nWARNING: More then 5% of buffers are free ($_other_perc%).\n"
		fi
	elif [ -n "$_verbose" ]
	then
		echo -e "\nOK: Less then 5% of buffers if free ($_other_perc%)."
	fi
fi

#Check cached percentages
if [ -n "$_check_hit_cache" ]
then
	_HIT_CACHE=`onstat -p | grep -A 1 cached | awk '{print $4"\t"$8}'`

	_cache_nums=`echo "$_HIT_CACHE" | grep -E [0-9]+.*`

	_read_hit=`echo $_cache_nums | awk '{print $1}'`
	_write_hit=`echo $_cache_nums | awk '{print $2}'`

	if [ -n "$_verbose" ]
	then
		echo -e "\nExecuted command \"onstat -p | grep -A 1 cached\" with result:\n"
		echo "$_HIT_CACHE"
		echo "$_read_hit"
		echo "$_write_hit"
		echo ""
	fi

	_read_hit_int=`echo $_read_hit | sed 's/\..*//'`
	_write_hit_int=`echo $_write_hit | sed 's/\..*//'`

	if [ "$_read_hit_int" -lt "90" ]
	then
		echo -e "\nCRITICAL: Read hit less then 90% ($_read_hit%)."
	elif [ "$_read_hit_int" -lt "95" ]
	then
		echo -e "\nWARNING: Read hit less then 95% ($_read_hit%)."
	elif [ -n "$_verbose" ]
	then
		echo -e "\nOK: Read hit greater then 95% ($_read_hit%)."
	fi


	if [ "$_write_hit_int" -lt "80" ]
	then
		echo -e "\nCRITICAL: Write hit less then 80% ($_write_hit%)."
	elif [ "$_write_hit_int" -lt "90" ]
	then
		echo -e "\nWARNING: Write hit less then 90% ($_write_hit%)."
	elif [ -n "$_verbose" ]
	then
		echo -e "\nOK: Write hit greater then 90% ($_write_hit%)."
	fi
fi

if [ -n "$_check_buf_waits" ]
then
	_ONSTAT_PROFILE=`onstat -p`

	_bufwaits=`echo "$_ONSTAT_PROFILE" | grep -A 1 bufwaits | awk '{print $1}' | grep -E [0-9]+`
	_pagreads=`echo "$_ONSTAT_PROFILE" | grep -A 1 pagreads | awk '{print $2}' | grep -E [0-9]+`
	_bufwrits=`echo "$_ONSTAT_PROFILE" | grep -A 1 bufwrits | awk '{print $7}' | grep -E [0-9]+`

	_buf_formula="($_bufwaits / ( $_pagreads + $_bufwrits ) )*100"


	if [ -n "$_verbose" ]
	then 
		echo -e "\n\"onstat -p\" output"
		echo "$_ONSTAT_PROFILE"
		echo -e "\n"
	
		echo -e "\nParsed values:"
		echo "bufwaits="$_bufwaits
		echo "pagreads="$_pagreads
		echo "bufwrits="$_bufwrits
		echo -e "\n"

		echo -e "\nSource formula stolen from: http://www.informix-dba.com/p/informix-innovator-c-tuning-basics.html#lru_mon"
		echo -e "Source formula: Bufwaits Ratio (BR) = (bufwaits / (pagreads + bufwrits)) * 100\n"

		echo -e "\nFormula before calculation"
		echo $_buf_formula
		echo -e "\n"
	fi

	_buf_result=`echo "scale=6; $_buf_formula" | bc -q 2>/dev/null`
	_buf_result_int=`echo $_buf_formula | bc -q 2>/dev/null`

	if [ "$_buf_result_int" -gt "15" ]
	then
		echo -e "\nCRITICAL: Buffer wait ratio greater then 15% ($_buf_result%)"
	elif [ "$_buf_result_int" -gt "7" ]
	then
		echo -e "\nWARNING: Buffer wait ratio greater then 7% ($_buf_result%)"
	elif [ -n "$_verbose" ]
	then
		echo -e "\nOK: Buffer wait ratio less then 7% ($_buf_result%)"
	fi
fi
