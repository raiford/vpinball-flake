default:
  just --list

update:
  just update-vpinfe
  nix flake update vpinball

update-vpinfe:
  ./scripts/update_vpinfe.sh

update-commit commit:
  nix flake update vpinball --override-input vpinball github:/vpinball/vpinball/{{commit}}

build:
  nix build --show-trace .
