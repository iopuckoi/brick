# $Id$
package Brick::Bucket;
use strict;

use subs qw();
use vars qw($VERSION);

use Storable qw(dclone);

$VERSION = '0.20_01';

=head1 NAME

Brick - This is the description

=head1 SYNOPSIS

	use Brick::Constraints;

=head1 DESCRIPTION

See C<Brick::Constraints> for the general discussion of constraint
creation.

=head2 Utilities

=over 4

=item matches_regex( HASHREF )

Create a code ref to apply a regular expression to the named field.

	field - the field to apply the regular expression to
	regex - a reference to a regular expression object ( qr// )

=cut

sub _matches_regex
	{
	my( $bucket, $hash ) = @_;

	my @caller = main::__caller_chain_as_list();

  	unless( eval { $hash->{regex}->isa( ref qr// ) } )
    	{
    	carp( "Argument to $caller[0]{'sub'} must be a regular expression object" );
    	return sub {};
		}

	$bucket->add_to_bucket ( {
		name        => $caller[0]{'sub'},
		description => ( $hash->{description} || "Match a regular expression" ),
		#args        => [ dclone $hash ],
		fields      => [ $hash->{field} ],
		code        => sub {
			die {
				message => "The value in $hash->{field} [$_[0]->{ $hash->{field} }] did not match the pattern",
				field   => $hash->{field},
				handler => $caller[0]{'sub'},
				} unless $_[0]->{ $hash->{field} } =~ m/$hash->{regex}/;
			},
		} );

	}

=back

=head1 TO DO

Regex::Common support

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