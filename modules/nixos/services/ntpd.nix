{...}: {
  config = {
    time = {
      timeZone = "America/Sao_Paulo";
      hardwareClockInLocalTime = false;
    };

    networking.timeServers = [
      "a.st1.ntp.br"
      "b.st1.ntp.br"
      "c.st1.ntp.br"
      "d.st1.ntp.br"
    ];

    services.chrony = {
      enable = true;
      enableNTS = true;
    };
  };
}
