use strict;
use Module::Build;

my %arguments = (
    #create_makefile_pl => 'passthrough',
    create_makefile_pl  => 'traditional',
    license            => 'perl',
    module_name        => 'Image::VisualConfirmation',
    requires           => {
        'Imager'            => 0.48,
        'Path::Class'       => 0,
    },
    build_requires      => {
        'Test::Exception'   => 0
    },
);

my $build = Module::Build->new(%arguments);
$build->add_build_element('ttf');
$build->create_build_script();
