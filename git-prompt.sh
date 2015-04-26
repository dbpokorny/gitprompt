
# don't set prompt if this is not interactive shell
# it is better if this test is done before git-prompt.sh is sources for performance reasons. 
[[ $- != *i* ]] && return

##################################################################### CONFIG

	# dir, rc, root color 
	if [ 0`tput colors` -ge 8 ];  then				#  if terminal supports colors
		dir_color='BLUE'
		rc_color='red'
		root_id_color='magenta'
	else											#  only B/W
		dir_color='bw_bold'
		rc_color='bw_bold'
	fi

	# arrows color
	      arrows_color=green

	# vcs state colors
		 init_vcs_color=WHITE     # initial
		clean_vcs_color=blue      # nothing to commit (working directory clean)
	     modified_vcs_color=red       # Changed but not updated:
		added_vcs_color=green     # Changes to be committed:
		mixed_vcs_color=yellow    # 
	    untracked_vcs_color=blue      # Untracked files:
		   op_vcs_color=MAGENTA
	     detached_vcs_color=RED

	max_file_list_length=40

	#####################################################################  post config

	################# terminfo colors-16
	#
	#  	black?    0 8			  
	#	red       1 9
	#	green     2 10
	#	yellow    3 11
	#	blue      4 12
	#	magenta   5 13
	#	cyan      6 14
	#	white     7 15
	#
	#	terminfo setaf/setab - sets ansi foreground/background
	#	terminfo sgr0 - resets all attributes
	#	terminfo colors - number of colors
	#
	#################  Colors-256
	#  To use foreground and background colors from the extension, you only
	#  have to remember two escape codes:
	#       Set the foreground color to index N:    \033[38;5;${N}m
	#       Set the background color to index M:    \033[48;5;${M}m
	# To make vim aware of a present 256 color extension, you can either set
	# the $TERM environment variable to xterm-256color or use vim's -T option
	# to set the terminal. I'm using an alias in my bashrc to do this. At the
	# moment I only know of two color schemes which is made for multi-color
	# terminals like urxvt (88 colors) or xterm: inkpot and desert256, 

	### if term support colors,  then use color prompt, else bold

              black='\['`tput sgr0; tput setaf 0`'\]'
                red='\['`tput sgr0; tput setaf 1`'\]'
              green='\['`tput sgr0; tput setaf 2`'\]'
             yellow='\['`tput sgr0; tput setaf 3`'\]'
               blue='\['`tput sgr0; tput setaf 4`'\]'
            magenta='\['`tput sgr0; tput setaf 5`'\]'
               cyan='\['`tput sgr0; tput setaf 6`'\]'
              white='\['`tput sgr0; tput setaf 7`'\]'

              BLACK='\['`tput setaf 0; tput bold`'\]'
                RED='\['`tput setaf 1; tput bold`'\]'
              GREEN='\['`tput setaf 2; tput bold`'\]'
             YELLOW='\['`tput setaf 3; tput bold`'\]'
               BLUE='\['`tput setaf 4; tput bold`'\]'
            MAGENTA='\['`tput setaf 5; tput bold`'\]'
               CYAN='\['`tput setaf 6; tput bold`'\]'  # why 14 doesn't work?
              WHITE='\['`tput setaf 7; tput bold`'\]'

            bw_bold='\['`tput bold`'\]'
               bell=`tput bel`

       colors_reset='\['`tput sgr0`'\]'

	# Workaround for UTF readline(?) bug. Disable bell when UTF
	locale |grep -qi UTF && bell=''	


	# replace symbolic colors names to raw treminfo strings
		 init_vcs_color=${!init_vcs_color}
	     modified_vcs_color=${!modified_vcs_color}
	    untracked_vcs_color=${!untracked_vcs_color}
		clean_vcs_color=${!clean_vcs_color}
		added_vcs_color=${!added_vcs_color}
		   op_vcs_color=${!op_vcs_color}
		mixed_vcs_color=${!mixed_vcs_color}
	     detached_vcs_color=${!detached_vcs_color}

	##################################################################### 

	# echo "*** /etc/prompt  on A,  TERM=$TERM"
	unset PROMPT_COMMAND

	#######  work around for MC bug
	if [ -z "$TERM" -o "$TERM" = "dumb" -o -n "$MC_SID" ]; then
		unset PROMPT_COMMAND
		PS1='\w> '
		return 0
	fi

	export who_where


set_shell_title() { 

	xterm_title() { echo  -n "]2;${@}" ; }

	screen_title() { 
		# FIXME: run this only if screen is in xterm (how to test for this?)
		xterm_title  "sCRn  $plain_who_where $@" 

		# FIXME $STY not inherited though "su -"
		[ "$STY" ] && screen -S $STY -X title "$@"
	}

	case $TERM in

		screen*)                                                    
			screen_title "$@"
			;;

		xterm* | rxvt* | gnome-terminal | konsole | eterm | wterm )       
			xterm_title  "$plain_who_where $@"
			;;

		*)                                                     
			;;
	esac
 }

    export -f set_shell_title

