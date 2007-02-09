# $Id$
package Beancounter::Pool;
use strict;

use subs qw();
use vars qw($VERSION);

use Carp;

use Beancounter::Constraints;

foreach my $package ( qw(Numbers Regex Strings Date General Composers Filters) )
	{
	# print STDERR "Requiring $package\n";
	eval "require Beancounter::$package";
	print STDERR $@ if $@;
	}

$VERSION = '0.10_01';

=head1 NAME

Beancounter - This is the description

=head1 SYNOPSIS

	use Beancounter::Constraints::Pool;

	my $pool = Beancounter::Constraints::Pool->new();

=head1 DESCRIPTION

=head2 Class methods

=over 4

=item new()

Creates a new pool to store Beancounter constraints

=cut

sub new
	{
	my( $class ) = @_;


	bless {}, $class;
	}

=item entry_class


Although this is really a class method, it's also an object method because
Perl doesn't know the difference. The return value, however, isn't designed
to be mutable. You may want to change it in a subclass, but the entire system
still needs to agree on what it is. Since I don't need to change it (although
I don't want to hard code it either), I have a method for it. If you need
something else, figure out the consequences and see if this could work another
way.

=cut

sub entry_class { __PACKAGE__ . "::Entry"; }

=back

=head2 Object methods

=over 4

=item add_to_pool( HASHREF )

You can pass these entries in the HASHREF:

	code        - the coderef to add to the pool
	name        - a name for the entry, which does not have to be unique
	description - explain what this coderef does
	args        - a reference to the arguments that the coderef closes over
	fields      - the input field names the coderef references

The method adds these fields to the entry:

	gv          - a GV reference from B::svref_2object($sub), useful for
				finding where an anonymous coderef came from

	created_by  - the name of the routine that added the entry to the pool

It returns the subroutine reference.

=cut

sub add_to_pool
	{
	require B;
	my @caller = main::__caller_chain_as_list();
	# print STDERR Data::Dumper->Dump( [\@caller],[qw(caller)] );
	my( $pool, $hash ) = @_;

	my( $sub, $name, $description, $args, $fields ) = @$hash{ qw(code name description args fields) };

	unless( ref $sub eq ref sub {} )
		{
		print STDERR Data::Dumper->Dump( [$hash],[qw(hash)] );
		croak "Code ref [$sub] is not a reference! $caller[1]{sub}";
		return;
		}
	elsif( exists $pool->{ $sub } )
		{
		#carp "Sub already enchanted!";
		#return $sub;
		no warnings;
		my $old_name = $pool->{ $sub }{name};
		#print STDERR "Previous name is $old_name; passed in name is $name\n"
			#if $ENV{DEBUG};
		}

	my $entry = $pool->{ $sub } || $pool->entry_class->new( $hash );

	$entry->{code} = $sub;

	$entry->set_name( do {
		if( defined $name ) { $name }
		elsif( defined $entry->get_name ) { $entry->get_name }
		elsif( ($name) = map { $_->{'sub'} =~ /^__|add_to_pool/ ? () :  $_->{'sub'} } @caller )
			{
			$name;
			}
		else
			{
			"Unknown";
			}
		} );

	$entry->set_description(
		$entry->get_description
		  ||
		$description
		  ||
		"This spot left intentionally blank by a naughty programmer"
		);

	$entry->{created_by} ||= [ map { $_->{'sub'} =~ /add_to_pool/ ? () :  $_->{'sub'} } @caller ];

	$entry->set_gv( B::svref_2object($sub)->GV );

	$pool->{ $sub } = $entry;

	$sub;
	}

=item get_from_pool( CODEREF )

Gets the entry for the specified CODEREF. If the CODEREF is not in the pool,
it returns false.

The return value is an entry instance.

=cut

sub get_from_pool
	{
	my( $pool, $sub ) = @_;

	return exists $pool->{$sub} ? $pool->{$sub} : ();
	}

=item get_all_keys

Returns an unordered list of the keys (entry IDs) in the pool.
Although you probably know that the pool is a hash, use this just in
case the data structure changes.

=cut

sub get_all_keys { keys %{ $_[0] } }

=item comprise( COMPOSED_CODEREF, THE_OTHER_CODEREFS )

Tell the pool that the COMPOSED_CODEREF is made up of THE_OTHER_CODEREFS.

	$pool->comprise( $sub, @component_subs );

