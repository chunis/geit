#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use Encode;

use LWP::Simple;
use HTML::TreeBuilder;

use Data::Dumper;


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
# print Dumper($tree), "\n";

#$tree->dump;   # print( ) a representation of the tree
# my $tt = $tree->address("0.1.2.3.0.0.0.6.1.0.0.0.2.3")->content;
# print Dumper $tt;

my $html = $tree->as_HTML();
$html = encode("gb2312", $html);
# print $html;

$html =~ s#(href="(?!http://))#$1http://www.itpub.net/#ig;
$html =~ s#(src="(?!http://))#$1http://www.itpub.net/#ig;
print $html;

$tree->delete;















