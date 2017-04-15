#!/bin/sh

if [ -e "${HOME}/.bash_ps1" ]; then
 . "${HOME}/.bash_ps1"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

#-----------------------
# Global and local to profile
#-----------------------
if [ -z "$SHORTHOSTNAME" ]
 then
 export SHORTHOSTNAME=`hostname`
fi

if [ -z "$LOGNAME" ]
 then
 export LOGNAME=`whoami`
fi

# Remote host configurations
export R_TEMP='d/temp'
export R_PORT=22
export CYGWIN_HOME='d/cygwin/home/'${LOGNAME}

#-----------------------
# History Options
#-----------------------

# Don't put duplicate lines in the history.
export HISTCONTROL=ignoredups

#-----------------------
# Aliases
#-----------------------
alias ll='ls -l'                              # long list
alias dirs='dirs -v'
alias df='df -h'
alias du='du -h'
alias http='python -m SimpleHTTPServer'
# Interactive operation ...
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias ..='cd ..'
alias path='echo -e ${PATH//:/\\n}'
alias h='history'
alias j='jobs -l'
alias r='rlogin'
alias lt='ls -ltr'              # sort by date
alias tree="ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'"
# spelling typos :)
alias xs='cd'
alias vf='cd'
alias moer='more'
alias moew='more'
alias moze='more'
alias kk='ll'
alias cs='cd `pwd | sed s,^/genoff\.,/src/,`'
alias cb='cd `pwd | sed s,^/src/,/genoff\.,`'
alias p4mad="p4 dirs //depot/v3.1.build.* | grep mad | awk -F'/' '{print $4}' | xargs -i echo //depot/{}/... //jmkhael-win7-fr/{}/..."
#-----------------------
# Prompt and coloring
#-----------------------
# Define some colors first:
# No colors for AIX for the time being
case "`uname`" in
  AIX)
  ;;
  *)
red='\e[0;31m'
RED='\e[1;31m'
blue='\e[0;34m'
BLUE='\e[1;34m'
cyan='\e[0;36m'
CYAN='\e[1;36m'
NC='\e[0m'              # No Color
  ;;
esac

function shellinabox
{
  ~/shellinaboxd -t -b --no-beep
}

function eligible
{ 
if [ $# -ne 1 ]
  then
    echo usage $FUNCNAME "branch";
    echo e.g: $FUNCNAME v3.1.build.merge.14233.pac 
  else
    BRANCH=$1;
    p4 changes //depot/$BRANCH/... | grep -v builder | awk '{print $2}' | xargs -i p4 describe -s {} | grep "//depot/" > f.out; grep hbm.xml f.out & grep java f.out & grep DTD f.out;
  fi
}

function prompt
{
return
  # Change the prompt
  PROMPT_COLOR='0;36m'
  case $1 in
        SunOS*)
  PS1='\[\e]1;\h\a\e]2;\h:${PWD}\a\
\e[${PROMPT_COLOR}\][\u@\h:\w]\n \!\$ \[\e[m\]'
        ;;
        CYGWIN*)
  PS1='\[\e]1;\h\a\e]2;\h:${PWD}\a\
\e[${PROMPT_COLOR}\][\u@\h \w]\n \!\$ \[\e[m\]'
        ;;
        AIX)
  PS1='[\u@\h \w]\n \!\$ '
        ;;
        *)
   export PS1="\[\033[38;5;247m\]\d\[$(tput sgr0)\]\[\033[38;5;15m\] \T :: \[$(tput sgr0)\]\[\033[38;5;32m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput sgr0)\]\[\033[38;5;9m\]\H\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;135m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]\n \[$(tput sgr0)\]\[\033[38;5;208m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
        ;;
  esac
}

