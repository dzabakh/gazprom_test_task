#!/usr/bin/perl
use strict;
use warnings;
use CGI qw(:standard);
use DBI;

# Database connection parameters
my $dsn = "DBI:Pg:dbname=dzabakh;host=localhost;port=5432";
my $username = "dzabakh";
my $password = "";

# Create CGI object
my $cgi = CGI->new;

# Get the address from the form
my $address = $cgi->param('address');

# Prepare SQL queries
my $message_query = <<'END_SQL';
SELECT created, str, int_id FROM message WHERE str LIKE ? ORDER BY int_id LIMIT 101
END_SQL

my $log_query = <<'END_SQL';
SELECT created, str, int_id FROM log WHERE address = ? ORDER BY int_id LIMIT 101
END_SQL

# Connect to the database
my $dbh = DBI->connect($dsn, $username, $password, { RaiseError => 1, AutoCommit => 1 });

# Execute the queries
my $message_sth = $dbh->prepare($message_query);
$message_sth->execute('%' . $address . '%');

my $log_sth = $dbh->prepare($log_query);
$log_sth->execute($address);

# Combine the results
my @results;

while (my $row = $message_sth->fetchrow_hashref) {
    push @results, $row;
}

while (my $row = $log_sth->fetchrow_hashref) {
    push @results, $row;
}

# Sort results by int_id
@results = sort { $a->{int_id} cmp $b->{int_id} } @results;

# Limit results to 100 and check if there are more
my $more_records = @results > 100;
@results = @results[0..99] if $more_records;

# Disconnect from the database
$dbh->disconnect;

# Print the HTML header
print $cgi->header('text/html');
print $cgi->start_html('Search Results');
print $cgi->h1('Search Results');

# Display the results
print "<table border='1'>";
print "<tr><th>Created</th><th>Str</th><th>Int ID</th></tr>";

foreach my $result (@results) {
    print "<tr>";
    print "<td>" . $result->{created} . "</td>";
    print "<td>" . $result->{str} . "</td>";
    print "<td>" . $result->{int_id} . "</td>";
    print "</tr>";
}

print "</table>";

# Print a message if there are more than 100 records
if ($more_records) {
    print "<p>More than 100 records found. Showing the first 100 records.</p>";
}

print $cgi->end_html;