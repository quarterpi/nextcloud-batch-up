#!/bin/sh

set -eu

# Handle printing errors
die () {
  printf '%s\n' "$1" >&2
  exit 1
}

message () {
  printf '%s\n' "$1" >&2
}

usage () {
  cat <<'EOF'
NAME
      batch_up - batch upload users

SYNOPSIS
      batch_up -?
      batch_up -h
      batch_up --help
      batch_up -v
      batch_up -vv
      batch_up -vvv
      batch_up --verbose
      batch_up -d
      batch_up --delimiter
      batch_up --delimiter=
      batch_up -p
      batch_up --path
      batch_up --path=

DESCRIPTION
      Batch_up is a program that adds a batch of users to an instance of NextCloud
      running inside of a docker container by reading a comma separated list from 
      stdin or a csv file. Stdin is the default and will be used if no file is 
      supplied. The delimiter does not have to be a comma, and can be set via the
      -d flag.

      CSV file should be formatted in one of the following configurations:
      username,Display Name,group,email@address.domain
      username,Display Name,group
      username,Display Name
      username

      CSV files should not include the header.

OPTIONS
      -? or -h or --help
            This option displays a summary of the commands accepted by batch_up.

      -v or -vv or -vvv or --verbose
            This option sets the verbosity. Each v adds to the verbosity.
            See the occ command for OwnCloud/NextCloud for more details as this
            option is passed on to the occ command.

            If this option is not passed, the default behavior is to pass the
            -q option to occ (the quiet option), making occ non-verbose.

      -d or --delimiter or --delimiter=
            This option allows you to choose which delimiter you would like to use.
            The following are acceptable characters for this option. ,.;:|

      -p or --path or --path=
            This option allows you to specify the directory of the 
            docker-compose.yml file. The default is to assume that it is in the 
            current path.

ENVIRONMENT VARIABLES
      OC_PASS
            Sets the password for users added. The OC_PASS environment variable
            is required.

EXAMPLES
      The command:
            batch_up.sh foobar.csv
            Will add the users from foobar.csv. Users will be given the password
            in the OC_PASS environment variable. 

      The command:
            batch_up.sh <<< "jack,Jack Frost,users,jack.frost@gmail.com"
            Will add the user jack, set his display name to Jack Frost, add him
            to the group users, and set his email to jack.frost@gmail.com.

      The command:
            echo "jack,Jack Frost,users,jack.frost@gmail.com" | batch_up.sh
            Will add the user jack, set his display name to Jack Frost, add him
            to the group users, and set his email to jack.frost@gmail.com.

      The command:
            batch_up.sh -d : foobar.csv
            Will set the delimiter to : and add the users from foobar.csv.

      The command:
            batch_up.sh -p ~/path/to/docker-dir foobar.csv
            Will set the path and add the users from foobar.csv.

      The command:
            cat foobar.csv | batch_up -p ~/path/to/docker-dir
            Will pipe the contents of foobar.csv into batch_up, set the path,
            and add the users from foobar.csv.

NOTE
      batch_up will assume that the csv file is in the current working directory.
      If the csv file is in a different directory, then you should either cd to the
      directory containing the csv OR cat the csv and pipe the output to batch_up.

EOF
}


# Set verbosity. Default is silent.
verbose=-q

# flags
while [ $# -gt 0 ]
do
  case $1 in
    -h|-\?|--help)
      usage # Display a usage synopsis.
      exit
      ;;
    -v|-vv|-vvv|--verbose)
      verbose=$1
      ;;
    -d|--delimiter)
      if [ $# -gt 1 ]
      then
        case $2 in
          ,|.|\;|:|\|)
            delimiter=$2
            shift
            ;;
          *)
            die 'Error: delimiter should be one of ,.;:| characters.'
        esac 
      else
        die 'Error: "--delimiter" requires a non-empty option argument.'
      fi
      ;;
    --delimiter=?*)
      case ${1#*=} in # Delete everything up to the = and assign the remainder.
        ,|.|\;|:|\|)
          delimiter=${1#*=}
          shift
          ;;
        *)
          die 'Error: delimiter should be one of ,.;:| characters.'
      esac 
      ;;
    --delimiter=) # Handle the case of empty --delimiter=
      die 'Error: "--delimiter=" requires a non-empty option argument.'
      ;;
    -p|--path)
      if [ $# -gt 1 ]
      then
        path=$2
        shift
      else
        die 'Error: --path requires a non-empty option argument.'
      fi
      ;;
    --path=?*)
      path=${1#*=}
      shift
      ;;
    --path=) # Handle the case of empty --path=
      die 'Error: "path=" requires a non-empty option argument.'
      ;;
      --)
      shift
      break
      ;;
    -?*)
      printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      ;;
    *) # Default case. No more options, so break out of the loop
      break
  esac

  shift
done

# Is the file readable?
if [ $# -gt 0 ] 
then
  [ -r "$1" ] || die "$1: Couldn't read file."
fi

# Is the OC_PASS environment variable set?
[ ${OC_PASS:-} ] || die "$0: No password specified. Run with --help for more info."

status=true                     # until a command fails

file=/dev/stdin
if [ $# -gt 0 ]; then file=$PWD'/'$1; fi
echo $file

# Check to see if the --path option is set
if [ ${path:-} ]
then
  cd $path
fi

message 'Adding users'

while IFS=${delimiter:-,} read -r f1 f2 f3 f4
do
  if [ "$f1" ]
  then
    docker-compose exec -T -e OC_PASS --user www-data app php occ \
      user:add --password-from-env \
      ${verbose:+"$verbose"} \
      ${f2:+"--display-name=$f2"} \
      ${f3:+"--group=$f3"} \
      "$f1" </dev/null \
      || status=false

    # If there is a fourth value in the csv, use it to set the user email.
    if [ "$f4" ]
    then
      docker-compose exec -T \
        --user www-data app php occ \
        user:setting "$f1" settings email "$f4" \
        </dev/null \
        || status=false
    fi
  else
    echo "Expected at least one field, but none were supplied." >&2
    status=false
    continue
  fi
  message '...'
done <"${file:-/dev/stdin}"

message 'Done'

exec $status
