use Test::More tests => 4;
BEGIN { use_ok('Image::VisualConfirmation') };

my    $vc = Image::VisualConfirmation->new();

isa_ok($vc, 'Image::VisualConfirmation');

ok($vc->code =~ m/\A \w+ \z/xms, 'Code creation');

my $vc_image = $vc->image;
isa_ok($vc_image, 'Imager');

