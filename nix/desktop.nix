{ config, lib, pkgs, ... }:

let
  user = "@USER@";

  flakeInputs = config._module.args.inputs or null;

  matugenFromFlake = flakeInputs != null && flakeInputs ? matugen;

  matugenPkg =
    if matugenFromFlake
    then flakeInputs.matugen.packages.${pkgs.stdenv.hostPlatform.system}.default
    else pkgs.matugen;

  shellPackages = with pkgs; [
    quickshell
    matugenPkg
    swaybg
    wl-clipboard
    brightnessctl
    jq
    inotify-tools
    killall
    glib
  ];

  configPackages = with pkgs; [
    kitty
    thunar
    hyprshot
    grim
    slurp
    swappy
    wf-recorder
    hypridle
    hyprlock
    fastfetch
  ];

in
{

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  programs.hyprlock.enable = true;
  programs.dconf.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.homeBinInPath = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  networking.networkmanager.enable = lib.mkDefault true;

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  services.udev.packages = [ pkgs.brightnessctl ];

  services.xserver.xkb = {
    layout = lib.mkDefault "us,ru";
    options = lib.mkDefault "grp:win_space_toggle";
  };

  time.timeZone = lib.mkDefault "Asia/Yekaterinburg";
  i18n.defaultLocale = lib.mkDefault "ru_RU.UTF-8";

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      dejavu_fonts
      liberation_ttf
      font-awesome
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Noto Sans" "DejaVu Sans" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  users.users.${user} = {
    isNormalUser = lib.mkDefault true;
    extraGroups = [ "video" "input" "networkmanager" ];
  };

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  environment.systemPackages = shellPackages ++ configPackages;

  warnings = lib.optional (!matugenFromFlake) ''
    matugen comes from nixpkgs (4.0) instead of the flake. The bar copes with
    that: it checks the version and skips --prefer when the option is absent.
    Automatic wallpaper colors will not work on images with several candidate
    colors, because matugen 4.0 wants a human to pick one in a terminal. Fix
    it with a flake input: inputs.matugen.url = "github:InioX/matugen" plus
    specialArgs = { inherit inputs; }.
  ''
}
