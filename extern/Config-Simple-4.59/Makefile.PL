use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Config::Simple',
    'VERSION_FROM'	=> 'Simple.pm', 
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?    (ABSTRACT_FROM => 'Simple.pm', AUTHOR => 'Sherzod B. Ruzmetov <sherzodr@cpan.org>') : ()),
);
