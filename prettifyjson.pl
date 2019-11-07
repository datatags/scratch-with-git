use JSON::XS;

$project = join(" ", @ARGV);
open (PROJECT, $project) || die "Couldn't open $project: $!";
$json = JSON::XS->new->ascii->pretty;
$/ = undef;
$data = <PROJECT>;
$decoded = $json->decode($data);
$json->canonical();
$output = $json->encode($decoded);
print $output;
