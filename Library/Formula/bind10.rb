require 'formula'

class Bind10 < Formula
  homepage 'http://www.isc.org/software/bind10/'
  url 'ftp://ftp.isc.org/isc/bind10/1.0.0-beta/bind10-1.0.0-beta.tar.gz'
  version '1.0.0-beta'
  sha1 '79f4de4712bceac615eb24c70d4ad10bf485f346'

  depends_on "python3"
  depends_on "boost"
  depends_on "botan"
  depends_on "log4cplus"
  depends_on "sqlite"

  # this directory will be initially empty but will be searched for
  # configuration on startup
  skip_clean 'var/bind10'

  def patches
    { :p0 => DATA }
  end

  def install
      system "./configure", "--prefix=#{prefix}"
      system "make"
      ENV.j1 # make install breaks with -j option
      system "make install"
  end
end

__END__
--- configure.orig	2013-01-21 16:47:06.000000000 -0800
+++ configure	2013-01-21 16:47:18.000000000 -0800
@@ -15014,7 +15014,7 @@
   $as_echo_n "(cached) " >&6
 else
 
-	for am_cv_pathless_PYTHON in python python3.2 python3.1 python3 none; do
+	for am_cv_pathless_PYTHON in python python3.3 python3.2 python3.1 python3 none; do
 	  test "$am_cv_pathless_PYTHON" = none && break
 	  prog="import sys
 # split strings by '.' and convert to numeric.  Append some zeros
