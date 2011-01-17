#!/usr/bin/perl

# Author: Chunis Deng (chunchengfh@gmail.com)
# Version: 0.2 @ 2011/01/18


use strict;
use warnings;

use utf8;
use Encode;

use LWP::Simple;
use HTML::TreeBuilder;
use Data::Dumper;
use Date::Calc qw(Date_to_Time Time_to_Date);


my @a_content;
my $ret_flag = 0;
my $super_flag = 0;
my $output = "output.html";
my $myparent;
my @trees;

# add 8 hours to fix the timezone issue in China
my $cur_time = time() + 8*3600;
my $sub_sec = get_argument_hours() * 3600;
my $fix_time = $cur_time - $sub_sec;
my $fix_day = Date_to_Time((Time_to_Date($fix_time))[0..2], 0, 0, 0);
print "fix_time: $fix_time\n";
print "fix_day : $fix_day\n";


my $tree = new HTML::TreeBuilder;

my $page = 1;
while($ret_flag == 0){		# need more items
	print "-----------> process page = $page now...\n";
	get_more_page($page);
	$page++;
}

$myparent->push_content(@a_content);

my $html = $tree->as_HTML(undef, "  ");
$html = encode("gb2312", $html);
$html =~ s#(href="(?!http://))#$1http://www.itpub.net/#ig;
$html =~ s#(src="(?!http://))#$1http://www.itpub.net/#ig;
open my $ofh, ">", $output or die "Open $output for write failed: $!\n";
print $ofh $html;

$tree->delete;
foreach (@trees){
	$_->delete;
}


sub usage {
	print "Usage:\n\t$0 <-Xh> <-Xd>\n";
	print "E.g.:\n";
	print "\t$0 -12h        : <= 12 hours\n";
	print "\t$0 -2d         : <=  2 days\n";
	print "\t$0 -2d -3h     : <= 25 hours\n";
	print "\t$0 -2d3h       : <= 25 hours\n";
	exit;
}

sub get_more_page {
	my $page = shift;

	my @date;
	my $newtree = new HTML::TreeBuilder;
	my $_tree = $page == 1? $tree : $newtree;
	
	my $url = "http://www.itpub.net/forum-61-$page.html";
	my $str = get($url);
	$str = decode("gb2312",$str);

	$_tree->parse($str);
	$_tree->eof();

	foreach my $form ($_tree->find_by_tag_name('form')){
		my $attr = $form->attr('name');
		# $form->dump if $attr eq "moderate";
		# $form->delete;
		next unless defined $attr && $attr eq "moderate";
		
		foreach my $tab ($form->find_by_tag_name('table')){
			if($super_flag == 0){
				$super_flag = 1;
				$myparent = $tab->parent;
			}

			if($ret_flag == 1){
				$tab->delete;
				next;
			}
			
			if($page == 1){
				# check if the item is fixed as the top items
				my $top_item = 0;
				foreach my $img ($tab->find_by_tag_name('img')){
					my $img_attr = $img->attr('src');
					$top_item = 1 if $img_attr =~ m#images/itpub/pin_[1-3].gif#;
				}
				next if $top_item == 1;
			}

			@date = ();
			foreach my $td ($tab->find_by_tag_name('td')){
				# print $td->as_text();

				my $t = $td->find_by_tag_name('span');
				if($t){
					push @date, $t->as_text();
				}
			}
			# print "$_\n" foreach(@date);
			if($#date >= 1){
				my $ok = check_time_ok($date[-2], $date[-1]);
				# print "ok = $ok\n";
				if($ok == 0){
					$tab->delete;
				}
				elsif($ok == -1){
					$tab->delete;
					$ret_flag = 1;
				}
				elsif($ok == 1){
					print "\tThis item is saved\n";
					push @a_content, $tab;
				}
			}
			else {
				print "date: @date\n";
				warn "Something wrong, check it again!";
			}
		}
	}
	$_tree = undef;
	push @trees, $newtree;
}


sub get_argument_hours {
	usage() unless @ARGV;
	
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
	
	if($ctime >= $fix_day){
		return 1;
	}
	elsif($mtime < $fix_time){
		return -1;
	}
	
	return 0;
}
