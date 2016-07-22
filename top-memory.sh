#!/bin/bash
#
# Copyright 2016 Alban Kraus
# firstname.name@gmail.com
# Intern at the Institute for Geoinformation
# Technische Universität
# Gußhausstraße 27-29/E120
# 1040 Wien
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# top-memory
#
# This programs measures the maximal memory used by a process.
#
# Table of contents:
#  34: function print_help
#  73: dependency check
#  78: constants and parameters
#  89: commandline parsing
# 131: main code
# 170: display statistics

function print_help {
	cat <<EOF

Usage: $1 [options] command

Run the *command* with its standard output redirected to /dev/null,
trace its PID with top, and display on standard output various
statistics parametered with *options*.

Options:
--help          Display this summary.
-FIELD , +FIELD Display the line with minimal (resp. maximal) FIELD.
                (defaults to +RES)
-o file         Do not inhibate command's standard output and write
                statistics to *file*.
--              End of options (when *command* begins with - or +).

FIELD can be:
	VIRT: whole virtual memory (codes, data, shared libs, swapped
	      pages, mapped unused pages) in Kio
	RES:  physical memory application has used in Kio
	SHR:  shared memory in Kio

Warning: top output is filtered according to column order; depending
on your top configuration, field names above may not match their
order.

Exit codes:
	1 /usr/bin/top program is missing
	2 Unknown option provided
	3 Programmation error: this should not happen, please report a
	  bug.

Known bugs: See ${1}.bugs

© 2016 Alban Kraus <kraus@geoinfo.tuwien.ac.at>
EOF
}

# Dependencies
if [ ! -x /usr/bin/top ] ; then
	exit 1
fi

# Program constants
TOPPID=/var/run/user/$(id -u)/top-memory
STATS=/var/run/user/$(id -u)/top-memory.stats


# Program parameters
display=( +RES )
output=
inhibit=


# Command line
THIS=$0
dindex=0
while [ $# -gt 0 ] ; do
	case $1 in
		--help)
			print_help $THIS
			exit 0
			;;
		--)
			shift
			break
			;;
		-o)
			shift
			output="> $1"
			;;
		-VIRT | -RES | -SHR | +VIRT | +RES | +SHR)
			display[$dindex]=$1
			((dindex++))
			;;
		-* | +*)
			if [ -z $output ] ; then
				echo "Unknown option provided: $1"
			fi
			exit 2
			;;
		*)
			break
			;;
	esac
	shift
done
unset dindex
unset THIS


# Post-defaults
if [ -z $output ] ; then
	inhibit="> /dev/null"
fi

# Running application
DEBUG="--verbose -s"
cat <<EOF | bash
	# This script will become the command
	cat <<END | bash | sed -n -e "/^ *\$\$/p" > $STATS &
		# This script will become the top command
		echo \\\$\\\$ > $TOPPID
		LC_ALL=C exec top -b -d 0.1 -p \$\$
		# because of float       ^
END
	$inhibit exec $@
EOF

#   # This script will become the command
#   cat <<END | bash | sed -n -e "/^ *$$/p" > top-memory.stats &
#		# This script will become the top command
#		echo \$\$ > top-memory
#		LC_ALL=C exec top -b -d 0.1 -p $$
#		# because of float       ^
#END
#	> /dev/null exec firefox https://duckduckgo.com

#   cat <<END | bash | sed -n -e "/^ *3778/p" > top-memory.stats &
#		# This script will become the top command
#		echo $$ > top-memory
#		LC_ALL=C exec top -b -d 0.1 -p 3778
#		# because of float       ^
#END
#	> /dev/null exec firefox https://duckduckgo.com

##		echo 3780 > top-memory
##		LC_ALL=C exec top -b -d 0.1 -p 3778

if [ $? -ne 0 ] ; then
	sleep 3s # let enough time for top to launch
fi

kill -SIGINT $(cat $TOPPID) && rm $TOPPID

# Process statistics
dindex=0
while [ -n ${display[$dindex]} ] ; do
	case ${display[$dindex]} in
		-*)
			prog=head
			;;
		+*)
			prog=tail
			;;
		*)
			exit 3
			;;
	esac

	case ${display[$dindex]} in
		*VIRT)
			column=5
			;;
		*RES)
			column=6
			;;
		*SHR)
			column=7
			;;
		*)
			exit 3
			;;
	esac

	cat $STATS \
		| sed -e '/^\(\s*[^\s]*\){4}\s*0\s*0\s*0/d' `# delete invalid results when process is killed` \
		| sort -b -k $column  `# select user's column` \
		| $prog -n 1          `# select the extremum` \
				$output        # pipe it to output file (if any)

	((dindex++))
done
unset column
unset prog
unset dindex

rm $STATS



exit 0
