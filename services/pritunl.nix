{ config, lib, k8s, ... }:

with lib;

{
  config.kubernetes.moduleDefinitions.pritunl.module = {module, config, ...}: {
    options = {
      image = mkOption {
        description = "Docker image to use";
        type = types.str;
        default = "jippi/pritunl";
      };

      replicas = mkOption {
        description = "Number of pritunl replicas to run";
        type = types.int;
        default = 1;
      };

      mongodbUri = mkOption {
        description = "URI for mongodb database";
        type = types.str;
        default = "mongodb://mongo/pritunl";
      };

      extraPorts = mkOption {
        description = "Extra ports to expose";
        type = types.listOf types.int;
        default = [];
      };
    };

    config = {
      kubernetes.resources.deployments.pritunl = {
        metadata = {
          name = module.name;
          labels.app = module.name;
        };
        spec = {
          replicas = config.replicas;
          selector.matchLabels.app = module.name;
          template = {
            metadata.labels.app = module.name;
            spec = {
              containers.pritunl = {
                image = config.image;
                env.PRITUNL_MONGODB_URI.value = config.mongodbUri;

                securityContext.capabilities.add = ["NET_ADMIN"];

                ports = [{
                  containerPort = 80;
                } {
                  containerPort = 443;
                } {
                  containerPort = 1194;
                }] ++ map (port: {containerPort = port;}) config.extraPorts;
              };
            };
          };
        };
      };

      kubernetes.resources.services.pritunl = {
        metadata.name = module.name;
        metadata.labels.app = module.name;

        spec.selector.app = module.name;

        spec.ports = [{
          name = "http";
          port = 80;
          targetPort = 80;
        } {
          name = "https";
          port = 443;
          targetPort = 443;
        } {
          name = "vpn";
          port = 1194;
          targetPort = 1194;
        }] ++ map (port: {
          name = "${toString port}";
          port = port;
          targetPort = port;
        }) config.extraPorts;
      };
    };
  };
}
