{
	description = "Yemma";

	# go here for using all system
	# https://serokell.io/blog/practical-nix-flakes

	outputs = { self, nixpkgs }:
		let pkgs = nixpkgs.legacyPackages.x86_64-darwin;
	in {

		# nix develop
		devShell.x86_64-darwin = pkgs.mkShell {
			buildInputs = with pkgs.darwin.apple_sdk.frameworks; [
				pkgs.postgresql
				pkgs.elixir
				CoreFoundation
				CoreServices
			];
			shellHook = ''
				mkdir -p .nix/mix
				mkdir -p .nix/hex

				unset MIX_ARCHIVES
				export MIX_HOME=$PWD/.nix/mix
				export HEX_HOME=$PWD/.nix/hex
				export PATH=$MIX_HOME/bin:$PATH
				export PATH=$HEX_HOME/bin:$PATH
				export LANG=en_US.UTF-8

				[ ! -f $MIX_HOME/rebar ] && mix local.rebar --force
				[ ! -d $MIX_HOME/archives ] && mix local.hex --force

				mkdir -p .nix/db
				export PGDATA=$PWD/.nix/db
				if [ ! -f $PGDATA/postgresql.conf ]; then
					initdb --auth=trust
					pg_ctl start
					createuser postgres --createdb -h localhost
					pg_ctl stop
				fi

				if [ -f ./env ]; then
				    set -a; source ./env; set +a
				fi
			'';

		};

		apps.x86_64-darwin.postgres = {
			type = "app";
			program = "${pkgs.postgresql}/bin/postgres";
		};
	};
}
