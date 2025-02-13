{
  description = "A flake for beholder on Binance";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    beholder = {
      url = "github:siegfried/beholder";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      beholder,
      ...
    }:
    {
      nixosModules.default =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          options.services.beholder = {
            enable = lib.mkEnableOption "Enable the take-profit-1d service";
            databaseURL = lib.mkOption {
              type = lib.types.str;
              description = "Database URL for beholder.";
            };
            startAt = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Start time for the service in systemd's `startAt` format. If null, the service will start during system boot (or when systemd deems appropriate for a oneshot service).";
            };
          };

          config = lib.mkIf config.services.beholder.enable (
            let
              serviceConfig = config.services.beholder;
              startAt = lib.mkIf (serviceConfig != null) serviceConfig.startAt;
              beholderPkg = beholder.packages.${pkgs.system}.default;
              beholderScripts = pkgs.callPackage ./default.nix {
                beholder = beholderPkg;
                beholderDatabase = serviceConfig.databaseURL;
              };
              user = "beholder";
              group = "beholder";
            in
            {
              users.users.${user} = {
                inherit group;
                packages = [
                  beholderPkg
                  beholderScripts.beholder-all-script
                  beholderScripts.beholder-daily-1d-script
                  beholderScripts.beholder-daily-1h-script
                  beholderScripts.beholder-daily-15m-script
                ];
              };

              users.groups.${group} = { };

              systemd = {
                services.beholder-daily-1d = {
                  description = "Beholder Daily Data Import 1d";
                  script = lib.getExe beholderScripts.beholder-daily-1d-script;
                  after = [ "network.target" ];
                  serviceConfig = {
                    Type = "oneshot";
                    User = user;
                    Group = group;
                  };
                  inherit startAt;
                };
                services.beholder-daily-1h = {
                  description = "Beholder Daily Data Import 1h";
                  script = lib.getExe beholderScripts.beholder-daily-1h-script;
                  after = [ "network.target" ];
                  serviceConfig = {
                    Type = "oneshot";
                    User = user;
                    Group = group;
                  };
                  inherit startAt;
                };
                services.beholder-daily-15m = {
                  description = "Beholder Daily Data Import 15m";
                  script = lib.getExe beholderScripts.beholder-daily-15m-script;
                  after = [ "network.target" ];
                  serviceConfig = {
                    Type = "oneshot";
                    User = user;
                    Group = group;
                  };
                  inherit startAt;
                };
              };
            }
          );
        };
    };
}
