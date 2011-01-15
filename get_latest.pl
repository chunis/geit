#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use Encode;

use LWP::Simple;
use HTML::TreeBuilder;

use Data::Dumper;

sub _tmp_set_time {
	my $t = localtime();
	
	print "$t\n";
}

sub check_time_ok {			# time is not earlier than we asked
	my ($d, $t) = @_;		# d: created day, t: last time
	
	print "Day: $d, Time: $t\n";
	_tmp_set_time();
	
	return 1;
}


my $str;
my $url = "http://www.itpub.net/forum-61-1.html";
my $file = "test.html";
# $str = getstore($url, $file);
# $str = get($url);

open my $fh, "<", $file or die "Open $file failed: $!\n";
my @_str = <$fh>;
$str = join "", @_str;
$str = decode("gb2312",$str);


# my $tree = HTML::TreeBuilder->new_from_file($file);
my $tree = new HTML::TreeBuilder;
$tree->parse($str);
# print $tree->dump();
# $tree->dump;
# exit;


# for debug
# foreach my $b ($tree->find_by_tag_name('table')){
	# my $tab = $b->attr('bgColor');
	# $b->dump if $tab eq "#ffffff";
	# print "$tab\n" if $tab;
# }

my @date;
foreach my $form ($tree->find_by_tag_name('form')){
	my $attr = $form->attr('name');
	# $form->dump if $attr eq "moderate";
	# $form->delete;
	next unless defined $attr && $attr eq "moderate";
	
	foreach my $tab ($form->find_by_tag_name('table')){
		@date = ();
		foreach my $td ($tab->find_by_tag_name('td')){
			# print $td->as_text();
			my $t = $td->find_by_tag_name('span');
			if($t){
				push @date, $t->as_text();
			}
		}
		# print "$_\n" foreach(@date);
		print "$#date\n";
		if($#date >= 1){
			my $ok = check_time_ok($date[-2], $date[-1]);
			$tab->delete unless $ok;
		}
		else {
			print "date: @date\n";
			warn "Something wrong, check it again!";
		}
	}
}




my $html = $tree->as_HTML(undef, "  ");
$html = encode("gb2312", $html);
# print $html;

$html =~ s#(href="(?!http://))#$1http://www.itpub.net/#ig;
$html =~ s#(src="(?!http://))#$1http://www.itpub.net/#ig;
# print $html;

$tree->delete;



