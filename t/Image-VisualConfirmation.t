use Test::More tests => 6;
BEGIN { use_ok('Image::VisualConfirmation') };

my $vc = Image::VisualConfirmation->new();

isa_ok($vc, 'Image::VisualConfirmation');

ok($vc->code =~ m/\A \w+ \z/xms, 'Code retrieval');

my $vc_image = $vc->image;
isa_ok($vc_image, 'Imager');

$vc->create_new_image({ code => 'marcus' });
ok($vc->code eq 'marcus', 'Code provided by user');

$vc->create_new_image({ code => sub { return 'julius' } });
ok($vc->code eq 'julius', 'Code provided by user');
