require 'formula'

class Bind10 < Formula
  homepage 'http://www.isc.org/software/bind10/'
  url 'ftp://ftp.isc.org/isc/bind10/1.0.0/bind10-1.0.0.tar.gz'
  version '1.0.0'
  sha1 '15b0000ea3c3ff7d26401ca204244869cc79b2f0'

  depends_on "python3"
  depends_on "boost"
  depends_on "botan"
  depends_on "log4cplus"
  depends_on "sqlite"
  depends_on "pkg-config" => :build

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
--- src/lib/util/encode/base_n.cc
+++ src/lib/util/encode/base_n.cc
@@ -119,6 +119,16 @@ public:
         }
         return (*this);
     }
+    EncodeNormalizer operator++(int) {
+        EncodeNormalizer copy = *this;
+        if (!in_pad_) {
+            ++base_;
+        }
+        if (base_ == base_end_) {
+            in_pad_ = true;
+        }
+        return (copy);
+    }
     const uint8_t& operator*() const {
         if (in_pad_) {
             return (BINARY_ZERO_CODE);
@@ -156,16 +166,20 @@ public:
     DecodeNormalizer(const char base_zero_code,
                      const string::const_iterator& base,
                      const string::const_iterator& base_beginpad,
-                     const string::const_iterator& base_end) :
+                     const string::const_iterator& base_end,
+                     size_t* char_count) :
         base_zero_code_(base_zero_code),
         base_(base), base_beginpad_(base_beginpad), base_end_(base_end),
-        in_pad_(false)
+        char_count_(char_count), in_pad_(false)
     {
         // Skip beginning spaces, if any.  We need do it here because
         // otherwise the first call to operator*() would be confused.
         skipSpaces();
     }
     DecodeNormalizer& operator++() {
+        if (base_ < base_end_) {
+            ++*char_count_;
+        }
         ++base_;
         skipSpaces();
         if (base_ == base_beginpad_) {
@@ -195,8 +209,12 @@ public:
             // we can catch and reject this type of invalid input.
             isc_throw(BadValue, "Unexpected end of input in BASE decoder");
         }
-        if (in_pad_) {
-            return (base_zero_code_);
+        if (*base_ == BASE_PADDING_CHAR) {
+            if (in_pad_) {
+                return (base_zero_code_);
+            } else {
+                isc_throw(BadValue, "Intermediate padding found");
+            }
         } else {
             return (*base_);
         }
@@ -209,6 +227,7 @@ private:
     string::const_iterator base_;
     const string::const_iterator base_beginpad_;
     const string::const_iterator base_end_;
+    size_t* char_count_;
     bool in_pad_;
 };
 
@@ -330,15 +349,22 @@ BaseNTransformer<BitsPerChunk, BaseZeroCode, Encoder, Decoder>::decode(
     // convert the number of bits in bytes for convenience.
     const size_t padbytes = padbits / 8;
 
+    size_t char_count = 0;
     try {
         result.assign(Decoder(DecodeNormalizer(BaseZeroCode, input.begin(),
-                                               srit.base(), input.end())),
+                                               srit.base(), input.end(),
+                                               &char_count)),
                       Decoder(DecodeNormalizer(BaseZeroCode, input.end(),
-                                               input.end(), input.end())));
+                                               input.end(), input.end(),
+                                               NULL)));
     } catch (const dataflow_exception& ex) {
         // convert any boost exceptions into our local one.
         isc_throw(BadValue, ex.what());
     }
+    if (((char_count * BitsPerChunk) & 7) != 0) {
+        isc_throw(BadValue, "Incomplete input for " << algorithm
+                  << ": " << input);
+    }
 
     // Confirm the original BaseX text is the canonical encoding of the
     // data, that is, that the first byte of padding is indeed 0.
