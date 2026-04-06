{pkgs, ...}: {
  config = {
    home.packages = let
      google-cloud-sdk = let
        sdk-components = with pkgs.google-cloud-sdk.components; [
          beta
          cloud-sql-proxy
          docker-credential-gcr
          gke-gcloud-auth-plugin
          gsutil
          pubsub-emulator
          terraform-tools
        ];
      in
        pkgs.google-cloud-sdk.withExtraComponents sdk-components;
    in [
      google-cloud-sdk
    ];
  };
}
