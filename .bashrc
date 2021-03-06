#!/bin/sh

if [ -e "${HOME}/.bash_ps1" ]; then
 . "${HOME}/.bash_ps1"
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
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
alias topmem='top -b -o +%MEM | head -n 22'

cheat() { curl -s "https://raw.githubusercontent.com/cheat/cheatsheets/master/$1"; }
how_in() {   where="$1"; shift;   IFS=+ curl "https://cht.sh/$where/$*"; }

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

#-----------------------
# General helpers
#-----------------------
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
      echo -e "\n${RED}Memory stats :$NC " ; free -h
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

function serviceInStack() {
  service=$1;
  stack_services=$2;
  #echo $service; echo $stack_services;

  if ! (echo ${stack_services[@]} | grep -q -w "$service"); then
    #echo ".";
  #else
    echo "$service is not in any stack";
  fi;
}

function servicesInNoStack() {
  unset stack_services
  IFS=$'\n'; for stack in $(docker stack ls --format {{.Name}}); do stack_services+=($(docker stack services $stack --format {{.Name}})); done
  echo checking in ${stack_services[@]}

  IFS=$'\n'; for service in $(docker service ls --format {{.Name}}); do serviceInStack $service $stack_services; done
}

#-----------------------
# Entry point
# Platform specific
#-----------------------
case "`uname`" in
  SunOS)

  alias ps='/usr/ucb/ps -auxwww'
  ;;
esac

# Display some machine info
#ii
neofetch
# Set display
disp

PATH=`echo $PATH | sed -e 's/:\/usr\/local\/java\/jdk1.7.0_79\/bin//'`

# Add krew to the path
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

complete -cf sudo
complete -cf man

export DOCKER_HOST=tcp://localhost:2375

cd ~
alias work='cd /d/1d-mx/workspace/'
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/johnny/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/johnny/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/johnny/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/johnny/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

source ~/.bash_ps1
alias msfconsole="docker run --rm -it metasploitframework/metasploit-framework ./msfconsole"
alias kali='docker run -it --rm jmkhael/kali'
