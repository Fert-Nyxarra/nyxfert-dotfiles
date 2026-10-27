# ~/.config/nixos-setup/desktop.nix
# Среда рабочего стола целиком: Hyprland, панель quickshell и всё, без чего
# они не работают. Подключается из configuration.nix:
#
#   imports = [ ./hardware-configuration.nix ./desktop.nix ];
#
# Файл ставит install.sh из того же набора; он же подставляет имя пользователя
# вместо @USER@ и правит imports.
{ config, lib, pkgs, ... }:

let
  user = "@USER@";

  # Входы флейка, если система вообще на флейке. Брать их аргументом модуля
  # (`{ inputs ? null, ... }`) нельзя: на системе без флейка модульная система
  # всё равно лезет за ними в _module.args и падает с «attribute 'inputs'
  # missing» — значение по умолчанию до неё не доходит.
  flakeInputs = config._module.args.inputs or null;

  # matugen 4.2+ обязателен: в 4.0 из nixpkgs нет --prefer, а без него режим
  # «авто» в селекторе обоев падает на картинках с несколькими цветами —
  # matugen хочет, чтобы выбор сделал человек в терминале.
  matugenFromFlake = flakeInputs != null && flakeInputs ? matugen;

  matugenPkg =
    if matugenFromFlake
    then flakeInputs.matugen.packages.${pkgs.stdenv.hostPlatform.system}.default
    else pkgs.matugen;

  # Только то, без чего не работает САМА оболочка и то, на что ссылаются
  # конфиги. Прикладного софта тут нет намеренно: браузер, мессенджеры и
  # плеер у каждой машины свои, а их список в модуле переноса превращается в
  # чужой вкус, навязанный новой системе.
  shellPackages = with pkgs; [
    quickshell          # сама панель
    matugenPkg          # палитра по обоям
    swaybg              # обои
    wl-clipboard        # буфер обмена: wl-paste --watch и wl-copy
    brightnessctl       # яркость без root
    jq                  # разбор вывода hyprctl в скриптах
    inotify-tools       # слежение за файлами в ~/bin
    killall
    glib                # gdbus — им шлются уведомления без notify-send
  ];

  # На это ссылается hyprland.lua и скрипты из ~/bin
  configPackages = with pkgs; [
    kitty               # терминал из биндов
    thunar              # файловый менеджер из биндов
    hyprshot            # скриншоты, SUPER + Print и соседи
    grim                # нужен hyprshot и ~/bin/screenrec
    slurp               # выбор области
    swappy              # разметка скриншота
    wf-recorder         # запись экрана, ~/bin/screenrec
    hypridle
    hyprlock            # SUPER + L
    fastfetch           # конфиг едет вместе с остальными
  ];

in
{
  #### Hyprland и сессия ######################################################

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

  # Электрон под Wayland, иначе окна размыты на дробном масштабе
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ~/bin в PATH: там лежат screenrec, keycheck и export-setup, и без этого
  # они зовутся только по полному пути.
  environment.homeBinInPath = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  #### Звук ###################################################################

  # Панель читает громкость и устройства через PipeWire; без wireplumber
  # список устройств будет пустым.
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  #### Сеть, батарея, яркость #################################################

  networking.networkmanager.enable = lib.mkDefault true;

  # Батарея в панели берётся из UPower, профили потребления — из
  # power-profiles-daemon. Без них модуль батареи просто не появится.
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Правила udev из brightnessctl: без них яркость меняется только от root.
  services.udev.packages = [ pkgs.brightnessctl ];

  #### Раскладка, локаль ######################################################

  services.xserver.xkb = {
    layout = lib.mkDefault "us,ru";
    options = lib.mkDefault "grp:win_space_toggle";
  };

  time.timeZone = lib.mkDefault "Asia/Yekaterinburg";
  i18n.defaultLocale = lib.mkDefault "ru_RU.UTF-8";

  #### Шрифты #################################################################

  # JetBrainsMono Nerd Font обязателен: из него все значки панели. Без него
  # вместо иконок будут пустые прямоугольники.
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

  #### Пользователь ###########################################################

  # video — яркость, input — клавиатура и мышь для Hyprland.
  #
  # isNormalUser через mkDefault: если пользователь уже объявлен в
  # configuration.nix, выиграет его объявление, а если нет — модуль не
  # развалится на «ровно одно из isSystemUser/isNormalUser должно быть
  # задано».
  users.users.${user} = {
    isNormalUser = lib.mkDefault true;
    extraGroups = [ "video" "input" "networkmanager" ];
  };

  #### Пакеты #################################################################

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  # Прикладной софт ставится отдельно и сюда не попадает — см. комментарий
  # у shellPackages.
  environment.systemPackages = shellPackages ++ configPackages;

  # Предупреждение видно при каждой сборке, пока matugen берётся из nixpkgs.
  warnings = lib.optional (!matugenFromFlake) ''
    matugen взят из nixpkgs (4.0), а не из флейка. Панель это переживёт:
    она сама спрашивает версию и не передаёт --prefer, если его нет. Но
    режим «авто» в селекторе обоев на картинках с несколькими кандидатами
    цвета работать не будет — matugen в 4.0 хочет, чтобы выбор сделал
    человек в терминале. Лечится входом флейка:
    inputs.matugen.url = "github:InioX/matugen" плюс specialArgs = { inherit inputs; }.
  '';
}
