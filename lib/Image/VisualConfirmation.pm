package Image::VisualConfirmation;

use 5.008;
use strict;
use warnings;

use Carp;
use Imager();
use List::Util qw/shuffle/;

our $VERSION = '0.01';

# We want to avoid all possible confusions for the user: 0, upper and
# lower-case 'o', lower-case 'l' and '1', 'j'
our @LETTERS = (
    'A'..'N', 'P'..'Z', 'a'..'i', 'k', 'm', 'n', 'p'..'z', '2'..'9'
);

our $DEFAULT_TYPE         = 'png';
our $DEFAULT_FONT_FACE    = 'Arial';        # For Win32
our $DEFAULT_FONT_FILE    = 'Vera.ttf';     # For all other platforms
our $DEFAULT_FONT_SIZE    = 20;
our $DEFAULT_BGCOLOR      = '#f9e680';
our $DEFAULT_CODE_LENGTH  = 6;

# Instantiate a new object, and then call create_new_image which
# does the real work
sub new {
    my ($class, $options) = @_;

    my $self = {};
    bless $self, $class;

    # Create an image from the code
    $self->create_new_image($options);
        
    return $self;
}

# Create a new codice and image
sub create_new_image {
    my ($self, $options) = @_;
        
    croak "Arguments must be an hashref"
        if ( $options ) && ( ref($options) ne 'HASH' );

    # If we're on Win32, see if the font face is passed, otherwise
    # grab the default one
    if ( $^O =~ m/Win/xms ) {
        $self->{font_face} = $options->{font_face} || $DEFAULT_FONT_FACE;
    }

    # Now see if there is a font_file parameter, which is the one
    # needed on Unix (and will override font_face on Windows)
    if ( exists $options->{font_file} )
    {
        $self->{font_file} = $options->{font_file};
    }
    
    # Otherwise we search for the default, but only if we're not
    # on Windows (we'll use the font_face defined above in that case)
    elsif ( $^O !~ m/Win/xms ) {
        my $font_file = __FILE__;

        $font_file =~ s/\.pm\z//;
        $font_file .= q{/} . $DEFAULT_FONT_FILE;

        croak 'Error getting the default font file. Please specify one'
            if !-e $font_file;
        $self->{font_file} = $font_file;
    }

    $self->{code_length} = $options->{code_length} || $DEFAULT_CODE_LENGTH;
    $self->{font_size} = $options->{font_size} || $DEFAULT_FONT_SIZE;
    $self->{bgcolor} = $options->{bgcolor} || $DEFAULT_BGCOLOR;
    
    # Generate a confirmation code
    $self->{code} = $self->_generate_code();
    
    my ($width, $height);
    if ( (exists $options->{width}) && (exists $options->{height}) ) {
        $width  = $options->{width};
        $height = $options->{heigh};
    }

    # Auto-compute the size of the image (if it's not passed)
    else {
        $width
            = int($self->{font_size}*1.2) * $self->{code_length} + 20;
        $height = $self->{font_size} + 10;
    }

    $self->{image} = Imager->new(
        xsize    => $width,
        ysize    => $height,
    ) or croak "Can't create image objct: $!";

    $self->{image}->box( filled => 1, color => $self->{bgcolor} );

    $self->_create_string();
    
    # Rotate the image just to confuse things a bit
    my $degrees = int(rand 10) + 10;
    $degrees = (qw/+ -/)[int(rand 2)] . $degrees;
    $self->{image}
        = $self->{image}->rotate(degrees => $degrees, back => $self->{bgcolor})
            or croak "Can't create image objct: $!";
}

# Return the code in a string
sub code {
    my $self = shift;

    return $self->{code};
}

# Return the Imager object for the image
sub image {
    my $self = shift;

    return $self->{image};
}

# Return the raw data of an image, in the format specified (PNG if
# not otherwise stated)
sub image_data {
    my ($self, $options) = @_;
    
    croak "Arguments must be an hashref"
        if ( $options ) && ( ref($options) ne 'HASH' );

    my $image_type = $options->{type} || $DEFAULT_TYPE;
    
    my $image = $self->{image};
    my $image_data;
    
    $image->write(
        type => 'png',
        data => \$image_data
    ) or croak $image->errstr;

    return $image_data;
}

