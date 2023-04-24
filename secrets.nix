{
  wirelessNetworks = {
    "homenetwork" = {
      psk = "password123";
    };
  };
  users = {
    nixos = {
      # password = nixos
      initialHashedPassword = "$y$j9T$cIgK4AbDSq7Z/1ltwoRoV0$TyFEtuK8mn3YPNJQUYNvuQPcNesLbLv./87TP6F7AzB";
      opensshKeys = [
        # enter your key here
      ];
    };
    root = {
      # password = nixos
      initialHashedPassword = "$y$j9T$cIgK4AbDSq7Z/1ltwoRoV0$TyFEtuK8mn3YPNJQUYNvuQPcNesLbLv./87TP6F7AzB";
    };
  };
}
