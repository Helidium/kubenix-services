{ config, k8s, ... }:

{
  require = import ../services/module-list.nix;

  kubernetes.modules.mongo = {
    module = "mongo";
    configuration = {
      auth = {
        key.name = "mongo-creds";
      };
    };
  };

  kubernetes.resources.secrets.mongo-creds.data = {
    username = k8s.toBase64 "root";
    password = k8s.toBase64 "root";
    key = k8s.toBase64 "someveryrandomkey";
  };
}
