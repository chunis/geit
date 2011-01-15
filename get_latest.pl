#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use LWP::Simple;
use Data::Dumper;

use HTML::TreeBuilder;


my $url = "http://www.itpub.net/forum-61-1.html";
my $file = "test.html";
# my $ret = getstore($url, $file);
# my $ret = get($url);

# open my $fh, "<", "test2.html";
# my $content = join("", <$fh>);
# my @forms = $content =~ /<table.*?thread.*<\/table>/gs;
# my @forms = $content =~ /<table.*?smalltxt.*?<\/table>/gs;
# my $count = 0;
# while($content =~ /(<table.*?<\/table>)/gs){
	# print "----------- $count\n";
	# $count++;
# }
# print scalar @forms;
# print $forms[0];
# print $forms[1];


my $root = HTML::TreeBuilder->new_from_file($file);
#$root->dump;   # print( ) a representation of the tree
my $tt = $root->address("0.1.2.3.0.0.0.6.1.0.0.0.2.3")->content;
print Dumper $tt;


$root->delete; # erase this tree because we're done with it















