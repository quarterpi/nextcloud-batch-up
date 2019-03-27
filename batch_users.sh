#!/bin/bash

# Handle printing errors
die () {
  printf '%s\n' "$1" >&2
  exit 1
}

usage () {
  echo ""
  echo "batch_users.sh"          
  echo "SYNOPSIS"
  echo "batch_users [-p] [file]"
  echo "DESCRIPTION"
  echo "The batch_users script adds a batch of users to an instance of NextCloud running inside of a docker container by reading a list from a csv file."
  echo ""
  echo "-p, --password    Set users password. If no option is passed, the default password is nomoremonkeysjumpingonthebed ."
  echo ""
  echo "csv file should be formatted in one of the following configurations."
  echo "username,Display Name,group,email@address.domain,"
  echo "username,Display Name,group,"
  echo "username,Display Name,"
  echo "username,"
  echo ""
  echo "EXAMPLES"
  echo "The command:"
  echo "batch_users.sh -p 123password321 foobar.csv"
  echo "will add the users from foobar.csv and assign them the password 123password321"
  echo "The command:"
  echo"batch_users.sh foobar.csv"
  echo "will add the users from foobar.csv and assign them the default password."
  echo ""
  echo "batch_users will return 0 on success and a positive number on failure."
  echo ""
}
# flags
password=nomoremonkeysjumpingonthebed
while :; do
  case $1 in
    -h|-\?|--help)
      usage # Display a usage synopsis.
      exit
      ;;
    -p|--password)
      if [ "$2" ]; then
        password=$2
        shift
      else
        die 'Error: "--password" requires a non-empty option argument.'
      fi
      ;;
    --password=?*)
      password=${1#*=} # Delete everything up to = and assign the remainder.
      ;;
    --password=) # Handle the case of empty --password=
      die 'Error: "--password" requires a non-empty option argument.'
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


# Check to see if there was at least one argument passed.
# If not, print error and exit.
if [[ $# -eq  0 ]]
then
#  (>&2 echo "Expected at least one argument, but no arguments were supplied.")
  die 'Error: Expected at least one argument, but no arguments were supplied.'
fi

# Check to see if the file passed in exists.
# If not, print error and exit.
if [[ ! -e $1 ]]
then
  die "Couldn't find file ${1}."
  exit 1
fi


input_file="$1"

#   Input File
#   Jack Ripper,jack,test_group
#   Jill Ripper,jill,test_group
#   Johny Appleseed,johny,test_group

while IFS=, read -r f1 f2 f3 f4
do
  # check --password flag
  # f1, f2, f3 exist?
  if [[ -n $f1  && -n $f2 && -n $f3 ]]
  then

    sh -c "docker-compose exec -T --env OC_PASS=${password} --user www-data app php occ \
      user:add --password-from-env --display-name=\"${f2}\" --group=\"${f3}\" \"$f1\" " < /dev/null

  elif [[ -n $f1 && -n $f2 ]]
  then
    # f1 and f2

    sh -c "docker-compose exec -T --env OC_PASS=${password} --user www-data app php occ \
      user:add --password-from-env --display-name=\"${f2}\" \"$f1\" " < /dev/null

  elif [[ -n $f1 ]]
  then
    #only f1

    sh -c "docker-compose exec -T --env OC_PASS=${password} --user www-data app php occ \
      user:add --password-from-env \"$f1\" " < /dev/null

  else
    #error
    die "Expected at least one field, but none were supplied."
  fi

  # If there is a fourth value in the csv, use it to set the user email.
  if [[ -z ${f4+x} ]]
  then
    break
  else
    sh -c "docker-compose exec -T --user www-data app php occ\
      user:setting \"$f1\" settings email \"${f4}\" " < /dev/null
  fi
done <"$input_file"
exit 0

