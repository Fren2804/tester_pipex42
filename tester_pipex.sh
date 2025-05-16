#!/bin/bash

clear

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'

inf="./test/infile"
out="./test/outfile"
comp="./test/compares"
pipex_dir="./"

function print_results()
{
	echo
	echo "-------------------------"
	echo
	errores=$(cat $comp/result)
    if [ -z "$errores" ]; then
        echo -e "${GREEN}✅ No Errors, CONGRATULATIONS. ${RESET}"
        echo -e "${GREEN}THANK YOU FOR USING ME${RESET}"
        echo
        echo "-------------------------"
    else
        echo -e "${YELLOW}❌ Errors. Pay Attention: not all KO means error - it could be a different out or exit with the same meaning. Study the KO and determine on your own if it is a real Error. ${RESET}"
        echo -e "${YELLOW}You can check every output, exit, errors, leaks and fd in "./test/outfile", check it please.${RESET}"
        echo -e "${YELLOW}If you want to know the exactly content of the test, go to "tester_pipex.sh" and search "#NUMBER" - for example "#3" ${RESET}"
        echo -e "${YELLOW}THANK YOU FOR USING ME${RESET}"
        echo
        echo -e "${RED}-------------------------${RESET}"
        echo -e "${RED}${errores}${RESET}"
        echo
        echo "-------------------------"
    fi
	exit 0
}

function comprobar_test_out_1() {
    local n_test_function=$1

    if [ -f "$out/outfile${n_test_function}" ] && [ -f "$out/outfile${n_test_function}_ori" ];  then
        diff "$out/outfile${n_test_function}" "$out/outfile${n_test_function}_ori" > /dev/null
        if [[ $? -ne 0 ]]; then
            echo "Test ${n_test_function} - Out" >> $comp/result
            echo "Different content in $out/outfile${n_test_function} and $out/outfile${n_test_function}_ori please, check it." >> $comp/result
            local line1=$(cat "$out/outfile${n_test_function}")
            local line2=$(cat "$out/outfile${n_test_function}_ori")
            echo "Outfile pipex:" >> $comp/result
            echo "${line1}" >> $comp/result
            echo "Outfile ori:" >> $comp/result
            echo "${line2}" >> $comp/result
            return 1
        fi
        return 0
    else
        if [ -f "$out/outfile${n_test_function}" ]; then
            echo "Test ${n_test_function} - Out" >> $comp/result
            echo "Outfile exist $out/outfile${n_test_function} and outfile not $out/outfile${n_test_function}_ori please, check it." >> $comp/result
            local line1=$(cat "$out/outfile${n_test_function}")
            echo "Outfile pipex:" >> $comp/result
            echo "${line1}" >> $comp/result
            return 1
        else
            if [ -f "$out/outfile${n_test_function}_ori" ]; then
                echo "Test ${n_test_function} - Out" >> $comp/result
                echo "Outfile NO exist $out/outfile${n_test_function} and yes outfile $out/outfile${n_test_function}_ori please, check it." >> $comp/result
                local line2=$(cat "$out/outfile${n_test_function}_ori")
                echo "Outfile ori:" >> $comp/result
                echo "${line2}" >> $comp/result
                return 1
            else
                return 0
            fi
        fi
    fi    
}

function comprobar_test_exit_1()
{
    local n_test_function=$1
    local line1=$(cat "$out/outfile${n_test_function}_exit")
    local line2=$(cat "$out/outfile${n_test_function}_ori_exit")
    local line2_aux_1=$(echo "$line2" | sed 's/.*line [0-9]*: //')
    local line2_aux_2=$(echo "$line2" | sed 's/bash: //')
    local line2_aux_1_sort=$(echo "$line2_aux_1" | sort)
    local line2_aux_2_sort=$(echo "$line2_aux_2" | sort)
    local line1_sort=$(echo "$line1" | sort)


    if [[ "$line1" == "$line2_aux_1" ]] || [[ "$line1" == "$line2_aux_2" ]] || [[ "$line1" == "$line2_aux_1_sort" ]] || [[ "$line1" == "$line2_aux_2_sort" ]] || [[ "$line1_sort" == "$line2_aux_1_sort" ]] || [[ "$line1_sort" == "$line2_aux_2_sort" ]]; then
        return 0
    else
        echo "Test ${n_test_function} - Exit" >> $comp/result
        echo "Different content in $out/outfile${n_test_function}_exit and $out/outfile${n_test_function}_ori_exit please, check it." >> $comp/result
        echo "Outfile pipex:" >> $comp/result
        echo "${line1}" >> $comp/result
        echo "Outfile ori:" >> $comp/result
        echo "${line2}" >> $comp/result
        return 1
    fi
}

