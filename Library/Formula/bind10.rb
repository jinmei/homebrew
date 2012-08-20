require 'formula'

class Bind10 < Formula
  homepage 'http://www.isc.org/software/bind10/'
  url 'ftp://ftp.isc.org/isc/bind10/devel-20120816/bind10-devel-20120816.tar.gz'
  version 'devel-20120816'
  sha1 'f10c80f590d0e462a20f8fa13964463b34b69f51'

  depends_on "boost"
  depends_on "botan"
  depends_on "log4cplus"
  depends_on "sqlite"
  depends_on "python3"

  # this directory will be initially empty but will be searched for
  # configuration on startup
  skip_clean 'var/bind10-devel'

  def install
      system "./configure", "--prefix=#{prefix}"
      system "make"
      ENV.j1 # make install breaks with -j option
      system "make install"
  end
end
