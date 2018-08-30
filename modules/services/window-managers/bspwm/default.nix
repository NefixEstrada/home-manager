{ config, lib, pkgs, ... }:

with lib;

let

	cfg = config.xsession.windowManager.bspwm;
	bspwm = cfg.package;

	monitor = types.submodule {
		options = {
			name = mkOption {
				type = types.nullOr types.string;
				default = null;
				description = "The name or id of the monitor (MONITOR_SEL).";
				example = "HDMI-0";
			};

			desktops = mkOption {
				type = types.listOf types.string;
				default = [];
				description = "The desktops that the monitor is going to hold";
				example = [ "web" "terminal" "III" "IV" ];
			};
		};
	};

	formatConfig = n: v:
    let
      formatList = x:
        if isList x
        then throw "can not convert 2-dimensional lists to bspwm format"
        else formatValue x;

      formatValue = v:
        if isBool v then (if v then "true" else "false")
        else if isList v then concatMapStringsSep ", " formatList v
        else toString v;
    in
      "bspc config ${n} ${formatValue v}";

	formatMonitors = n:
		map(s: 
			"bscp monitor " + (if (s.name != null) then (s.name + " ") else "") + "-d ${concatStringsSep " " s.desktops}" 
		) n;

	formatStartupPrograms = n:
		map(s: s + " &") n;

in

{
  options = import .options.nix { inherit pkgs; };

	config = mkIf cfg.enable (mkMerge [
		{
			home.packages = [ bspwm ];
			xsession.windowManager.command = "${cfg.package}/bin/bspwm";
		}

		(mkIf (cfg.config != null) {
			xdg.configFile."bspwm/bspwmrc" = {
				executable = true;
				text = "#!/bin/sh\n\n" + 
				concatStringsSep "\n" ([]
					++ (optionals (cfg.monitors != []) (formatMonitors cfg.monitors))
					++ [ "" ]
					++ (optionals (cfg.config != null) (mapAttrsToList formatConfig cfg.config))
					++ [ "" ]
					++ (optional (cfg.extraConfig != "") cfg.extraConfig)
					++ (optionals (cfg.startupPrograms != null) (formatStartupPrograms cfg.startupPrograms))
				) + "\n";
			};
		})
	]);
}