# Generate the code for the image
sub _generate_code {
    my $self = shift;

    my $code = '';
    for my $i(1 .. $self->{code_length}) {
        $code .= $LETTERS[ rand $#LETTERS ];
    }
    
    return $code;
}

# Create the funky string in the image
sub _create_string {
    my $self = shift;

    my $image = $self->{image};
    my $code  = $self->{code};
    
    # Generate some colors
    my @font_attrs;
    for my $i(1 .. length($code)) {
        my @colors;
        
        my $j = 0;
        while ($j < 2) {
            push @colors, int(rand 255)+1;
            $j++;
            
            # TODO: ensure colors do no match backgroup too much
        }
        
        push @font_attrs, {
            red     => shift @colors,
            green   => shift @colors,
            blue    => shift @colors,
        };
    }
    
    # Render the font
    my $font;
    if ( exists $self->{font_file} ) {
        $font = Imager::Font->new(
            file  => $self->{font_file},
        ) or croak "Font file not found: $!";
    }
    else {
        $font = Imager::Font->new(
            face  => $self->{font_face},
        ) or croak "Font not found: $!";
    }

    my @code_chars = split //, $code;
    my $pos_x = 10;
    for my $i(0 .. length($code)-1) {
        my $color = Imager::Color->new(
            $font_attrs[$i]{red}, $font_attrs[$i]{blue}, $font_attrs[$i]{green},
        );
        
        # Make sure the font size varies a bit (+-20%)
        my $font_delta = int( rand int($self->{font_size}*0.2) )+1;
        my $font_size = $self->{font_size} + ( (qw/+ -/)[int(rand 2)] . $font_delta );

        $image->align_string(
            font    => $font,
            text    => $code_chars[$i],
            x       => $pos_x,
            y       => 10,
            valign  => 'top',
            size    => $font_size,
            color   => $color,
            aa      => 1
        ) or croak "Error inserting string: $!";
        
        $pos_x += $self->{font_size} + int(rand (int ($self->{font_size}/2)))+1;
    }
}

1;

__END__

=head1 NAME

Image::VisualConfirmation - Add anti-spam visual confirmation/challenge
to your web forms

=head1 SYNOPSIS

    use Image::VisualConfirmation;
    
    my $vc = Image::VisualConfirmation->new();
    
    print $vc->image_code;
    my $image_data = $vc->image_data(type => 'png');

=head1 DESCRIPTION

This module aims at making the creation of visual confirmation (also
known as visual challenge) images simple. For those who doen't know
about these, they are the funky images from which you have to copy the
text when submitting a form. Their function is to avoid robots spamming
web forms, and they work quite good even though spammers' OCR software
is becoming increasingly good.

This module is mainly for use in a web application context, in
conjuction with such modules as L<CGI::Session> or with a web framework
such as L<Catalyst>.

When creating the random string, this module excludes the letters/digits
which might be confused with each other, so that the user has a greater
chance to not get angered with the challenge: C<0>, upper and lower-case
C<o>; lower-case C<l> and C<1>; C<j>.

=head1 METHODS

=head2 new

Arguments: \%options

Return Value: $vc (new Image::VisualConfirmation object)

This method initializes a new object. 

    # This should work everywhere
    my $vc = Image::VisualConfirmation->new();

    # Font selection on Win32
    my $vc = Image::VisualConfirmation->new({
        font_file   => './bodoni.pbf',
        font_size   => 30,
    });
    
    # Font selection on all other systems (should work on Win32 as well)
    my $vc = Image::VisualConfirmation->new({
        font_face   => 'Times New Roman',
        font_size   => 30,
    });

All parameters are optional:

C<font_face>: under Win32, this is the standard method to specify
the font to use to render the text. You can specify the font with
or without attributes, i.e. C<Times New Roman> or C<Arial Bold>. If
this parameter is not passed, it defaults to C<Arial> on Win32 and
is completely ignored on other systems.

C<font_file>: the path to the font to use to render the text. By
default it uses a Bitstream Vera font bundled with this module, unless
you are on Win32 where your system C<Arial> font will be used.
Several font formats are accepted, depending on your platform:
see L<Imager::Font> documentation. The bundled Vera font is in
C</your/perllib/path/Image/VisualConfirmation/Vera.ttf> or some
similar location, and you should have plenty of fonts to choose from
in C</usr/share/fonts>.

C<font_size>: the size of the characters, it defaults to C<20>.

C<bgcolor>: the background color of the image to be created.

C<code_length>: the length, in chars, of the visual code to generate at
random; default is C<6>.

C<width> and C<height>: if these 2 are provided, the image will be
createt of that size (but rotation might then change it a bit);
otherwise, the size will be calculated dinamically depending on
C<code_length> and C<font_size>.

=head2 create_new_image

Arguments: \%options

Generates a new code and new image for the given object. Parameters are
the same as C<new>.

=head2 code

Returns: string

Returns the code which has been generated, in string format. This is
needed for comparison with the user-entered one.

=head2 image

Returns: L<Imager> object

Returns an L<Imager> object with the created image. This allows you to
get all the image properties, save it, ... It also allows to perform
further obfuscation on the image, if needed.

=head2 image_data

Arguments: \%options

Returns: raw image data

This method returns the raw data of the image in a variable, which can
be used for direct output, i.e.:

    my $image_data = $vc->image_data;
    
    print $q->header(
        -type   => 'image/png',
    );

    print $image_data;

There's an optional parameter, C<type>, which allows you to specify the
format of the data you get. All formats supported by L<Imager> are
valid:  C<png> (the default if you don't pass the parameter), C<jpeg>,
C<gif>, C<tiff>, C<bmp>, C<tga>. Beware that C<gif> support is broken
on some platforms (including mine): don't use it. L<Imager> also
supports C<raw> format, but it has mandatory arguments: since argument
forwarding is not (yet) implemented for this method, it's not supported.
If you need to pass arguments to Imager, please use the C<image> method
and then work directly on the Imager object.

=head1 TODO

- Allow user to provide a code generated by himself, or a callback to
a function which generates it.

- Improve the visual challenge by adding image deformations and random
backgroup colors.

- Improve the synopsis with a L<CGI::Session> and a L<Catalyst> example.

- Improve error handling with bad parameters.

- Add more tests.

- Implement argument forwarding to L<Imager> object for C<image_data>.

=head1 BUGS

- Well, it's version 0.01, you know... ;-)

=head1 SEE ALSO

L<Imager>

=head1 AUTHOR

Michele Beltrame, C<mb@italpro.net>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

The Bitstream Vera font bundled with this distribution is copyrighted
by Bitstream ( http://www.bitstream.com ) and distributed under its
license terms.

=cut
