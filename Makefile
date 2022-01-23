include env
export


.PHONY: test postgres test-setup

test-setup:
	nix develop --command mix ecto.reset

test:
ifdef IN_NIX_SHELL
	mix test
else
	nix develop --command mix test
endif

postgres:
ifdef IN_NIX_SHELL
	postgres
else
	nix develop --command postgres
endif
