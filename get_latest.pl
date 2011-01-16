#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use Encode;

use LWP::Simple;
use HTML::TreeBuilder;
use Data::Dumper;
use Date::Calc qw(Date_to_Time Time_to_Date);


# add 8 hours to fix the timezone issue in China
my $cur_time = time() + 8*3600;
my $sub_sec = get_argument_hours() * 3600;
my $fix_time = $cur_time - $sub_sec;
my $fix_day = Date_to_Time((Time_to_Date($fix_time))[0..2], 0, 0, 0);
print "fix_time: $fix_time\n";
print "fix_day : $fix_day\n";


my $str;
my $url = "http://www.itpub.net/forum-61-1.html";
my $file = "test.html";
my $output = "new.html";
# $str = getstore($url, $file);
# $str = get($url);

open my $fh, "<", $file or die "Open $file failed: $!\n";
my @_str = <$fh>;
$str = join "", @_str;

$str = decode("gb2312",$str);

my $tree = new HTML::TreeBuilder;
$tree->parse($str);
# $tree->dump;

# for debug
# foreach my $b ($tree->find_by_tag_name('table')){
	# my $tab = $b->attr('bgColor');
	# $b->dump if $tab eq "#ffffff";
	# print "$tab\n" if $tab;
# }

my @date;
my $ret_flag = 0;
foreach my $form ($tree->find_by_tag_name('form')){
	my $attr = $form->attr('name');
	# $form->dump if $attr eq "moderate";
	# $form->delete;
	next unless defined $attr && $attr eq "moderate";
	
	foreach my $tab ($form->find_by_tag_name('table')){
		if($ret_flag == 1){
			$tab->delete;
			next;
		}
		@date = ();
		foreach my $td ($tab->find_by_tag_name('td')){
			# print $td->as_text();
			my $t = $td->find_by_tag_name('span');
			if($t){
				push @date, $t->as_text();
			}
		}
		print "$_\n" foreach(@date);
		if($#date >= 1){
			my $ok = check_time_ok($date[-2], $date[-1]);
			print "ok = $ok\n";
			if($ok == 0){
				$tab->delete;
			}
			elsif($ok == -1){
				$tab->delete;
				$ret_flag = 1;
			}
		}
		else {
			print "date: @date\n";
			warn "Something wrong, check it again!";
		}
	}
}


my $html = $tree->as_HTML(undef, "  ");
$html = encode("gb2312", $html);

$html =~ s#(href="(?!http://))#$1http://www.itpub.net/#ig;
$html =~ s#(src="(?!http://))#$1http://www.itpub.net/#ig;
open my $ofh, ">", $output or die "Open $output for write failed: $!\n";
print $ofh $html;

$tree->delete;


sub usage {
	print "Usage:\n\t$0 <-Xh> <-Xd>\n";
	print "E.g.:\n";
	print "\t$0 -12h        : <= 12 hours\n";
	print "\t$0 -2d         : <=  2 days\n";
	print "\t$0 -2d -3h     : <= 25 hours\n";
	print "\t$0 -2d3h       : <= 25 hours\n";
	exit;
}

sub get_argument_hours {
	foreach(@ARGV){
		usage() if $_ =~ /-h/i || $_ =~ /-help/i;
	}
	foreach(@ARGV){
		usage() unless $_ =~ /[-\d]+[dh]/i;
	}
	
	my $hours = 0;
	foreach(@ARGV){
		if($_ =~ /(\d+)d/i){
			$hours += $1 * 24;
		}
		elsif($_ =~ /(\d+)h/i){
			$hours += $1;
		}
	}
	
	print "Check time before: $hours hours\n\n";
	$hours;
}

# time is not earlier than we asked
# return value:
#	0: keep going on
#	1: keep this item
# 	-1: not check any more items
sub check_time_ok {			
	my ($d, $t) = @_;		# d: created day, t: last time
	
	print "Day: $d, Time: $t\n";
	
	my @_ctime = split /-/, $d;
	my @_mtime = split /[- :]/, $t;
	
	push @_ctime, (0, 0, 0);
	push @_mtime, 0;
	
	my $ctime = Date_to_Time(@_ctime);
	my $mtime = Date_to_Time(@_mtime);
	
	if($ctime > $fix_day){
		return 1;
	}
	elsif($mtime < $fix_time){
		return -1;
	}
	
	return 0;
}

