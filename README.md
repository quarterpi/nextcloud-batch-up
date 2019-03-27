# nextcloud-batch-users
Bash script that allows you to batch upload users to NextCloud from csv file.

Assumes that you are running NextCloud in docker with docker-compose.yml.
This script should be executed from the same directory as your docker-compose.yml.

# Example usage
`./batch_users.sh --password=Supersecretpassword123# foo.csv`
Will add users from foo.csv and give them the password Supersecretpassword123#.
`./batch_users.sh --password Supersecretpassword123# foo.csv`
and 
`./batch_users.sh -p Supersecretpassword123# foo.csv`
will do the same thing.

### foo.csv
CSV files should follow the form:
`username,Display Name,yourgroup,your@email.domain,`
where only `username` is required for any given entry.

If no email is supplied, no email is added
If no group is supplied for the user, then none is added.
If a group is supplied and the group does not already exist, the group is created.
If no Display Name is supplied, then the username serves as both the username (uid) and the Display Name.
