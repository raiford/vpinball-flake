default:
  just --list

update:
  nix flake update vpinball

update-commit commit:
  nix flake update vpinball --override-input vpinball github:/vpinball/vpinball/{{commit}}

build:
  nix build --show-trace .
