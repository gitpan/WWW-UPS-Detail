package WWW::UPS::Detail;
use strict;
#use warnings;
use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/upscheck/;
our $VERSION = '0.2';
use LWP::Simple;
use LWP::UserAgent;

sub upscheck {
	my $paketnummer = shift;
	my $language = shift || 'de';

	my $lang;
	if($language eq "de"){
		$lang = '&Lang=ger';
	}
	my @newdata;
	my $firstdata1 = get("http://wwwapps.ups.com/ietracking/tracking.cgi?tracknum=$paketnummer&IATA=$language$lang");
	my($loc) = ($firstdata1 =~ /<input type="hidden" name="loc" value="([^"]*)"/);
	my($hiddensession) = ($firstdata1 =~ /<INPUT name="HIDDEN_FIELD_SESSION" type="HIDDEN" value="([^"]*)">/);
	#my($detail) = ($firstdata1 =~ /<legend>Tracking Information<\/legend>(.*)<form name="progressForm" action="http:\/\/wwwapps.ups.com\/WebTracking\/detail" method="post">/s);#old - release
	my($detail) = ($firstdata1 =~ /<h2>Tracking Detail<\/h2>(.*)<form name="detailForm" action="https?:\/\/wwwapps.ups.com\/WebTracking\/detail" method="post">/s);#new - mai 2012
	$detail =~ s/[\n\r]//g;
	$detail =~ s/\s\s*/ /g;
	#my($paketnumber) = ($detail =~ /<dt><label>(?:Kontrollnummer|Tracking Number):<\/label><\/dt>\s*<dd>(\w+)/);#old
	#my($weight) = ($detail =~ /<dt><label>(?:Gewicht|Weight):<\/label><\/dt>\s*<dd>([\.\,\w\s]+)/);#old
	#my($service) = ($detail =~ /<dt><label>Service:<\/label><\/dt>\s*<dd>([^<]*)<\/dd>/);#old
	#my($type) = ($detail =~ /<dt><label>(?:Typ|Type):<\/label><\/dt>\s*<dd>([^<]*)<\/dd>/);#old
	#my($deliveryto) = ($detail =~ /<dt><label>\s*(?:Ausgeh&auml;ndigt an|Delivered To):\s*<\/label>\s*<\/dt>\s*<dd>([^<]*)<\/dd>/i);#old
	my($paketnumber) = ($detail =~ /<dt><label(?> for=""|)>(?:Kontrollnummer|Tracking Number):<\/label><\/dt>\s*<dd>(\w+)/);#new
	if(!defined($paketnumber) || ($paketnumber eq "")){#new
		($paketnumber) = ($detail =~ /<input type="hidden" name="trackNums" value="([^"]+)">/i);#new
	}#new
	my($weight) = ($detail =~ /<dt><label(?> for=""|)>(?:Gewicht|Weight):<\/label><\/dt>\s*<dd>([\.\,\w\s]+)/);#new
	my($service) = ($detail =~ /<dt><label(?> for=""|)>Service:<\/label><\/dt>\s*<dd>([^<]*)<\/dd>/);#new
	if(!defined($service) || ($service eq "")){#new
		($service) = ($detail =~ /<p><a href="[^"]*" class="service">\s*([^<]*)\s*<\/a><\/p>/i);#new
	}#new
	$service =~ s/\xAE//g;#new
	my($type) = ($detail =~ /<dt><label(?> for=""|)>(?:Typ|Type):<\/label><\/dt>\s*<dd>([^<]*)<\/dd>/);#new
	my($deliveryto) = ($detail =~ /<dt>\s*<label(?> for=""|)>\s*(?:Ausgeh&auml;ndigt an|Delivered\s*To|To):\s*<\/label>\s*<\/dt>\s*<dd>\s*(?><strong>|)([^<]*)(?><\/strong>|)\s*<\/dd>/i);#new
	$deliveryto =~ s/&nbsp;/ /g;#new
	$deliveryto =~ s/^\s*//g;
	$deliveryto =~ s/\s\s*/ /g;
	$deliveryto =~ s/,\s*/, /g;
	#my($location) = ($detail =~ /<dt><label>(?:Ort|Location):<\/label><\/dt>\s*<dd>([^<]*)<\/dd>/i);#old
	#my($deliveryon) = ($detail =~ /<dt><label>\s*(?:Zugestellt am|Delivered On):\s*<\/label>\s*<\/dt>\s*<dd>([^<]*)<\/dd>/i);#old
	my($location) = ($detail =~ /<dt><label(?> for=""|)>(?:Ort|Location):<\/label><\/dt>\s*<dd>([^<]*)<\/dd>/i);#new
	my($deliveryon) = ($detail =~ /<dt><label(?> for=""|)>\s*(?:Zugestellt am|Delivered On):\s*<\/label>\s*<\/dt>\s*<dd>([^<]*)<\/dd>/i);#new
	$deliveryon =~ s/&nbsp;/ /g;#new
	$deliveryon =~ s/^\s*//g;
	$deliveryon =~ s/\s\s*/ /g;
	$deliveryon =~ s/,\s*/, /g;
	my($billedon) = ($detail =~ /(?:in Rechnung gestellt am|Billed On):\s*<\/label>\s*<\/dt>\s*<dd>([^<]*)<\/dd>/i);
	$billedon =~ s/^\s*//g;
	$billedon =~ s/\s\s*/ /g;
	$billedon =~ s/,\s*/, /g;
	#my($signedby) = ($detail =~ /(?:Unterschrieben von|Signed By):\s*<\/label>\s*<\/dt>\s*<dd>([^<]*)<\/dd>/i);#old
	my($signedby) = ($detail =~ /(?:Unterschrieben von|Signed\s*By):\s*<\/label>\s*<\/dt>\s*<d[dt]>([^<]*)<\/d[dt]>/i);#new
	$signedby =~ s/[\n\r]//g;
	$signedby =~ s/^\s*//g;
	$signedby =~ s/\s\s*/ /g;
	$signedby =~ s/,\s*/, /g;
	my($laststatus) = ($detail =~ /"(?:st_del_de_de_pgx_hh_linkedText|st_del_en_us_pgx_hh_linkedText)" class="pgx_hh_linkedText">\s*<b>\s*([^<]*)\s*<\/b>\s*<img/i);
	if(!defined($laststatus) || ($laststatus eq "")){
		($laststatus) = ($detail =~ /<div id="ttc_tt_spStatus">\s*<!-- cms: id="[^">]*" actiontype="0" -->\s*<h3>\s*([^<]*)\s*<\/h3>/i);
	}
	$laststatus =~ s/^\s*//g;
	$laststatus =~ s/\s\s*/ /g;
	$laststatus =~ s/,\s*/, /g;

	$hiddensession =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	my %post;
	$post{'HIDDEN_FIELD_SESSION'} = $hiddensession;
	if($language eq "de"){
		$post{'loc'} = 'de_DE';
	}else{
		$post{'loc'} = 'en_US';
	}
	$post{'datakey'} = 'line1';
	$post{'progressIsLoaded'} = 'N';
	$post{'shipmentsAreLoaded'} = 'N';
	$post{'showPkgProgress'} = 'false';
	$post{'showAsscShipments'} = 'false';
	$post{'showSpPkgProg'} = 'Paketfortschritt anzeigen';
	my $ua = LWP::UserAgent->new;
	my $response = $ua->post('http://wwwapps.ups.com/WebTracking/detail', \%post );
	my $data1 = $response->content;

	my($data) = ($data1 =~ /<table border="0" cellpadding="0" cellspacing="0" class="dataTable">(.*?)<\/table>/s);
	$data =~ s/[\n\r]//g;

	my $lastort;
	while($data =~ /<tr(.*?)<\/tr>/ig){
		my $detailone = $1;

		#my($ort,$datum,$zeit,$daten) = ($detailone =~ /<td nowrap VALIGN="top">([^<]*)<\/td>\s*<td nowrap VALIGN="top">([^<]*)<\/td>\s*<td nowrap VALIGN="top">([^<]*)<\/td>\s*<td VALIGN="top">([^<]*)<\/td>/);#old
		my($ort,$datum,$zeit,$daten) = ($detailone =~ /<td[^>]*>([^<]*)<\/td>\s*<td[^>]*>([^<]*)<\/td>\s*<td[^>]*>([^<]*)<\/td>\s*<td[^>]*>([^<]*)<\/td>/);#new
		next unless($daten);
		$datum =~ s/\s\s*/ /g;
		$datum =~ s/^\s*|\s*$//g;
		$ort =~ s/\s\s*/ /g;
		$ort =~ s/^\s*|\s*$//g;
		$zeit =~ s/\s\s*/ /g;
		$zeit =~ s/^\s*|\s*$//g;
		$daten =~ s/\s\s*/ /g;
		$daten =~ s/^\s*|\s*$//g;
		$ort = $lastort unless($ort);
		$lastort = $ort;
		my %details;
		$details{'datum'} = $datum . " " . $zeit;
		$details{'ort'} = $ort;
		$details{'daten'} = $daten;
		push(@newdata,\%details)
	}

	return(\@newdata,({
		'shipnumber' => $paketnumber,
		'weight' => $weight,
		'service' => $service,
		'type' => $type,
		'deliveryto' => $deliveryto,
		'deliveryon' => $deliveryon,
		'billedon' => $billedon,
		'location' => $location,
		'signedby' => $signedby,
		'laststatus' => $laststatus
		})
	);
}


=pod

=head1 NAME

WWW::UPS::Detail - Perl module for the UPS online tracking service with details.

=head1 SYNOPSIS

	use WWW::UPS::Detail;
	my($newdata,$other) = upscheck('paketnumber','de');#de for text in german

	foreach my $key (keys %$other){# shipnumber, weight, service, type, deliveryto, deliveryon, billedon, location, signedby, laststatus
		print $key . ": " . ${$other}{$key} . "\n";
	}
	print "\nDetails:\n";

	foreach my $key (@{$newdata}){
		#foreach my $key2 (keys %{$key}){#datum, ort, daten
		#	print ${$key}{$key2};
		#	print "\t";
		#}

		print ${$key}{ort};
		print "\t";
		print ${$key}{datum};
		print "\t";
		print ${$key}{daten};
		print "\n";
	}
	# see http://www.ups.com/content/de/de/tracking/tracking/description.html

=head1 DESCRIPTION

WWW::UPS::Detail - Perl module for the UPS online tracking service with details.

=head1 AUTHOR

    Stefan Gipper <stefanos@cpan.org>, http://www.coder-world.de/

=head1 COPYRIGHT

	WWW::UPS::Detail is Copyright (c) 2012 Stefan Gipper
	All rights reserved.

	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO



=cut
