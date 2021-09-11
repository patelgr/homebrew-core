class Ortp < Formula
  desc "Real-time transport protocol (RTP, RFC3550) library"
  homepage "https://www.linphone.org/technical-corner/ortp"
  url "https://gitlab.linphone.org/BC/public/ortp/-/archive/5.0.22/ortp-5.0.22.tar.bz2"
  sha256 "103ce29e310fbb86d261acda9f6a505389247a82096c5666818f25ba3ad7079b"
  license "GPL-3.0-or-later"
  head "https://gitlab.linphone.org/BC/public/ortp.git", branch: "master"

  bottle do
    sha256 cellar: :any, arm64_big_sur: "b36b7bb24c4e641fc0dd87b21cbbb2a63d476e91fc797e7ee6ca2c579a3595f0"
    sha256 cellar: :any, big_sur:       "b09156988e2029491ee22113c2f393a794bc52e1948a049c4840aa8a443f7c36"
    sha256 cellar: :any, catalina:      "f06cf89eb0e56109d12deb012967267e22e97781153013ab2b34d814853b5f56"
    sha256 cellar: :any, mojave:        "48fffa9b46ee7eebf085e7ff91d63eb54b292a966c50180b573d0a9cd8a45afb"
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "mbedtls@2"

  # bctoolbox appears to follow ortp's version. This can be verified at the GitHub mirror:
  # https://github.com/BelledonneCommunications/bctoolbox
  resource "bctoolbox" do
    url "https://gitlab.linphone.org/BC/public/bctoolbox/-/archive/5.0.22/bctoolbox-5.0.22.tar.bz2"
    sha256 "a9fcc7d617d001a9b035ff0834b2346a4a05a2d52f5af141a716f035bb8d1ff8"
  end

  def install
    resource("bctoolbox").stage do
      args = std_cmake_args.reject { |s| s["CMAKE_INSTALL_PREFIX"] } + %W[
        -DCMAKE_INSTALL_PREFIX=#{libexec}
        -DENABLE_TESTS_COMPONENT=OFF
      ]
      system "cmake", ".", *args
      system "make", "install"
    end

    ENV.prepend_path "PKG_CONFIG_PATH", libexec/"lib/pkgconfig"

    args = std_cmake_args + %W[
      -DCMAKE_PREFIX_PATH=#{libexec}
      -DCMAKE_C_FLAGS=-I#{libexec}/include
      -DCMAKE_CXX_FLAGS=-I#{libexec}/include
      -DENABLE_DOC=NO
    ]
    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
    end
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include "ortp/logging.h"
      #include "ortp/rtpsession.h"
      #include "ortp/sessionset.h"
      int main()
      {
        ORTP_PUBLIC void ortp_init(void);
        return 0;
      }
    EOS
    system ENV.cc, "-I#{include}", "-I#{libexec}/include", "-L#{lib}", "-lortp",
           testpath/"test.c", "-o", "test"
    system "./test"
  end
end
