class twemproxy::install (
  $version        = '0.4.0',
  $cflags_opts    = '-ggdb3 -O0',
  $debug_mode     = false,
  $debug_opts     = 'full'
){

  include stdlib
  include twemproxy::params
  include twemproxy::package
  include twemproxy::autoconf

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  $prefix = $twemproxy::params::default_prefix

  validate_string($version)
  validate_string($cflags_opts)
  validate_bool($debug_mode)
  validate_string($debug_opts)

  $resource = "twemproxy-${version}"

  # installs /usr/sbin/nutcracker
  # this must match the service templates
  if $debug_mode {
    $cfgcmd = "CFLAGS=\"${cflags_opts}\" ./configure --prefix=/usr --enable-debug=${debug_opts}"
  } else {
    $cfgcmd = "CFLAGS=\"${cflags_opts}\" ./configure --prefix=/usr"
  }

  file { "${prefix}/src":
    ensure  => 'directory'
  } ->
  file { "${prefix}/src/${resource}.tar.gz":
    ensure => 'file',
    source => "puppet:///modules/twemproxy/${resource}.tar.gz"
  } ->
  exec { "tar-xvfz-${resource}":
    command => "tar xvzf ${resource}.tar.gz",
    cwd     => "${prefix}/src",
    creates => "${prefix}/src/${resource}"
  } ->
  exec { "autoconf-${resource}":
    command   => 'autoreconf -fvi',
    provider  => shell,
    logoutput => false,
    cwd       => "${prefix}/src/${resource}",
    creates   => "${prefix}/src/${resource}/configure",
    require   => Anchor['twemproxy::autoconf::end']
  } ->
  exec { "configure-${resource}":
    command   => $cfgcmd,
    provider  => shell,
    logoutput => false,
    cwd       => "${prefix}/src/${resource}",
    creates   => "${prefix}/src/${resource}/config.status"
  } ->
  exec { "make-${resource}":
    command   => 'make && make install',
    provider  => shell,
    logoutput => false,
    cwd       => "${prefix}/src/${resource}",
    creates   => "${prefix}/src/${resource}/src/nutcracker"
  }
}