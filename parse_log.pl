#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Getopt::Long;
use constant none_val => 'None';

# Database connection parameters
my $db_name = 'dzabakh';
my $db_user = 'dzabakh';
my $db_pass = '';
my $host    = 'localhost';
GetOptions ("db_name=s"   => \$db_name,
                      "db_user=s"   => \$db_user,
                      "db_pass=s"   => \$db_pass,
                      "host" => \$host) or die "Error in command line arguments\n";

# Make message table

# Connect to PostgreSQL database
my $dbh = DBI->connect("dbi:Pg:dbname=$db_name;host=$host", $db_user, $db_pass, {
    PrintError => 0,
    RaiseError => 1,
    AutoCommit => 1,
});

# SQL statements to create table and indexes
my @sql_commands = (
    q(CREATE TABLE message (
        created TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
        id VARCHAR NOT NULL,
        int_id CHAR(16) NOT NULL,
        str VARCHAR NOT NULL,
        status BOOL,
        CONSTRAINT message_id_pk PRIMARY KEY(id)
    )),
    q(CREATE INDEX message_created_idx ON message (created)),
    q(CREATE INDEX message_int_id_idx ON message (int_id))
);

# Execute each SQL command
foreach my $sql (@sql_commands) {
    $dbh->do($sql);
    print "Executed: $sql\n";
}


# Make log table
# SQL statements to create table and indexes
@sql_commands = (
    q(CREATE TABLE log (
        created TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
        int_id CHAR(16) NOT NULL,
        str VARCHAR,
        address VARCHAR
    )),
    q(CREATE INDEX log_address_idx ON log USING hash (address))
);

# Execute each SQL command
foreach my $sql (@sql_commands) {
    $dbh->do($sql);
    print "Executed: $sql\n";
}

open my $log, '<', 'out' or die "Could not open 'out': $!";

my $line_id = 1;
while (my $line = <$log>) {
    $line_id = $line_id + 1;
    chomp $line;
    print "Parsing line: $line\n";
    
    my ($date, $time, $int_id, $flag, $address, $other_info) = split(' ', $line, 6);
    
    unless ($date =~ /^\d{4}-\d{2}-\d{2}$/) {
        warn "Invalid date format: $date\n";
        $date = none_val;
    }

    unless ($time =~ /^\d{2}:\d{2}:\d{2}$/) {
        warn "Invalid time format: $time\n";
        $time = none_val;
    }

    unless ($flag =~ /^(<=|=>|->|\*\*|==)$/) {
        $other_info = join(' ', $flag // '', $address // '', $other_info // '');
        $flag = none_val;
        $address = none_val;
    }

    if ($address eq ':blackhole:' && $other_info =~ /^<([^>]+)>/) {
        $address = $1;
        $other_info =~ s/^<[^>]+>\s*//;
    }

    unless ($address =~ /@/) {
        $address = none_val;
    }

    my $id_value = none_val . $line_id;
    if ($other_info =~ / id=([^\s]+)/) {
        $id_value = $1;
    }

    print "Date: $date\n";
    print "Time: $time\n";
    print "Message ID: $int_id\n";
    print "Flag: $flag\n";
    print "Address: $address\n";
    print "Other Info: $other_info\n";
    print "ID value: $id_value\n";
    print "\n";

    my $str = $line;
    $str =~ s/^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+//;
    if ($flag eq '<=') {
        my $insert_sql = "INSERT INTO message (created, id, int_id, str, status) VALUES (?, ?, ?, ?, ?)";
        my $sth = $dbh->prepare($insert_sql);
        $sth->execute($date . ' ' . $time, $id_value, $int_id, $str, 1);
        $sth->finish();
    } else {
        my $insert_sql = "INSERT INTO log (created, int_id, str, address) VALUES (?, ?, ?, ?)";
        my $sth = $dbh->prepare($insert_sql);
        $sth->execute($date . ' ' . $time, $int_id, $str, $address);
        $sth->finish();
    }
}
$dbh->disconnect();
close $log;