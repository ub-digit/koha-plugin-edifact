package Koha::Plugin::Se::Gu::Ub::EdifactUb;


## It's good practive to use Modern::Perl
use Modern::Perl;

use Carp;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Members;
use C4::Auth;
use C4::Biblio;
use C4::Items;
use Koha::EDI;
use Koha::DateUtils;
use Koha::Libraries;

## Here we set our plugin version
our $VERSION = 0.01;

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'UBfied version of edifact',
    author          => 'xljoha',
    date_authored   => '2017-09-15',
    date_updated    => "",
    minimum_version => undef,
    maximum_version => undef,
    version         => $VERSION,
    description     => '@TODO: Write a good description here',
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}


## The existance of a 'edifact' subroutine means the plugin is capable
## of running replacing the default Edifact modules for generated Edifcat messages
sub edifact {
    my ( $self, $args ) = @_;
    require Koha::Edifact;
    my $edifact = Koha::Edifact->new( $args );
    return $edifact;
}

sub edifact_order {
    my ( $self, $args ) = @_;
    
    require Koha::Plugin::Se::Gu::Ub::EdifactUb::Order;
    $args->{params}->{plugin} = $self;
    my $edifact_order = Koha::Plugin::Se::Gu::Ub::EdifactUb::Order->new( $args->{params} );
    return $edifact_order;
}


## If your tool is complicated enough to needs it's own setting/configuration
## you will want to add a 'configure' method to your plugin like so.
## Here I am throwing all the logic into the 'configure' method, but it could
## be split up like the 'report' method is.
sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};


    my $libraries = Koha::Libraries->as_list();

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template({ file => 'configure.tt' });
        my %branch_delivery_addresses;
        foreach my $lib (@$libraries) {
            $branch_delivery_addresses{'addresses'}{$lib->branchcode} = $self->retrieve_data($lib->branchcode);
        }

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            libraries => $libraries,
            addresses => $branch_delivery_addresses{'addresses'}
        );

        print $cgi->header(-charset => 'utf-8' );
        print $template->output();
    }
    else {   
        my %branch_delivery_addresses;
        foreach my $lib (@$libraries) {
            $branch_delivery_addresses{$lib->branchcode} = $cgi->param($lib->branchcode);
        }

        $self->store_data(\%branch_delivery_addresses);

        $self->go_home();
    }
}



