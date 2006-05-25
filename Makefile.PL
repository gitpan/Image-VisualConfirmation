use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::VisualConfirmation',
    VERSION_FROM      => 'lib/Image/VisualConfirmation.pm', # finds $VERSION
    PREREQ_PM         => {
    	Imager	=> 0.48
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Image/VisualConfirmation.pm', # retrieve abstract from module
       AUTHOR         => 'Michele Beltrame <mb@italpro.net>') : ()),
);