function exportDlls
{
  if [ $# -ne 2 ]
  then
    echo usage $FUNCNAME "branch osname";
    echo e.g: $FUNCNAME v3.1.22.buffer.12112-1568348-110330-0942-940122 SunOS-x86-5.10
  else
     branch=$1
     osname=$2
     dlls=$(find /genoff.new/$branch -name '*.so.*')
     pushd /src/new/$branch/progs/mxnodll
     for dll in `zlink @mxpure | grep "Couldn't resolve library name" | awk '{print $8}' | sort -u` ; do
       echo Configuring $dll
       OLD_IFS="$IFS";
       IFS=" ";
       dll_directory=`echo $dlls | grep $dll | xargs -i dirname {}`;
       if [ "$dll_directory" != "" ]
       then
         echo Dll directory $dll_directory;
         export LOCAL_LD_LIBRARY_PATH=$dll_directory:$LOCAL_LD_LIBRARY_PATH;
       else
         echo Could not configure: $dll;
       fi
       IFS="$OLD_IFS";
     done;
     export LD_LIBRARY_PATH=$LOCAL_LD_LIBRARY_PATH:$LD_LIBRARY_PATH;
     popd

     for dir in `ls /src/new/$branch/thirdparty/`; do
        export LD_LIBRARY_PATH=/src/new/$branch/thirdparty/$dir/dist/release/$osname/lib:$LD_LIBRARY_PATH;
     done;

   fi
}


#-----------------------
# Display
#-----------------------
function disp
{
  if [ "$1" != "" ]
  then
    DISPLAY=$1;
  else
    if [ -z $DISPLAY ]; then
      if [ "$LOGNAME" != "$SHORTHOSTNAME" ]; then 
          # Display on remote host
	  DISPLAY=${LOGNAME}.fr.murex.com:1.0
      else		
          # Display on local host
	  DISPLAY=":1.0"
      fi
    fi
  fi

  export DISPLAY

  if [ ! -z "$PS1" ]; then
    echo -e "${CYAN}Display on ${RED}$DISPLAY $NC"
  fi
}

# function to run upon exit of shell
# function _exit()
# {
# }
# trap _exit EXIT

#-----------------------
# Developper helpers
#-----------------------
function src
{
   pushd /src/work/$LOGNAME/$*;
}

function genwork
{
   pushd /genwork/$LOGNAME/$*;
}

function portUsed
{
if [ $# -ne 1 ]
  then
    usage $FUNCNAME "portnumber";
    echo e.g: $FUNCNAME '7777'
  else
   lsof -i:$1
  fi
}

function findPid
{
  if [ $# -ne 2 ]
  then
    usage $FUNCNAME "processname grepregex";
    echo e.g: $FUNCNAME mx  'jmkhael.*TRADEREPO'
  else
     processName=$1
     regex=$2
     # Searching for pid of process $processName, applying regex $regex ...
     pid=`ps | egrep $processName | egrep $regex | egrep -v 'grep' | awk '{ print $2 }'`
     if [ "$pid" != "" ]
     then
       secondPid=`echo $pid | awk '{ print $2 }'`
       if [ "$secondPid" != "" ]
       then
         # Several pids found: $pid
	 # Please check the regex
	 echo "0";
       else       
         # Process id: $pid
	 echo $pid;
       fi
     else
       echo "0";
     fi
  fi
}

function attachDbx
{
  DBX=/nettools/sunstudio/sunstudio12/SUNWspro/bin/dbx

  if [ $# -ne 3 ]
  then
    usage $FUNCNAME "processname pid sourceServer";
    echo e.g: $FUNCNAME mx 12345 triton
  else
    process=$1
    pid=$2
    srcServer=$3
    pathMap="pathmap /$srcServer/production /net/$srcServer/$srcServer/production"
    #$DBX -c "history 100;ignore USR1;ignore USR2;stop in evsSrvMainCallBack -if iMessage==4;$pathMap;cont;stop in \`mx\`uxsystem.c\`Sys_GetMessage;status;cont;stop in pthread_cond_timedwait;" $process $pid
    $DBX -c "history 100;ignore USR1;ignore USR2;stop in evsSrvMainCallBack -if iMessage==4;$pathMap;" $process $pid
  fi
}

function attach
{
  if [ $# -ne 3 ]
  then
    usage $FUNCNAME "processname grepregex sourceServer";
    echo e.g: $FUNCNAME mx 'jmkhael.*TRADEREPO' triton
  else
     processName=$1
     regex=$2
     srcServer=$3
     
     echo Calling findPid $processName $regex
     pid=`findPid $processName $regex`
     if [ $pid -ne 0 ]
     then
       echo Attaching process $processName with pid: $pid, source on: $sourceServer
       attachDbx $processName $pid $sourceServer
     else
       echo process not found!
     fi
  fi
}

function pollAttach
{
  if [ $# -ne 3 ]
  then
    usage $FUNCNAME "processname grepregex sourceServer";
    echo e.g: $FUNCNAME mx 'jmkhael.*TRADEREPO' triton
  else
    processName=$1
    regex=$2
    sourceServer=$3

    echo -ne Polling $processName...
    pid=`findPid $processName $regex`;
    while [ $pid -eq 0 ]
    do
      sleep 1;
      echo -ne ".";
      pid=`findPid $processName $regex`;
    done
 
    if [ ! -z $pid ]
    then
      echo "found PID $pid"
      attachDbx $processName $pid $sourceServer;
    fi
  fi
}

function poll
{
  if [ $# -ne 2 ]
  then
    usage $FUNCNAME "predicate action";
    echo "poll till the predicate condition is non zero";
    echo "predicate: condition for exiting the polling";
    echo "action: action to execute when the condition is reached";
    echo e.g: $FUNCNAME "'findPid mx jmkhael.*TRADEREPO' 'echo pid found!'";
  else
    condition=$1;
    action=$2;
    
    status=`$condition`;

    while [ $status -eq 0 ]
    do
      sleep 1;
      status=`$condition`;
    done
 
    if [ ! -z $status ]
    then
      #echo "Condition met: $condition, executing $action...";
      $action;
    fi
  fi
}

function pollXargsEnd
{
  if [ $# -ne 2 ]
  then
    usage $FUNCNAME "predicate action";
    echo "poll till the predicate condition is non zero, the action is called with parameter the result from the condition";
    echo "predicate: condition for exiting the polling";
    echo "action: action to execute when the condition is reached";
    echo e.g: $FUNCNAME "'findPid mx jmkhael.*TRADEREPO' 'echo pid found: '";
  else
    condition=$1;
    action=$2;
    
    status=`$condition`;

    while [ $status -eq 0 ]
    do
      #echo -ne ".";
      sleep 1;
      status=`$condition`;
    done
 
    if [ ! -z $status ]
    then
      #echo "Condition met: $condition, executing...";
      $action $status;
    fi
  fi
}

function prepare4Rational
{
  if [ $# -ne 2 ]
  then
    usage $FUNCNAME "version destination";
    echo e.g: $FUNCNAME v3.1.build-724077-080220-1037-228042 hp016srv:/hp016srv2/apps/qa10037_TPK0000378_586250
  else
     echo preparing for rational
     version=$1
     destination=$2
     
     \rm /genoff.new/$version/progs/jniproc/exe/jniproc
     pushd /src/new/$version/progs/jniproc
     zcomp -debug
     zlink -debug
     
     \rm /genoff.new/$version/progs/mxnodll/exe/mxpure
     pushd /src/new/$version/progs/mxnodll
     zcomp -debug @mxpure
     zlink -debug @mxpure
     
     copyRational $version $destination
  fi
   
}

function copyRational
{
  if [ $# -ne 2 ]
  then
    usage $FUNCNAME "version destination";
    echo e.g: $FUNCNAME v3.1.build-724077-080220-1037-228042 hp016srv:/hp016srv2/apps/qa10037_TPK0000378_586250
  else
     echo copying rational...
     version=$1
     destination=$2

     echo copying jniproc...
     scp /genoff.new/$version/progs/jniproc/exe/jniproc $destination

     echo copying mxpure...
     scp /genoff.new/$version/progs/mxnodll/exe/mxpure $destination

     echo copying purifycache...
     scp -r /genoff.new/$version/progs/mxnodll/o/purifycache $destination
  fi
   
}

function diffsort
{
  diff <(sort $1) <(sort $2)
}

#-----------------------
# profile management
#-----------------------
function reload
{
   su - $LOGNAME;
}

function rebash
{
   source ~/.bashrc;
}

# Push profile on developper cygwin home
function pushprofile
{
  scp -qP $R_PORT ~/.bash_profile ~/.bashrc $LOGNAME@$LOGNAME:/mnt/$CYGWIN_HOME;
}

function replace_synched
{
  difference=`diff $1 $1_synched`
  if [ "$difference" != "" ]
  then
   echo -e "Difference found:\n$difference";
   
   if ask "Replace current $1?"
   then
     \mv $1_synched $1
   else
     \rm $1_synched
   fi
  else
   echo "$1 up to date"
   \rm $1_synched
  fi
}

# Sync profile from developper cygwin home
function syncprofile
{
   if ask "Sync the .bash_profile?"
   then
     echo "Synching .bash_profile ...";
     scp  -qP $R_PORT $LOGNAME@$LOGNAME:/mnt/$CYGWIN_HOME/.bash_profile ~/.bash_profile_synched
     replace_synched ~/.bash_profile
   fi
     
   if ask "Sync the .bashrc?"
   then
     echo "Synching .bashrc ...";
     scp  -qP $R_PORT $LOGNAME@$LOGNAME:/mnt/$CYGWIN_HOME/.bashrc ~/.bashrc_synched
     replace_synched ~/.bashrc
   fi
}

#-----------------------
# General helpers
#-----------------------
# Nedit is always a background task
function nedit
{
  NEDIT=`which nedit`
  $NEDIT $* &
}

# Usage syntax coloring helper
function usage
{
  echo -e "${RED}usage: ${BLUE}$1 ${CYAN}$2${NC}";
}

# Get a y/n answer and return 1 if yes, 0 if no
function ask()
{
    echo -n "$@" '[y/n] ' ; read ans
    case "$ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
}

# Remote execution
function rexec
{
  ssh -p $R_PORT $LOGNAME@$LOGNAME "$*";
}

# get current host related info
function ii
{
  # only run if we have an interactive shell
  if [ ! -z "$PS1" ]; then
    echo -e "\nIt is:$NC " ; date
    echo -e "\nYou are logged on ${RED}$SHORTHOSTNAME"
    echo -e "\nAdditionnal information:$NC " ; uname -a
    echo -e "\n${RED}Users logged on:$NC " ; w -h
    echo -e "\n${RED}Current date :$NC " ; date
    echo -e "\n${RED}Machine stats :$NC " ; uptime
    
    if [ -x /usr/bin/free ]
    then
      echo -e "\n${RED}Memory stats :$NC " ; free
    fi
    
    echo -e "\n${CYAN}This is BASH ${RED}${BASH_VERSION%.*}${NC}\n"
  fi
}

#-----------------------------------
# File & strings related functions:
#-----------------------------------
# Find a file with a pattern in name:
function ff()
{
  find . -type f -iname '*'$*'*' -ls ;
}

# Find a file with pattern $1 in name and Execute $2 on it:
function fe()
{
  find . -type f -iname '*'$1'*' -exec "${2:-file}" {} \;  ;
}

# find pattern in a set of files and highlight them:
function fstr()
{
    OPTIND=1
    local case=""
    local usage="fstr: find string in files.
Usage: fstr [-i] \"pattern\" [\"filename pattern\"] "
    while getopts :it opt
    do
        case "$opt" in
        i) case="-i " ;;
        *) echo "$usage"; return;;
        esac
    done
    shift $(( $OPTIND - 1 ))
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return;
    fi
    local SMSO=$(tput smso)
    local RMSO=$(tput rmso)
    for f in `find . -type f -name "${2:-*}"`;
    do
     count=`grep -c "$1" $f`
     if [ $count -gt 0 ]; then
       echo $f;
       grep -sn ${case} "$1" $f
     fi
    done
}

#-----------------------
# Files transfer
#-----------------------

# Push file on developper machine
function pushfile
{
  if [ $# -ne 2 ]
  then
    usage $FUNCNAME "source destination";
  else
    scp -qP $R_PORT $1 $LOGNAME@$LOGNAME:/mnt/$2;
  fi
}

# Gzip file or path
function gzipfile
{
  if [ $# -ne 1 ]
  then
    usage $FUNCNAME "source"
  else
    tar -cf $1.tar $1;
    gzip $1.tar
  fi
}

# Push the file to the developper machine, but zip it first
function pushzipped
{
  if [ $# -ne 2 ]
  then
    usage $FUNCNAME "source destination";
  else
    gzipfile $1
    pushfile $1.tar.gz $2;
    \rm $1.tar.gz
   fi
}

# Push the file to the developper machine, but zip it first with respect to IBM convention
function pushzippedibm
{
  if [ $# -ne 2 ]
  then
    usage $FUNCNAME "source destination";
  else
    gzipfile $1
    mv $1.tar.gz 72896.660.706.$1.tar.gz
    pushfile 72896.660.706.$1.tar.gz $2
    \rm 72896.660.706.$1.tar.gz
  fi
}

# Find all the executables in the current directory
function findexecutable
{
  find . -perm -u+x ! -type d;
}

function findjarexportingpackage
{
 if [ $# -ne 1 ]
  then
    usage $FUNCNAME "package";
  else
   IFS=$'\n';
   package=$1
   for f in `find . | grep "\.jar$"`;
   do 
     found=`jar tf $f | grep $package | wc -l`;

     if [ $found -gt 0 ];
     then
       echo "$f contains $package";
       jarsigner -verify $f
     fi
   done
fi

}

#-----------------------
# Entry point
# Platform specific
#-----------------------
case "`uname`" in
  CYGWIN*)
  
  # Don't use ^D to exit unless for me :D
  if [ `whoami` != "jmkhael" ]; 
  then
   set -o ignoreeof
  fi

  if [ `ps -eaf | grep bin/XWin | wc -l` -eq 0 ]; 
  then
   startxwin.bat > /dev/null &
  fi

  # Programming
  alias mscomp='mscomp.bat'
  alias mslib='mslib.bat'
  alias mslink='mslink.bat'
  
  # Coloring output
  alias ls='ls -hF --color'
  alias grep='grep --color'
  alias dir='ls --color=auto --format=vertical'
  
function settitle() { echo -n "^[]2;$@^G^[]1;$@^G"; }
function emed() { cygstart emed `cygpath -w $1`; }

export VISUAL='emed'

# Perforce related functions
function p4
{
  P4=`which p4`
  "$P4" -d $(cygpath -w $PWD) $*;
}

function remote
{
 X :1 -from 172.21.29.44 -query $1 &
}

  # Set the prompt
  prompt CYGWIN
   ;;
  SunOS)

  alias ps='/usr/ucb/ps -auxwww'

  # Display some machine info
  ii
  # Set display
  disp
  
  # Set the prompt
  prompt SunOS
  ;;
  Linux)
  # Display some machine info
  ii
  # Set display
  disp
  # Set the prompt
  prompt Linux
  ;;
  AIX)
  # Display some machine info
  ii
  # Set display
  disp
  # Set the prompt
  prompt AIX
  ;;
  HP-UX)
  # Display some machine info
  ii
  # Set display
  disp
  
  # Set the prompt
  prompt HP-UX
  ;;
esac

PATH=`echo $PATH | sed -e 's/:\/usr\/local\/java\/jdk1.7.0_79\/bin//'`
