{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  BOARD_NAME = "NUCLEO-L476RG";
  ST_LINK_SN = "066EFF323054413043233210";
  # CHIP_NAME = "STM32WLE5JCIx";
  CHIP_NAME = "STM32WLE5JC";
  DEVICE_EUI = "";
  LORAWAN_REGION = "";
  APPLICATION_EUI = "";
  APPLICATION_KEY = "";
  STM = {
    PROGRAMMER_CLI_ARGS = {
      BAUD_RATE = "115200";
      PARITY_BIT = "EVEN";
      DATA_BITS = "8";
      STOP_BITS = "1";
      FREQUENCY = "4000";
    };
  };
in
{
  env = {
    GREET = "devenv";
    PROBE_RS_PROTOCOL = "swd";
    PROBE_RS_CHIP = "${CHIP_NAME}";
    PROBE_RS_ALLOW_ERASE_ALL = "true";
    PROBE_RS_CONNECT_UNDER_RESET = "true";
    PROBE_RS_SPEED = "${STM.PROGRAMMER_CLI_ARGS.FREQUENCY}";
    };

  packages = with pkgs; [
  ] ++ lib.optionals config.languages.c.enable [
    ninja
    ccache
    openocd
    binsider        # binary inspector TUI
    dfu-util
    probe-rs-tools  # rust-based replacement for stmcli, openocd, etc.
  ];

  languages = {
    c.enable = true;
    nix.enable = true;
    shell.enable = true;
  };

  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # services.postgres.enable = true;

  scripts = {
    list = {
      exec = ''
        probe-rs list
  '';
      };

    # build = {
    #  exec = ''
    #   "${config.git.root}/Projects/Applications/LoRaWAN/LoRaWAN_End_Node/STM32CubeIDE"
    #  '';
    # };

    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      stm-list = {
        exec = ''
          stmcli -l
        '';
      };

      stm-flash = {
        exec = ''
          stmcli -c port=SWD -w ./Debug/LoRaWAN_End_Node.elf 0x08000000 --verbosity 3
        '';
      };

      monitor = {
        exec = ''
          comchan -c ${config.git.root}/comchan.toml -l ${config.git.root}/serial.log
        '';
      };

      flash = {
        exec = ''
          probe-rs run ${config.git.root}/Projects/Applications/LoRaWAN/LoRaWAN_End_Node/STM32CubeIDE/Debug/LoRaWAN_End_Node.elf
          # probe-rs run ./Debug/LoRaWAN_End_Node.elf  --connect-under-reset
        '';
      };

  # openocd \
  # -f interface/stlink.cfg \
  # -f target/stm32wlx.cfg \
  # -c "adapter speed 4000" \
  # -c "reset_config srst_only connect_assert_srst" \
  # -c "program ./Debug/LoRaWAN_End_Node.elf verify reset exit"

    };

  enterShell = ''
    list
    # stmcli -l
  '';

  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';
}