###################################################### ID (user name)
	id=`id -un`

########################################################### TTY
	tty=`tty`
	tty=`echo $tty | sed "s:/dev/pts/:p:; s:/dev/tty::" `		# RH tty devs	
	tty=`echo $tty | sed "s:/dev/vc/:vc:" `				# gentoo tty devs

	if [[ "$TERM" = "screen" ]] ;  then

		#	[ "$WINDOW" = "" ] && WINDOW="?"
		#	
		#		# if under screen then make tty name look like s1-p2
		#		# tty="${WINDOW:+s}$WINDOW${WINDOW:+-}$tty"
		#	tty="${WINDOW:+s}$WINDOW"  # replace tty name with screen number
		tty="$WINDOW"  # replace tty name with screen number
	fi

	# we don't need tty name under X11
	case $TERM in
		xterm* | rxvt* | gnome-terminal | konsole | eterm | wterm )  unset tty ;;
		*);;
	esac

	dir_color=${!dir_color}
	arrows_color=${!arrows_color}
	rc_color=${!rc_color}
	root_id_color=${!root_id_color}

	########################################################### HOST
	### we don't display home host/domain  $SSH_* set by SSHD or keychain

	# How to find out if session is local or remote? Working with "su -", ssh-agent, and so on ? 
	## is sshd our parent?
	# if 	{ for ((pid=$$; $pid != 1 ; pid=`ps h -o pid --ppid $pid`)); do ps h -o command -p $pid; done | grep -q sshd }
	#then 
    host=macbook
    host_color=$BLUE

	color_who_where="${id:+$id@}$host_color$host${tty:+ $tty}"
	plain_who_where="${id:+$id@}$host"
	
	# remove trailing "@" if any
	color_who_where="${color_who_where%@}"
	plain_who_where="${plain_who_where%@}"
	
	# add trailing " "
	color_who_where="$color_who_where "
	plain_who_where="$plain_who_where "
	
	# if  $who_where==" "  then  who_where=""
	color_who_where="${color_who_where## }"
	plain_who_where="${plain_who_where## }"
	
	
	# if root then highlight who_where
	if	[ "$id" == "root" ]  ; then 
	    color_who_where="$root_id_color$color_who_where$colors_reset"
	fi

parse_git_dir() {

        git_dir=`git rev-parse --git-dir 2> /dev/null`

        [[ -n ${git_dir/./} ]]  ||  return  1

        vcs=git

        ##########################################################   GIT STATUS
        unset status modified added clean init added mixed untracked op detached arrows
        eval `
                git status 2>/dev/null |
                    sed -n '
                        s/^On branch /branch=/p
                        s/^nothing to commit, working directory clean/clean=clean/p
                        s/^Your branch is behind.*/arrows="[vv] "/p
                        s/^Your branch is ahead of.*/arrows="[^^] "/p
                        s/^Your branch and .*have diverged.*/arrows="[<>] "/p
                        s/^Initial commit/init=init/p
                        /^Untracked files:/,/^[^#]/{
                            s/^Untracked files:/untracked=untracked;/p
                            s/^	\([^.]\)/untracked_files[${#untracked_files[@]}+1]=\"\1\"/p   
                        }
                        /^Changed but not updated:/,/^# [A-Z]/ {
                            s/^Changed but not updated:/modified=modified;/p
                            s/^	modified:   \([^.]\)/modified_files[${#modified_files[@]}+1]=\"\1\"/p
                            s/^	unmerged:   \([^.]\)/modified_files[${#modified_files[@]}+1]=\"\1\"/p
                        }
                        /^Changes not staged for commit:/,/^# [A-Z]/ {
                            s/^Changes not staged for commit:/modified=modified;/p
                            s/^	modified:   \([^.]\)/modified_files[${#modified_files[@]}+1]=\"\1\"/p
                            s/^	unmerged:   \([^.]\)/modified_files[${#modified_files[@]}+1]=\"\1\"/p
                        }
                        /^Changes to be committed:/,/^# [A-Z]/ {
                            s/^Changes to be committed:/added=added;/p
                            s/^	modified:   \([^.]\)/added_files[${#added_files[@]}+1]=\"\1\"/p
                            s/^	new file:   \([^.]\)/added_files[${#added_files[@]}+1]=\"\1\"/p
                            s/^	renamed:[^>]*> \([^.]\)/added_files[${#added_files[@]}+1]=\"\1\"/p
                            s/^	copied:[^>]*> \([^.]\)/added_files[${#added_files[@]}+1]=\"\1\"/p
                        }
                    ' 
        `

        if  ! grep -q "^ref:" $git_dir/HEAD  2>/dev/null;   then 
            detached=detached
        fi

        ### OP 
        unset op
        
        if [[ -d "$git_dir/.dotest" ]] ;  then

            if [[ -f "$git_dir/.dotest/rebasing" ]] ;  then
                op="rebase"

            elif [[ -f "$git_dir/.dotest/applying" ]] ; then
                op="am"

            else
                op="am/rebase"

            fi

        elif  [[ -f "$git_dir/.dotest-merge/interactive" ]] ;  then
            op="rebase -i"
            # ??? branch="$(cat "$git_dir/.dotest-merge/head-name")"

        elif  [[ -d "$git_dir/.dotest-merge" ]] ;  then
            op="rebase -m"
            # ??? branch="$(cat "$git_dir/.dotest-merge/head-name")"
            
        # lvv: not always works. Should  ./.dotest  be used instead?
        elif  [[ -f "$git_dir/MERGE_HEAD" ]] ;  then
            op="merge"
            # ??? branch="$(git symbolic-ref HEAD 2>/dev/null)"
            
        else
            [[  -f "$git_dir/BISECT_LOG"  ]]   &&  op="bisect"
            # ??? branch="$(git symbolic-ref HEAD 2>/dev/null)" || \
            #    branch="$(git describe --exact-match HEAD 2>/dev/null)" || \
            #    branch="$(cut -c1-7 "$git_dir/HEAD")..."
        fi

        #####################################################################

        rawhex=`git rev-parse HEAD 2>/dev/null`
        rawhex=${rawhex/HEAD/}
        rawhex=${rawhex:0:6}
        
        ### branch

        branch=${branch/master/M}

                        # another method of above:
                        # branch=$(git symbolic-ref -q HEAD || { echo -n "detached:" ; git name-rev --name-only HEAD 2>/dev/null; } )
                        # branch=${branch#refs/heads/}

        ### compose vcs_info

        if [[ $init ]];  then 
            vcs_info=M$white=init

        else
            if [[ "$detached" ]] ;  then     
                branch="<detached:`git name-rev --name-only HEAD 2>/dev/null`"


            elif   [[ "$op" ]];  then
                    branch="$op:$branch"
                    if [[ "$op" == "merge" ]] ;  then     
                        branch+="<--$(git name-rev --name-only $(<$git_dir/MERGE_HEAD))"
                    fi
                    #branch="<$branch>"
            fi
            vcs_info="$branch$white=$rawhex"

        fi
 }

