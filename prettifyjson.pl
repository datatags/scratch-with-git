use JSON::XS;

$project = join(" ", @ARGV);
open (PROJECT, $project) || die "Couldn't open $project: $!";
$json = JSON::XS->new->ascii->pretty;
$decoded = $json->decode(scalar <PROJECT>);
$output = $json->encode($decoded);
print $output;