function comprobar_test_errors_1() 
{
    local n_test_function=$1
    local line
    local error_pipex
    local error_original

    line=$(cat "$out/outfile${n_test_function}_errors")
    error_pipex=$(echo "$line" | grep -o "pipex:[0-9]*" | cut -d: -f2)
    error_original=$(echo "$line" | grep -o "original:[0-9]*" | cut -d: -f2)

    if [ "$error_pipex" -eq "$error_original" ]; then
        return 0
    else
        echo "Test ${n_test_function} - Errors" >> "$comp/result"
        echo "Different content in $out/outfile${n_test_function}_errors, please, check it." >> "$comp/result"
        echo "Error pipex:" >> "$comp/result"
        echo "${error_pipex}" >> "$comp/result"
        echo "Error original:" >> "$comp/result"
        echo "${error_original}" >> "$comp/result"
        return 1
    fi
}

function comprobar_test_duration()
{
    local n_test_function=$1
    local line
    local duration_pipex
    local duration_original
    local diff

    line=$(cat "$out/outfile${n_test_function}_duration")
    duration_pipex=$(echo "$line" | grep -o "Me:[0-9]*" | cut -d: -f2)
    duration_original=$(echo "$line" | grep -o "Ori:[0-9]*" | cut -d: -f2)
    diff=$((duration_pipex - duration_original))
    diff=${diff#-}

    if [ "$diff" -le 2 ]; then
        return 0
    else
        echo "Test ${n_test_function} - Time" >> "$comp/result"
        echo "Different content in $out/outfile${n_test_function}_duration, please, check it." >> "$comp/result"
        echo "Duration pipex:" >> "$comp/result"
        echo "${duration_pipex}" >> "$comp/result"
        echo "Duration original:" >> "$comp/result"
        echo "${duration_original}" >> "$comp/result"
        return 1
    fi
}

comprobar_test_val_leaks() {
    local n_test_function=$1
    local valgrind_file="$out/outfile${n_test_function}_val"
    local leak_summary
    local error_summary
    leak_summary=$(grep -A5 "LEAK SUMMARY:" "$valgrind_file")
    error_summary=$(grep "ERROR SUMMARY:" "$valgrind_file")
    if echo "$leak_summary" | grep -Eq "[1-9][0-9]* bytes in [1-9][0-9]* blocks" || \
       echo "$error_summary" | grep -vq "ERROR SUMMARY: 0 errors"; then
       {
            echo "Test $n_test_function - Leaks"
            if echo "$leak_summary" | grep -Eq "[1-9][0-9]* bytes in [1-9][0-9]* blocks"; then
                echo "$leak_summary"
            fi
            if echo "$error_summary" | grep -vq "ERROR SUMMARY: 0 errors"; then
                echo "$error_summary"
            fi
            echo
        } >> "$comp/result"
        return 1
    else
        return 0
    fi
}

comprobar_test_val_fd() {
    local n_test_function=$1
    local valgrind_file="$out/outfile${n_test_function}_val"

    if grep -A3 "Open file descriptor" "$valgrind_file" | grep -q "pipex"; then
        echo "Test ${n_test_function} - FD" >> "$comp/result"
        grep -A3 "Open file descriptor" "$valgrind_file" | grep -B1 "pipex" >> "$comp/result"
        return 1
    else
        return 0
    fi
}

function comprobar_test_out_2() {
    local n_test_function=$1

    if [ ! -f "$out/outfile${n_test_function}" ] && [ ! -f "$out/outfile${n_test_function}_ori" ];  then
        return 0
    else
        echo "Test ${n_test_function} - Out" >> $comp/result
        echo "Different results please, check it." >> $comp/result
        echo "Your pipex generate outfile, while original no." >> $comp/result
        local line1=$(cat "$out/outfile${n_test_function}")
        echo "Outfile pipex:" >> $comp/result
        echo "${line1}" >> $comp/result
		return 1
    fi    
}

function comprobar_test_exit_2()
{
    local n_test_function=$1
    local line1=$(cat "$out/outfile${n_test_function}_exit")
    local line2=$(cat "$out/outfile${n_test_function}_ori_exit")
    local line2_aux=$(echo "$line2" | sed 's/bash: //')
    local line2_aux_sort=$(echo "$line2_aux" | sort)
    local line1_sort=$(echo  "$line1" | sort)

    if [[ "$line1" == "$line2_aux" ]] || [[ "$line1" == "$line2_aux_sort" ]] || [[ "$line1_sort" == "$line2_aux_sort" ]]; then
        return 0
    else
        echo "Test ${n_test_function} - Exit" >> $comp/result
        echo "Different content in $out/outfile${n_test_function}_exit and $out/outfile${n_test_function}_ori_exit please, check it." >> $comp/result
        echo "Outfile pipex:" >> $comp/result
        echo "${line1}" >> $comp/result
        echo "Outfile ori:" >> $comp/result
        echo "${line2}" >> $comp/result
        return 1
    fi
}
#--
function comprobar_test_errors_2() {
    local n_test_function=$1
    local line
    local error_pipex

    line=$(cat "$out/outfile${n_test_function}_errors")
    error_pipex=$(echo "$line" | grep -o "pipex:[0-9]*" | cut -d: -f2)
    if [ "$error_pipex" -ne 0 ]; then
        return 0
    else
        echo "Test ${n_test_function} - Errors" >> $comp/result
        echo "Your pipex return 0, in a error case, please, check it." >> $comp/result
        echo "Error pipex:" >> $comp/result
        echo "${error_pipex}" >> $comp/result
        return 1
    fi
}

function comprobar_test_out_3() {
    local n_test_function=$1

    if [ ! -f "$out/outfile${n_test_function}" ]; then
        return 0
    else
        echo "Test ${n_test_function} - Out" >> $comp/result
        echo "Different result, please, check it." >> $comp/result
        echo "Your pipex generate outfile, but its a error." >> $comp/result
        local line1=$(cat "$out/outfile${n_test_function}")
        echo "Outfile pipex:" >> $comp/result
        echo "${line1}" >> $comp/result
		return 1
    fi    
}

function comprobar_test_exit_3()
{
    local n_test_function=$1
    local line1=$(cat "$out/outfile${n_test_function}_exit")

    if echo "$line1" | grep -iq "error"; then
        return 0
    else
		echo "Test ${n_test_function} - Exit" >> $comp/result
        echo "No found word "E/error", please, check it." >> $comp/result
        echo "Exit pipex:" >> $comp/result
        echo "${line1}" >> $comp/result
        return 1
    fi
}

#--

function comprobar_test_exit_path()
{
	local n_test_function=$1
    local line1=$(cat "$out/outfile${n_test_function}_exit")
    local line2=$(cat "$out/outfile${n_test_function}_ori_exit")
    local line2_aux=$(echo "$line2" | sed 's/bash: //')

    if [[ "$line1" == "$line2" ]] || [[ "$line1" == "$line2_aux" ]]; then
        return 0
    else
        echo "Test ${n_test_function} - Exit" >> $comp/result
        echo "Different content in $out/outfile${n_test_function}_exit and $out/outfile${n_test_function}_ori_exit please, check it." >> $comp/result
        echo "Outfile pipex:" >> $comp/result
        echo "${line1}" >> $comp/result
        echo "Outfile ori:" >> $comp/result
        echo "${line2}" >> $comp/result
        return 1
    fi
}




echo -e "${BLUE}==================================================${RESET}"
echo -e "${YELLOW}[........[.......          [.       [...     [.."
echo -e "[..      [..    [..       [. ..     [. [..   [.."
echo -e "[..      [..    [..      [.  [..    [.. [..  [.."
echo -e "[......  [. [..         [..   [..   [..  [.. [.."
echo -e "[..      [..  [..      [...... [..  [..   [. [.."
echo -e "[..      [..    [..   [..       [.. [..    [. .."
echo -e "[..      [..      [..[..         [..[..      [..${RESET}"
echo -e "${BLUE}==================================================${RESET}"

if [[ $# -ne 1 || ("$1" != "-nobonus" && "$1" != "-bonus1" && "$1" != "-bonus2" )]]; then
    echo "Use: bash tester_pipex.sh [flags]"
    echo "Options:"
    echo "  -nobonus, -Execute tests for no bonus pipex"
    echo "  -bonus1, -Execute tests for nobonus + for bonus multiple pipex"
	echo "  -bonus2, -Execute tests for bonus1 + for bonus delimiter pipex"
    exit 1
fi

make fclean > /dev/null 2>&1
error=$?
if [ "$error" -ne 0 ]; then
    echo -e "Make fclean\t\t${RED}[KO]${RESET}"
    exit 1
fi

norminette > /dev/null 2>&1
error=$?
if [ "$error" -ne 0 ]; then
    echo -e "Norminette \t\t\t${RED}[KO]${RESET}"
else
    echo -e "Norminette \t\t\t${GREEN}[OK]${RESET}"
fi

make > /dev/null 2>&1
error=$?
if [ "$error" -ne 0 ]; then
    echo -e "Compiling no bonus\t\t${RED}[KO]${RESET}"
    exit 1;
else
    echo -e "Compiling no bonus\t\t${GREEN}[OK]${RESET}"
fi
echo -e "\t${YELLOW}Waiting for tests...${RESET}"

rm -rf test

mkdir test
mkdir test/infile
mkdir test/outfile
mkdir test/compares

touch $comp/result
chmod 777 $comp/result

n_test=1

echo "Prueba1" > $inf/infile1
chmod 000 $inf/infile1

touch $inf/infile2

echo "hola mundo
hola chat
hola programador
hola mundo
hola chat
hola gpt
hola universo
hola terminal
hola sistema
nada relevante
adiós mundo
nada mundo
cuento mundo
adiós sistema
hola pipex
nada chat
mundo hola" > $inf/infile3

echo "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent fringilla nulla quis nibh gravida gravida.
Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Fusce fermentum ac dolor eget accumsan.
Donec et euismod orci. Nam magna quam, commodo cursus odio quis, tristique porta dolor. Phasellus interdum, dolor eu mattis semper, tellus odio ultricies mi, sed sollicitudin libero enim vitae est.
Morbi eget eros vel ligula venenatis vulputate quis a leo. Praesent placerat faucibus enim, eu lobortis tellus porta commodo. 
Maecenas convallis, nisi ac semper aliquet, augue velit congue lorem, bibendum dapibus leo tortor quis neque. Vestibulum sit amet nunc cursus, lobortis dolor non, tincidunt lectus.
Phasellus tristique orci augue, eu finibus purus dictum at. Mauris blandit volutpat erat in posuere. Phasellus fermentum dignissim ante vitae sodales. Maecenas non erat nec diam finibus lacinia eu non lorem." > $inf/infile4

ls -la > $inf/infile5

echo "42_pipex_tester
Hola
Makefile
a.out
ejecutar.sh
ejecutar_bonus.sh
hiola
inc
infile2
libft
outfile1_ori
pipex
src
test
tester_pipex.sh" > $inf/infile6




#1 - Infile no Exist - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "grep hola" "ls -l" "$out/outfile$n_test" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "grep hola" "ls -l" "$out/outfile$n_test"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ grep "hola" < "$inf/infile" | ls -l > "$out/outfile${n_test}_ori"; }  2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#2 - Infile no Permission - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile1" "ls -l" "wc -l" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile1" "ls -l" "wc -l" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ ls -l < "$inf/infile1" | wc -l > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#3 - Infile Good - 2 Commands Good - Outfile no Permission
touch $out/outfile_p1;
chmod 000 $out/outfile_p1
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "grep hola" "ls -l" "$out/outfile_p1" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "grep hola" "ls -l" "$out/outfile_p1"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
#That produce stderr 1
#{ grep "hola" < "$inf/infile2" | ls -l; } > "$out/outfile_p1" 2> "$out/outfile4_ori_exit"
echo "tester_pipex.sh: line 101: ./test/outfile/outfile_p1: Permission denied" > "$out/outfile${n_test}_ori_exit"
error2=1
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#4 - Infile Good - First command Error - Last command Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "ls -l" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "ls -l" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ nocommandexist < "$inf/infile2" | ls -l > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#5 - Infile Good - First command Good - Last command Error - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "ls -l" "nocommandexist" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "ls -l" "nocommandexist" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ ls -l < "$inf/infile2" | nocommandexist > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#6 - Infile no Exist - First command Good - Last command Error - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "ls -l" "nocommandexist" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "ls -l" "nocommandexist" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ ls -l < "$inf/infile" | nocommandexist > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#7 - Infile Good - 2 Commands Error - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "nocommandexist" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "nocommandexist" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ nocommandexist < "$inf/infile2" | nocommandexist > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#8 - Infile Good - 2 Commands Error - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "grep hola" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "grep hola" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ nocommandexist < "$inf/infile2" | grep hola > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#9 - Infile Good - 2 Commands Error - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "grep -fhg" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "grep -fhg" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ nocommandexist < "$inf/infile2" | grep -fhg > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#10 - Infile Good - 2 Commands Error - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "grep -fhg" "nocommandexist" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "grep -fhg" "nocommandexist" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ grep -fhg < "$inf/infile2" | nocommandexist > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#11 - Infile Error - 2 Commands Error - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "nocommandexist" "grep -fhg" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "nocommandexist" "grep -fhg" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ nocommandexist < "$inf/infile" | grep -fhg > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#12 - Infile Error - 2 Commands Error - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "nocommandexist" "grep -fhg" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "nocommandexist" "grep -fhg" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ nocommandexist < "$inf/infile" | grep -fhg > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#13 - Infile Error - 2 Commands Error - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "grep -fhg" "nocommandexist" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "grep -fhg" "nocommandexist" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ grep -fhg < "$inf/infile" | nocommandexist > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#14 - Infile Good - 2 Commands Error - Outfile Error
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "grep -fhg" "nocommandexist" "$out/outfile_p1" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "grep -fhg" "nocommandexist" "$out/outfile_p1"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
#Stderror 1
#{ grep -fhg < "$inf/infile2" | nocommandexist > "$out/outfile_p1"; } 2> "$out/outfile${n_test}_ori_exit"
echo "grep: hg: No such file or directory
bash: ./test/outfile/outfile_p1: Permission denied" > $out/outfile${n_test}_ori_exit
error2=1
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#15 - Infile Good - 2 Commands Error - Outfile Error
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "grep -fhg" "$out/outfile_p1" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "nocommandexist" "grep -fhg" "$out/outfile_p1"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
#Stderror 1
#{ nocommandexist < "$inf/infile2" | grep -fhg > "$out/outfile_p1"; } 2> "$out/outfile${n_test}_ori_exit"
echo "bash: ./test/outfile/outfile_p1: Permission denied
nocommandexist: command not found" > $out/outfile${n_test}_ori_exit
error2=1
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#16 - Infile Error - 2 Commands Error - Outfile Error
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "nocommandexist" "grep -fhg" "$out/outfile_p1" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "nocommandexist" "grep -fhg" "$out/outfile_p1"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
#Stderror 1
#{ nocommandexist < "$inf/infile" | grep -fhg > "$out/outfile_p1"; } 2> "$out/outfile${n_test}_ori_exit"
echo "bash: ./test/outfile/outfile_p1: Permission denied
bash: ./test/infile/infile: No such file or directory" > $out/outfile${n_test}_ori_exit
error2=1
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#17 - Just ./pipex
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

((n_test++))

#18 - Empty files + args
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "" "" "" ""> $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "" "" "" ""; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

((n_test++))

#19 - Infile Error - No more
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

((n_test++))

#20 - Infile Error - Outfile Error
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "$out/outfile_p1"> $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "$out/outfile_p1"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

((n_test++))

#21 - Outfile Error - No more
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$out/outfile_p1"> $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$out/outfile_p1"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

((n_test++))

#22 - Infile Good - 3 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "ls -l" "cat -e" "cat -e" "$out/outfile${n_test}"> $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "ls -l" "cat -e" "cat -e" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

((n_test++))

#23 - Infile Error - Empty args - Outfile Error
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "         " "      " "$out/outfile_p1"> $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "         " "      " "$out/outfile_p1";} > "$out/outfile${n_test}_exit" 2>&1
error1=$?
echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

((n_test++))

#24 - Infile Error - First command Error - Empty arg - Outfile Error
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "   hjg      " "      " "$out/outfile_p1"> $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "   hjg      " "      " "$out/outfile_p1";} > "$out/outfile${n_test}_exit" 2>&1
error1=$?
echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

((n_test++))

#25 - Infile Error - Empty arg - Last command Error  - Outfile Error
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "      " "   hjg      " "$out/outfile_p1"> $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile" "      " "   hjg      " "$out/outfile_p1";} > "$out/outfile${n_test}_exit" 2>&1
error1=$?
echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

((n_test++))

#26 - Infile Empty - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "grep hola" "ls -l" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "grep hola" "ls -l" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ grep hola < "$inf/infile2" | ls -l > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#27 - Infile Empty - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "ls -l" "grep hola" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "ls -l" "grep hola" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ ls -l < "$inf/infile2" | grep hola > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#28 - Infile Empty - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile2" "ls -l" "grep hola1" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile2" "ls -l" "grep hola1" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ ls -l < "$inf/infile2" | grep hola1 > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#29 - Infile Good - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile3" "grep hola" "wc -l" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
{ ${pipex_dir}pipex "$inf/infile3" "grep hola" "wc -l" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ grep hola < "$inf/infile3" | wc -l > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#30 - Infile Good - 2 Commands Good - Outfile Good
start_val=$(date +%s)
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile3" "sleep 8" "sleep 8" "$out/outfile${n_test}" > $out/outfile${n_test}_val 2>&1
end_val=$(date +%s)
start=$(date +%s)
{ ${pipex_dir}pipex "$inf/infile3" "sleep 8" "sleep 8" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
end=$(date +%s)
error1=$?
start_ori=$(date +%s)
{ sleep 8 < "$inf/infile3" | sleep 8 > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
end_ori=$(date +%s)
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors
duration_val=$((end_val - start_val))
duration=$((end - start))
duration_ori=$((end_ori - start_ori))
echo "Val:$duration_val Me:$duration Ori:$duration_ori" > $out/outfile${n_test}_duration

((n_test++))

#31 - Infile Good - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile3" "grep -i "hola"" "cat -e" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
{ ${pipex_dir}pipex "$inf/infile3" "grep -i "hola"" "cat -e" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ grep -i "hola" < "$inf/infile3" | cat -e > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#32 - Infile Good - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile4" "grep -o -i "lorem"" "cat -e" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
{ ${pipex_dir}pipex "$inf/infile4" "grep -o -i "lorem"" "cat -e" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ grep -o -i "lorem" < "$inf/infile4" | cat -e > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#33 - Infile Good - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile4" "ls -l -a" "cat -e -n" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
{ ${pipex_dir}pipex "$inf/infile4" "ls -l -a" "cat -e -n" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ ls -l -a < "$inf/infile4" | cat -e -n > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#34 - Infile Good - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e -n" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
{ ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e -n" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ head -4 < "$inf/infile6" | cat -e -n > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))
touch $out/outfile${n_test}
chmod 777 $out/outfile${n_test}
touch $out/outfile${n_test}_ori
chmod 777 $out/outfile${n_test}_ori
#35 - Infile Good - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e -n" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
{ ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e -n" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ head -4 < "$inf/infile6" | cat -e -n > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))
touch $out/outfile${n_test}
chmod 777 $out/outfile${n_test}
touch $out/outfile${n_test}_ori
chmod 777 $out/outfile${n_test}_ori
#36 - Infile Good - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "cat -e" "grep nothing" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
{ ${pipex_dir}pipex "$inf/infile6" "cat -e" "grep nothing" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ cat -e < "$inf/infile6" | grep nothing > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))
touch $out/outfile${n_test}
chmod 777 $out/outfile${n_test}
touch $out/outfile${n_test}_ori
chmod 777 $out/outfile${n_test}_ori
#37 - Infile Good - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "grep nothing" "cat -e" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
{ ${pipex_dir}pipex "$inf/infile6" "grep nothing" "cat -e" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ grep nothing < "$inf/infile6" | cat -e > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

((n_test++))

#38 - Infile Good - 2 Commands Good - Outfile Good
valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e -n" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
{ ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e -n" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
error1=$?
{ head -4 < "$inf/infile6" | cat -e -n > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
error2=$?
echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

if [[ "$1" == "-nobonus" ]]; then
    ((n_test++))
	ORIGINAL_PATH=$PATH
    unset PATH
    #39 - Infile Good - First Command Good - Last Command no Exist - Outfile Good
    { ${pipex_dir}pipex "$inf/infile6" "head -4" "noexistingcommand" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	#Stderr 127
	#{ head -4 < "$inf/infile6" | noexistingcommand > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
	export PATH=$ORIGINAL_PATH
	echo "bash: head: No such file or directory
bash: noexistingcommand: No such file or directory" > $out/outfile${n_test}_ori_exit
	error2=127
	echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors
else
	make fclean > /dev/null 2>&1
	error=$?
	if [ "$error" -ne 0 ]; then
		echo -e "Make fclean\t\t${RED}[KO]${RESET}"
		exit 1
	fi

	make bonus > /dev/null 2>&1
	error=$?
	if [ "$error" -ne 0 ]; then
		echo -e "Compiling bonus\t\t\t${RED}[KO]${RESET}"
		exit 1;
	else
		echo -e "Compiling bonus\t\t\t${GREEN}[OK]${RESET}"
	fi
	echo -e "\t${YELLOW}Waiting for tests...${RESET}"


	((n_test++))

	#39 - Infile Good - 2 Command Good - 2 Command Empty - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e -n" "   " "    " "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e -n" "   " "    " "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

	((n_test++))

	#40 - Infile Good - 1 Command Good - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "head -4" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile" "head -4" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

	((n_test++))

	#41 - Infile Good - 3 Command Good - 1 Command Empty - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "head -4" "ls -l" "cat -e" "    " "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile" "head -4" "ls -l" "cat -e" "    " "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	echo "Test ${n_test} - Error pipex:$error1" > $out/outfile${n_test}_errors

	((n_test++))

	#42 - Infile no Exist - 4 Commands Good - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "head -4" "cat -e" "ls -l" "sort" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile" "head -4" "cat -e" "ls -l" "sort" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	{ head -4 < "$inf/infile" | cat -e | ls -l | sort > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
	error2=$?
	echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

	((n_test++))

	#43 - Infile no Permission - 4 Commands Good - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "head -4" "cat -e" "ls -l" "cat -e" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile" "head -4" "cat -e" "ls -l" "cat -e" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	{ head -4 < "$inf/infile" | cat -e | ls -l | cat -e > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
	error2=$?
	echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

	((n_test++))

	#44 - Infile no Permission - 3 Commands Good - 1 Command no Exist - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile" "head -4" "cat -e" "hihuih" "cat -e" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile" "head -4" "cat -e" "hihuih" "cat -e" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	{ head -4 < "$inf/infile" | cat -e | hihuih | cat -e > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
	error2=$?
	echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

	((n_test++))

	#45 - Infile Good - 3 Commands Good - 1 Command no Exist - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e" "hihuih" "cat -e" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e" "hihuih" "cat -e" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	{ head -4 < "$inf/infile6" | cat -e | hihuih | cat -e > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
	error2=$?
	echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

	((n_test++))
	touch $out/outfile${n_test}
	chmod 777 $out/outfile${n_test}
	touch $out/outfile${n_test}_ori
	chmod 777 $out/outfile${n_test}_ori

	#46 - Infile Good - 4 Commands Good - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e" "ls -l" "grep nononono" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e" "ls -l" "grep nononono" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	{ head -4 < "$inf/infile6" | cat -e | ls -l | grep nononono > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
	error2=$?
	echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

	((n_test++))

	#47 - Infile Good - 4 Commands Good - Outfile no Permission
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e" "ls -l" "cat -e" "$out/outfile_p1" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile6" "head -4" "cat -e" "ls -l" "cat -e" "$out/outfile_p1"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	{ head -4 < "$inf/infile6" | cat -e | ls -l | cat -e > "$out/outfile_p1"; } 2> "$out/outfile${n_test}_ori_exit"
	error2=$?
	echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

	((n_test++))

	#48 - Infile Good - 1 Command Good - 3 Commands Error - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "cat -e" "nocommand" "command42Madrid" "FundacionTelefonica" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile6" "cat -e" "nocommand" "command42Madrid" "FundacionTelefonica" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	{ cat -e < "$inf/infile6" | nocommand | command42Madrid | FundacionTelefonica > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
	error2=$?
	echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

	((n_test++))

	#49 - Infile Good - 8 Commands Good - Outfile Good
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex "$inf/infile6" "cat -e" "cat -e" "cat -e" "cat -e" "cat -e" "cat -e" "cat -e" "cat -e" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
	{ ${pipex_dir}pipex "$inf/infile6" "cat -e" "cat -e" "cat -e" "cat -e" "cat -e" "cat -e" "cat -e" "cat -e" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
	error1=$?
	{ cat -e < "$inf/infile6" | cat -e | cat -e | cat -e | cat -e | cat -e | cat -e | cat -e > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
	error2=$?
	echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors

	if [[ "$1" == "-bonus1" ]]; then
		((n_test++))
		ORIGINAL_PATH=$PATH
		unset PATH
		#50 - Infile Good - First Command Good - Last Command no Exist - Outfile Good
		{ ${pipex_dir}pipex "$inf/infile6" "head -4" "noexistingcommand" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
		error1=$?
		export PATH=$ORIGINAL_PATH
		#Stderr 127
		#{ head -4 < "$inf/infile6" | noexistingcommand > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
		echo "bash: head: No such file or directory
bash: noexistingcommand: No such file or directory" > $out/outfile${n_test}_ori_exit
		error2=127
		echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors
	else
		((n_test++))
		#50 - Infile Good - DELIMITER - Outfile Good
		valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ${pipex_dir}pipex here_doc END "grep hola" "wc -l" "$out/outfile${n_test}" > "$out/outfile${n_test}_val" 2>&1
		{ ${pipex_dir}pipex here_doc END "grep hola" "wc -l" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
		error1=$?
{ cat << END | grep hola | wc -l > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
hola mundo
otra linea
hola otra vez
END
		error2=$?
		echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > "$out/outfile${n_test}_errors"

		((n_test++))
		ORIGINAL_PATH=$PATH
		unset PATH
		#51 - Infile Good - First Command Good - Last Command no Exist - Outfile Good
		{ ${pipex_dir}pipex "$inf/infile6" "head -4" "noexistingcommand" "$out/outfile${n_test}"; } > "$out/outfile${n_test}_exit" 2>&1
		error1=$?
		export PATH=$ORIGINAL_PATH
		#Stderr 127
		#{ head -4 < "$inf/infile6" | noexistingcommand > "$out/outfile${n_test}_ori"; } 2> "$out/outfile${n_test}_ori_exit"
		echo "bash: head: No such file or directory
bash: noexistingcommand: No such file or directory" > $out/outfile${n_test}_ori_exit
		error2=127
		echo "Test ${n_test} - Error pipex:$error1 error original:$error2" > $out/outfile${n_test}_errors
	fi
fi


n_test_aux=1
error_aux=0
echo
echo
printf "${MAGENTA}%-30s %-10s %-10s %-10s %-10s %-10s %-10s ${RESET}\n" "" "[OUT]" "[EXIT]" "[ERRORS]" "[TIME]" "[LEAKS]" "[FD]"
echo
echo -e "${YELLOW}No Bonus Tests${RESET}"
#Test 1 - 13
while [ $n_test_aux -le 13 ]; do
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    printf "%-10s " " "
    comprobar_test_val_leaks $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_val_fd $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-10s${RESET} " "[OK]"
    else
        printf "${RED}%-10s${RESET} " "[KO]"
		error_aux=1
    fi
    echo
	if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
    ((n_test_aux++))
done

#Test 14 - 16
while [ $n_test_aux -le 16 ]; do
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_2 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_2 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    printf "%-10s " " "
    comprobar_test_val_leaks $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_val_fd $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-10s${RESET} " "[OK]"
    else
        printf "${RED}%-10s${RESET} " "[KO]"
		error_aux=1
    fi
    echo
    if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
    ((n_test_aux++))
done

#Test 17 - 25
while [ $n_test_aux -le 25 ]; do
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_3 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_3 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_2 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    printf "%-10s " " "
    comprobar_test_val_leaks $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_val_fd $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-10s${RESET} " "[OK]"
    else
        printf "${RED}%-10s${RESET} " "[KO]"
		error_aux=1
    fi
    echo
    if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
    ((n_test_aux++))
done

#Test 26 - 38
while [ $n_test_aux -le 38 ]; do
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
	if [ $n_test_aux -eq 30 ]; then
		comprobar_test_duration $n_test_aux
		if [ $? -eq 0 ]; then
        	printf "${GREEN}%-10s${RESET} " "[OK]"
    	else
        	printf "${RED}%-10s${RESET} " "[KO]"
			error_aux=1
    	fi
	else
		printf "%-10s " " "
	fi
    comprobar_test_val_leaks $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_val_fd $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-10s${RESET} " "[OK]"
    else
        printf "${RED}%-10s${RESET} " "[KO]"
		error_aux=1
    fi
    echo
	if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
    ((n_test_aux++))
done

#Test 39 no bonus path
if [[ "$1" == "-nobonus" ]]; then
	echo
	echo -e "${YELLOW}Test Unset PATH${RESET}"
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_path $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    printf "%-10s " " "
    printf "%-10s " " "
	printf "%-10s " " "
    echo
    if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
	print_results
fi

#Bonus1
echo
echo -e "${YELLOW}Bonus 1 Tests${RESET}"

#Test 39 - 41
while [ $n_test_aux -le 41 ]; do
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_3 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_3 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_2 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    printf "%-10s " " "
    comprobar_test_val_leaks $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_val_fd $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-10s${RESET} " "[OK]"
    else
        printf "${RED}%-10s${RESET} " "[KO]"
		error_aux=1
    fi
    echo
    if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
    ((n_test_aux++))
done

#Test 42 - 48
while [ $n_test_aux -le 48 ]; do
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    printf "%-10s " " "
    comprobar_test_val_leaks $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_val_fd $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-10s${RESET} " "[OK]"
    else
        printf "${RED}%-10s${RESET} " "[KO]"
		error_aux=1
    fi
    echo
	if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
    ((n_test_aux++))
done

#Test 49
while [ $n_test_aux -le 49 ]; do
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
	printf "%-10s " " "
    comprobar_test_val_leaks $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_val_fd $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-10s${RESET} " "[OK]"
    else
        printf "${RED}%-10s${RESET} " "[KO]"
		error_aux=1
    fi
    echo
	if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
    ((n_test_aux++))
done

#Test 50 bonus 1 path
if [[ "$1" == "-bonus1" ]]; then
	echo
	echo -e "${YELLOW}Test Unset PATH${RESET}"
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_path $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    printf "%-10s " " "
    printf "%-10s " " "
	printf "%-10s " " "
    echo
    if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
	print_results
fi


#Bonus2
echo
echo -e "${YELLOW}Bonus 2 Tests${RESET}"

#Test 50
while [ $n_test_aux -le 50 ]; do
	error_aux=0
    printf "%-30s " "Test $n_test_aux"
    comprobar_test_out_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_exit_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-11s${RESET} " "[OK]"
    else
        printf "${RED}%-11s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_errors_1 $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
	printf "%-10s " " "
    comprobar_test_val_leaks $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-9s${RESET} " "[OK]"
    else
        printf "${RED}%-9s${RESET} " "[KO]"
		error_aux=1
    fi
    comprobar_test_val_fd $n_test_aux
    if [ $? -eq 0 ]; then
        printf "${GREEN}%-10s${RESET} " "[OK]"
    else
        printf "${RED}%-10s${RESET} " "[KO]"
		error_aux=1
    fi
    echo
	if [ $error_aux -eq 1 ]; then
    	echo "-------------------------------">> $comp/result
	fi
    ((n_test_aux++))
done

echo
echo -e "${YELLOW}Test Unset PATH${RESET}"
#Test 51 bonus 2 path
error_aux=0
printf "%-30s " "Test $n_test_aux"
comprobar_test_out_1 $n_test_aux
if [ $? -eq 0 ]; then
    printf "${GREEN}%-11s${RESET} " "[OK]"
else
    printf "${RED}%-11s${RESET} " "[KO]"
	error_aux=1
fi
comprobar_test_exit_path $n_test_aux
if [ $? -eq 0 ]; then
    printf "${GREEN}%-11s${RESET} " "[OK]"
else
    printf "${RED}%-11s${RESET} " "[KO]"
	error_aux=1
fi
comprobar_test_errors_1 $n_test_aux
if [ $? -eq 0 ]; then
    printf "${GREEN}%-9s${RESET} " "[OK]"
else
    printf "${RED}%-9s${RESET} " "[KO]"
	error_aux=1
fi
printf "%-10s " " "
printf "%-10s " " "
printf "%-10s " " "
echo
if [ $error_aux -eq 1 ]; then
    echo "-------------------------------">> $comp/result
fi
print_results
