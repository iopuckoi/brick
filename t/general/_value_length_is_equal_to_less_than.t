#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Beancounter::General' );
use_ok( 'Beancounter::Pool' );

use lib qw( t/lib );
use_ok( 'Mock::Pool' );

my $pool = Mock::Pool->new;
isa_ok( $pool, 'Mock::Pool' );
isa_ok( $pool, Mock::Pool->pool_class );

my $sub = $pool->_value_length_is_equal_to_less_than( 
	{
	field          => 'string',
	maximum_length => 10,
	}
	);
	
isa_ok( $sub, ref sub {}, "_value_length_is_equal_to_less_than returns a code ref" );

{
my $result = eval { 
	$sub->( { string => "Buster" } ) 
	}; 
	
ok( defined $result, "Result succeeds" );
diag( "Eval error: $@" ) unless defined $result;
}

{
my $result = eval { 
	$sub->( { string => "BusterBean!" } ) 
	}; 

my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
}