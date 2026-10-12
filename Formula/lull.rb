class Lull < Formula
  desc "Stops the dev servers your coding agents forgot"
  homepage "https://github.com/rgrvlsk/lull"
  url "https://github.com/rgrvlsk/lull/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "dfc04c5bd43cf347dc09464d4e4d883194f2cd571189b705a4ec380479c7d8cf"
  license any_of: ["MIT", "Apache-2.0"]

  depends_on "rust" => :build
  depends_on :macos

  # The unpacked Chromium extension, built from extension/ at the same tag (ADR-0007).
  resource "chromium-extension" do
    url "https://github.com/rgrvlsk/lull/releases/download/v0.1.0/lull-extension-chromium-0.1.0.zip"
    sha256 "063c3111863a157189bfc6701d399e995902bcf0a6623905b4755dbdb77a8041"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/cli")
    # Native messaging forbids arguments in the manifest path (contract §3).
    bin.install_symlink "lull" => "lull-nm-host"
    (pkgshare/"extension/chromium").install resource("chromium-extension")
  end

  service do
    run [opt_bin/"lull", "daemon"]
    keep_alive true
    process_type :background
    log_path "#{Dir.home}/Library/Logs/lull/daemon.log"
    error_log_path "#{Dir.home}/Library/Logs/lull/daemon.log"
  end

  def caveats
    <<~EOS
      Start the daemon (it stops idle agent-started dev servers after 30 minutes):
        brew services start lull
      Then connect your Chromium browsers (Helium, Chrome, Brave, Edge, Vivaldi):
        lull browsers install
      After each `brew upgrade lull`, run `lull browsers install` again and restart
      the browser to load the new extension.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lull --version")
    assert_predicate bin/"lull-nm-host", :symlink?
  end
end
