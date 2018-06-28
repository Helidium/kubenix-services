{ pkgs
, lib
, dockerTools
, overrides ? (self: super: {})
}:

with lib;

let
  images = (self:
let
  buildImageForPackage = {
    package,
    ...
  }@args:  let
    img = dockerTools.buildImage ({
      tag = "${getVersion package}-${substring 0 8 (baseNameOf (builtins.unsafeDiscardStringContext img.layer))}";
      fromImage = args.fromImage or self.base;
      contents = [package] ++ args.contents or [];
    } // (filterAttrs (n: _: n != "package") args));
  in img;

  pushImages = images: pkgs.writeScript "push-docker-images" ''
    #!/bin/sh

    ${concatStrings (mapAttrsToList (name: image: ''
    ${pkgs.skopeo}/bin/skopeo copy docker-archive:${image} $1/${image.imageName}:${image.imageTag}
    '') images)}
  '';

  callPackage = pkgs.newScope (pkgs // {
    images = self;
  });
in {
  inherit buildImageForPackage pushImages;

  base = dockerTools.buildImage {
    name = "base";
    contents = [pkgs.bashInteractive pkgs.coreutils];
  };

  zookeeper = callPackage ./zookeeper.nix { };
});

in fix' (extends overrides images)