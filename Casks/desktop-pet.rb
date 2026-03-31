cask "desktop-pet" do
  version "1.0.1"
  sha256 "354bad144b7affbc4f9899017f874bec3a5506744407d8137b89619feffecd08"

  url "https://github.com/bssm-oss/desktop-pet/releases/download/v#{version}/DesktopPet.dmg"
  name "Desktop Pet"
  desc "Transparent animated overlay for your macOS desktop"
  homepage "https://github.com/bssm-oss/desktop-pet"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma" # macOS 14.0+

  app "DesktopPet.app"

  zap trash: [
    "~/Library/Preferences/com.bssm-oss.desktop-pet.plist",
    "~/Library/Application Support/desktop-pet",
  ]
end
