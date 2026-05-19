{
  inputs,
  self,
  ...
}: {
  flake.overlays.default = import "${self}/overlays" {flake = {inherit inputs self;};};
}