=cut

sub comprise
	{
	my( $pool, $compriser, @used ) = @_;

	$pool->get_from_pool( $compriser )->add_bit( @used );
	}


=back

=head1 Beancounter::Pool::Entry

=cut

package Beancounter::Pool::Entry;

use Carp qw(carp);

=over 4

=item my $entry = Beancounter::Pool::Entry->new( HASHREF )

=cut

sub new
	{
	my $class = shift;

	my $self = bless {}, $class;

	$self->{comprises} ||= [];

	$self;
	}


=item $entry->get_gv()

Get the GV object associated with the entry. The GV object comes from
the svref_2object(SVREF) function in the C<B> module. Use it to get
information about the coderef's creation.

	my $entry = $pool->get_entry( $coderef );
	my $gv    = $entry->get_gv;

	printf "$coderef comes from %s line %s\n",
		map { $gv->$_ } qw( FILE LINE );

The C<B> documentation explains what you can do with the GV object.

=cut

sub get_gv          { $_[0]->{gv}  || Object::Null->new }

=item $entry->get_name()

Get the name for the entry.

=cut

sub get_name        { $_[0]->{name}        }

=item $entry->get_description()

Get the description for the entry.

=cut

sub get_description { $_[0]->{description} }

=item $entry->get_coderef()

Get the coderef for the entry. This is the actual reference that you
can execute, not the string form used for the pool key.

=cut

sub get_coderef     { $_[0]->{code}        }

=item $entry->get_comprises()

Get the subroutines that this entry composes. A coderef might simply
combine other code refs, and this part gives the map. Use it recursively
to get the tree of code refs that make up this entry.

=cut

sub get_comprises   { $_[0]->{comprises}   }

=item $entry->get_created_by()

Get the name of the routine that added the entry to the pool. This
is handy for tracing the flow of code refs around the program. Different
routines my make coderefs with the same name, so you also want to know
who created it. You can use this with C<get_gv> to get file and line numbers
too.

=cut

sub get_created_by  { ref  $_[0]->{created_by} ? $_[0]->{created_by} : [] }

=item $entry->get_fields()

=cut

sub get_fields      { [ keys %{ $_[0]->entry( $_[1] )->{fields} } ] }

=item $entry->set_name( SCALAR )

Set the entry's name. Usually this happens when you add the object
to the pool, but you might want to update it to show more specific or higher
level information. For instance, if you added the code ref with a low
level routine that named the entry "check_number", a higher order routine
might want to reuse the same entry but pretend it created it by setting
the name to "check_integer", a more specific sort of check.

=cut

sub set_name        { $_[0]->{name}        = $_[1] }

=item $entry->set_description( SCALAR )

Set the entry's description. Usually this happens when you add the object
to the pool, but you might want to update it to show more specific or higher
level information. See C<get_name>.

=cut

sub set_description { $_[0]->{description} = $_[1] }

=item $entry->set_gv( SCALAR )

Set the GV object for the entry. You probably don't want to do this
yourself. The pool does it for you when it adds the object.

=cut

sub set_gv          { $_[0]->{gv}          = $_[1] }

=item $entry->add_bit( CODEREFS )

I hate this name, but this is the part that adds the CODEREFS to the
entry that composes it.

=cut

sub add_bit
	{
	my $entry = shift;

	# can things get in here twice
	push @{ $entry->{comprises} }, map { "$_" } @_;
	}

=item $entry->dump

=cut

sub dump
	{
	require Data::Dumper;

	Data::Dumper->Dump( [ $_[0]->entry( $_[1] ) ], [ "$_[1]" ] )
	}

sub applies_to_fields
	{
	my( $class, $sub, @fields ) = @_;

	foreach my $field ( @fields )
		{
		$class->registry->{$sub}{fields}{$field}++;
		$class->registry->{_fields}{$field}{$sub}++;
		}
	}

sub main::__caller_chain_as_list
	{
	my $level = 0;
	my @Callers = ();

	while( 1 )
		{
		my @caller = caller( ++$level );
		last unless @caller;

		push @Callers, {
			level   => $level,
			package => $caller[0],
			'sub'   => $caller[3] =~ m/(?:.*::)?(.*)/,
			};
		}

	#print STDERR Data::Dumper->Dump( [\@Callers], [qw(callers)] ), "-" x 73, "\n";
	@Callers;
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
