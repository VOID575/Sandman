class DbConstants {
  static const String tableNetworks = 'networks';
  static const String tableMachines = 'machines';
  static const String databaseFileName = 'sandman_app.db';

  static const String createNetworksTable =
      '''
    CREATE TABLE $tableNetworks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      router_ip TEXT NOT NULL,
      api_key TEXT
    )
  ''';

  static const String createMachinesTable =
      '''
    CREATE TABLE $tableMachines (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      network_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      mac_address TEXT NOT NULL,
      FOREIGN KEY (network_id) REFERENCES $tableNetworks (id) ON DELETE CASCADE
    )
  ''';
}
