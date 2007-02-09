# $Id$
package Beancounter::Pool;
use strict;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.10_01';

=head1 NAME

Beancounter::Constraints - Connect the input data to the closures in the pool

=head1 SYNOPSIS

	use Beancounter;

=head1 DESCRIPTION

=over 4

=item $pool->__make_constraint( CODEREF, INPUT_HASH_REF )

Turn a closure into a constraint by providing the bridge between the
input hash and code reference.

Call this in your top level generator after you have composed all the
pieces you want.

=cut

sub __make_constraint # may need to change name to make generic
	{
    my( $pool, $validator, $hash ) = @_;

	$hash ||= {};

 	my @callers = main::__caller_chain_as_list();

	if( $callers[1]{'sub'} =~ m/^_/ )
		{
		carp "$callers[1]{'sub'} called from sub with leading underscore. Are you sure you want that?";
		}

	my $name = $hash->{profile_name} || $callers[-1]{'sub'} || 'Anonymous';

 	unless(
 		eval { $validator->isa( ref sub {} ) }    or
 		UNIVERSAL::isa( $validator, ref sub {} )
 		)
    	{
    	croak( "Argument to $callers[1]{'sub'} must be a code reference [$validator]: $@" );
    	return $pool->add_to_pool( {
    		code        => sub {},
    		name        => "Null subroutine",
    		description => "This sub does nothing, because something didn't happen correctly."
    		} );
		}

    my $constraint = $pool->add_to_pool( {
    	name        => $name,
    	description => "Beancounter constraint sub for $name",

    	code        => sub {
    		my $input_hash = shift;

			my $result = eval{ $validator->( $input_hash ) };
			die if $@;

			return 1;
			},
		} );

    $pool->comprise( $constraint, $validator );

    return $constraint;
	}


=item __make_dfv_constraint

Adapter for Data::FormValidator

=cut

sub __make_dfv_constraint # may need to change name to make generic
	{
    my( $pool, $validator, $hash ) = @_;

	$hash ||= {};

 	my @callers = main::__caller_chain_as_list();

	my $name = $hash->{profile_name} || $callers[-1]{'sub'} || 'Anonymous';

 	unless(
 		eval { $validator->isa( ref sub {} ) }    or
 		UNIVERSAL::isa( $validator, ref sub {} )
 		)
    	{
    	carp( "Argument to $callers[1]{'sub'} must be a code reference [$validator]: $@" );
    	return $pool->add_to_pool( { code => sub {}, name => "Null subroutine",
    		description => "This sub does nothing, because something didn't happen correctly."
    		} );
		}

    my $constraint = $pool->add_to_pool( {
    	name        => $name,
    	description => "Data::FormValidator constraint sub for $callers[-1]{'sub'}",

    	code        => sub {
			my( $dfv ) = @_;

			$dfv->name_this( $callers[-1]{'sub'} );
			my( $field, $value ) = map {
				$dfv->${\ "get_current_constraint_$_"}
				} qw(field value);

			my $hash_ref = $dfv->get_filtered_data;

			return unless $validator->( $hash_ref );

			return $field;
			},
		} );

    $pool->comprise( $constraint, $validator );

    return $constraint;
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in CVS, as well as all of the previous releases.

	http://sourceforge.net/projects/brian-d-foy/

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2007, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
