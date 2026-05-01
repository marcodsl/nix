{
  config,
  lib,
  ...
}: {
  security.polkit = {
    enable = lib.mkDefault true;
    debug = lib.mkDefault false;

    extraConfig = lib.mkIf config.security.polkit.debug ''
      /* Log authorization checks. */
      polkit.addRule(function(action, subject) {
        polkit.log("user " +  subject.user + " is attempting action " + action.id + " from PID " + subject.pid);
      });
    '';
  };
}