parse_vcs_dir() {

        unset   file_list modified_files untracked_files added_files 
        unset   vcs vcs_info
        unset   status modified untracked added init detached
        unset   file_list modified_files untracked_files added_files 

        parse_git_dir || return 

     
        ### status:  choose primary (for branch color)
        unset status
        status=${op:+op}
        status=${status:-$detached}
        status=${status:-$clean}
        status=${status:-$modified}
        status=${status:-$added}
        status=${status:-$untracked}
        status=${status:-$init}
                                # at least one should be set
                                : ${status?prompt internal error: git status}
        eval vcs_color="\${${status}_vcs_color}"

        ### file list
        unset file_list
        [[ ${added_files[1]}     ]]  &&  file_list+=" "$added_vcs_color${added_files[@]}
        [[ ${modified_files[1]}  ]]  &&  file_list+=" "$modified_vcs_color${modified_files[@]}
        [[ ${untracked_files[1]} ]]  &&  file_list+=" "$untracked_vcs_color${untracked_files[@]}
        file_list=${file_list:+:$file_list}

	if [[ ${#file_list} -gt $max_file_list_length ]]  ;  then
		file_list=${file_list:0:$max_file_list_length} 	
		file_list="${file_list% *} ..."
	fi


        #head_local="(${vcs_info}$vcs_color${file_list}$vcs_color)"
        head_local="(${vcs_info}$vcs_color$vcs_color)"

        ### fringes (added depended on location)
        head_local="${head_local+$vcs_color$head_local }"
        above_local="${head_local+$vcs_color$head_local\n}"
        tail_local="${tail_local+$vcs_color $tail_local}${dir_color}"
 }


###################################################################### PROMPT_COMMAND

prompt_command_function() {
    rc="$?"

    if [[ "$rc" == "0" ]]; then 
        rc=""
    else
        #rc="$rc_color$rc$colors_reset$bell "
        rc="$rc_color$rc$colors_reset "
    fi

    set_shell_title "$PWD/" 

    # TODO: put it back
    # truncate $PWD to $max_path_length
        # max_path_length=50
    # front=7
    # head=${PWD:0:$front}"..."

    parse_vcs_dir

    #PS1="$head_local$colors_reset$arrows_color$arrows$colors_reset$color_who_where$dir_color\w$tail_local$dir_color$ $colors_reset"
    PS1="$head_local$colors_reset$arrows_color$arrows$colors_reset$dir_color\w$tail_local$dir_color@local$ $colors_reset"

    unset head_local tail_local unset arrows
 }
    

PROMPT_COMMAND=prompt_command_function

unset rc id tty bell modified_files file_list

