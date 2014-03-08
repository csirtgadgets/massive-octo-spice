$PERL_VERSION = 5.18.2

class perlbrew::install {
    exec { 'install perlbrew':
        require => Package['curl'],
        environment => 'PERLBREW_ROOT=/home/vagrant/perl5/perlbrew',
        command => '/usr/bin/sudo /usr/bin/curl -kL http://install.perlbrew.pl | /bin/bash',
        user => 'vagrant',
        cwd => '/home/vagrant',
        timeout => 100,
        before => Exec['add perlbrew to $PATH'],
        #logoutput => true,
    }

    # FIXME this at least, should only happen once
    exec { 'add perlbrew to $PATH':
        path => '/bin/',
		unless => 'grep -c "/home/vagrant/perl5/perlbrew/etc/bashrc" /home/vagrant/.bashrc',
        command => 'echo "source ~/perl5/perlbrew/etc/bashrc" >> /home/vagrant/.bashrc',
        user => 'vagrant',
        cwd => '/home/vagrant',
        logoutput => on_failure,
        before => Exec['perlbrew init'],
    }

    exec { 'perlbrew init':
        #path => '/home/vagrant/perl5/perlbrew/bin',
        environment => 'PERLBREW_ROOT=/home/vagrant/perl5/perlbrew',
        command => '/home/vagrant/perl5/perlbrew/bin/perlbrew init',
        user => 'vagrant',
        #logoutput => 'true',
        before => Exec["install perl ${PERL_VERSION}"],
    }

    exec { "install perl ${PERL_VERSION}":
        #path => '/home/vagrant/perl5/perlbrew/bin',
        environment => 'PERLBREW_ROOT=/home/vagrant/perl5/perlbrew',
        command => "/home/vagrant/perl5/perlbrew/bin/perlbrew install perl-${PERL_VERSION}",
        timeout => 2400,
        user => 'vagrant',
        cwd => '/home/vagrant',
        logoutput => true,
        before => Exec['set default perl'],
    }

    exec { 'set default perl':
        environment => 'PERLBREW_ROOT=/home/vagrant/perl5/perlbrew',
        #path => '/home/vagrant/perl5/perlbrew/bin',
        command => "/home/vagrant/perl5/perlbrew/bin/perlbrew switch perl-${PERL_VERSION}",
        user => 'vagrant',
        cwd => '/home/vagrant',
        before => Exec['install cpanm'],
    }

    exec { 'install cpanm':
        environment => 'PERLBREW_ROOT=/home/vagrant/perl5/perlbrew',
        #path => '/home/vagrant/perl5/perlbrew/bin',
        command => '/home/vagrant/perl5/perlbrew/bin/perlbrew install-cpanm',
        user => 'vagrant',
        cwd => '/home/vagrant',
    }
}
