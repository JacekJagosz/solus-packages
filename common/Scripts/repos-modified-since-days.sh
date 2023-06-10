#!/usr/bin/env bash
#
# Check for repositories that saw changes in the past n days {n defaults to 7}.
#
# Takes exactly zero XOR one arguments.
# IFF an argument is supplied, it is expected to be a positive integer.
# IFF an argument is NOT supplied (or 0 is supplied), the default value will be used.

AFFECTED=()
ARGS="$1"
DAYS=
DETECTCHANGES=""
# Define it here because bash doesn't like quotes in pattern matching expressions ('=~' below)
NUMERIC='(^[[:digit:]]+$)'

function parse-cmd-line-args () {
    if [[ ${ARGS} == "" ]]; then
        echo -en "# No argument specified, "
        DAYS=7
    elif [[ ${ARGS} =~ $NUMERIC ]]; then
        echo -en "# Argument specified (${BASH_REMATCH[1]}), "
        DAYS=${BASH_REMATCH[1]}
        # 0 is not a useful value in the "since 0 day(s)" sense
        if [[ $DAYS == 0 ]]; then
            DAYS=7
        fi
    else
        echo -en "# Nonsense argument specified (${ARGS}), "
        DAYS=7
    fi
}

function check-dir () {
    if [[ ! -d ./common/.git ]]; then
        echo -e "\nThis script needs to be run from the directory that contains common/ and package repo clones.\n"
        exit 1
    fi
}

function find-affected () {
    local nom
    local output
    for i in $(find . -maxdepth 2 -name .git); do
        nom="$(dirname ${i})"
        output="$(git -C ${nom} log -1 --date=short --after=@{$DAYS.days.ago})"
        if [[ -z "${output}" ]]; then
            continue
        fi
        AFFECTED+="${nom} "
    done
    unset nom
    unset output
}

# main
check-dir
parse-cmd-line-args
echo -en "using $DAYS.\n"
echo -e "#\n# change-detection command: git -C \$nom log -1 --date=short --after=@{$DAYS.days.ago}\n#"
find-affected

echo "# Repos affected in the last ${DAYS} days:"
echo "${AFFECTED[@]}"|tr ' ' '\n'|sort|uniq

