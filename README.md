Top-memory
==========

This bash script measures various memory extrema using `top` on a
GNU/Linux platform (especially Debian 9). You may use and distribute
it under the terms of the Apache licence version 2 or any newer
version.


Usage
-----

top-memory.sh [*options*] *command*


Principle
---------

The script runs the *command* with its standard output redirected to
`/dev/null`, traces its process identificator with `top`, and displays
on standard output various statistics parametered with *options*.


Options
-------

### --help

Display a summary of commands on standard output and exit.

### -*FIELD* , +*FIELD*

Display the statistics obtained from `top` at a time where *FIELD* is
minimal (respectively maximal).

You may repeat these options with various values for *FIELD*,
separated by spaces. In that case, output lines will be in the same
order as the options you have provided.

If you do not provide any of them, a default of `+RES` is assumed.

*FIELD* can take one of there values:

* `VIRT`: whole virtual memory (codes, data, shared libs, swapped
	      pages, mapped unused pages) (in Kio)
* `RES`:  physical memory the application has used (in Kio)
* `SHR`:  shared memory (in Kio)

**Beware** yet that in the script, the output of `top` is filtered with
the column number, not their names. Depending on your configuration
for `top`, columns may not be ordered in the same fashion than on my
system. In that case, you will have to edit the source code.

### -o *file*

Write statistics to *file* instead of the standard output.

This option has the side effect on redirecting your *command*'s output
to standard output, and preventing error messages of my script to be
displayed.

If not specified, the standard output of your command is redirected to
`/dev/null`, and statistics and error messages from my script are
directed to standard output.

Standard error ouput from your command is never redirected, and some
commands in my script may also print messages on it.

### --

End of options. All following arguments are considered part of your
command.

You will want to use this option if your command begins with a `-` or
`+`.


Exit codes
----------

	1 /usr/bin/top program is missing
	2 Unknown option provided
	3 Programmation error: this should not happen, please report a
	  bug.


Example
-------

    bash top-memory.sh +VIRT +RES +SHR firefox-esr https://duckduckgo.com


Known bugs and implementation notes
-----------------------------------

There is a race condition between the shell where the *command* is
launched and the shell where the listening `top` process is
launched. At the end of *command*, `top` process is killed. So, if
*command* ends very quickly, the script will try to kill `top` (and
silently fail) before `top` process will be created. At the end, the
`top` process will still be running and accessing the temporary data
file where statistics get stored (but not actually writing anything
because the output of `sed` will be empty). To prevent the situation
where *command* fails immediately, a small delay has been
introduced.

*command* is not protected for spaces. Thus, even if you give it as a
string to my program, each word will be considered separately. I
cannot imagine a situation where it is a problem.

The script uses some modern bash specific features, like an array, so
it might not work with other interpreters.


Licencing
---------

This software is licensed under the Apache License, Version 2.0 (the
"License"); you may not use it except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an **"as is" basis,
without warranties or conditions of any kind**, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

This software has been developed during my research internship at the
Technical University of Vienna.
