node default {
    # Useful...
    exec { 'apt-get update':
        command => '/usr/bin/apt-get update'
    }

    include core
    include perlbrew
}
