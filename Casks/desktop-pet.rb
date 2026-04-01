cask "desktop-pet" do
  version "1.1.1"
  sha256 "60c0bfa3217fcf65307693bf11678dabcc48a43b7edbe04bae1fb389a5bafa28"

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
