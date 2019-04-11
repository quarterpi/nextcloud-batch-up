# nextcloud-batch-up
      batchup is a program that adds a batch of users to an instance of NextCloud
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

## OPTIONS
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

## ENVIRONMENT VARIABLES
      OC_PASS
            Sets the password for users added. The OC_PASS environment variable
            is required.

## EXAMPLES
      The command:
            batchup.sh foobar.csv
            Will add the users from foobar.csv. Users will be given the password
            in the OC_PASS environment variable. 

      The command:
            batchup.sh <<< "jack,Jack Frost,users,jack.frost@gmail.com"
            Will add the user jack, set his display name to Jack Frost, add him
            to the group users, and set his email to jack.frost@gmail.com.

      The command:
            echo "jack,Jack Frost,users,jack.frost@gmail.com" | batchup.sh
            Will add the user jack, set his display name to Jack Frost, add him
            to the group users, and set his email to jack.frost@gmail.com.

      The command:
            batchup.sh -d : foobar.csv
            Will set the delimiter to : and add the users from foobar.csv.

      The command:
            batchup.sh -p ~/path/to/docker-dir foobar.csv
            Will set the path and add the users from foobar.csv.

      The command:
            cat foobar.csv | batchup -p ~/path/to/docker-dir
            Will pipe the contents of foobar.csv into batchup, set the path,
            and add the users from foobar.csv.

## NOTE
      batchup will assume that the csv file is in the current working directory.
      If the csv file is in a different directory, then you should either cd to the
      directory containing the csv OR cat the csv and pipe the output to batch_up.
