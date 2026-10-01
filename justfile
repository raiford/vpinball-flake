default:
  just --list

update:
  nix flake update vpinball
  nix develop '.#updateInputs'

update-commit commit:
  nix flake update vpinball --override-input vpinball github:/vpinball/vpinball/{{commit}}
  nix develop '.#updateInputs'

build:
  nix build --show-trace .
