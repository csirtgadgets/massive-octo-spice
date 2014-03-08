# Everybody needs these...
class build-essential {
    package { build-essential: ensure => latest }
}
class vim {
    package { vim: ensure => latest }
}
class git {
    package { git-core: ensure => latest }
}
class curl {
    package { curl: ensure => latest }
}
class htop {
    package { htop: ensure => latest }
}

class core {
    include build-essential
    include vim
    include htop
    include git
    include curl
}
