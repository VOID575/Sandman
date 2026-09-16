class Validators {
  static final RegExp _ipRegex = RegExp(
    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );

  static final RegExp _macRegex = RegExp(
    r'^([0-9A-Fa-f]{2}[:.-]){5}([0-9A-Fa-f]{2})$',
  );

  static final RegExp _portRegex = RegExp(r'^\d+$');

  static String? validateIp(String? value) {
    if (value == null || value.isEmpty) {
      return 'IP address is required';
    }
    if (value.contains(' ')) {
      return 'No spaces allowed';
    }
    if (!_ipRegex.hasMatch(value)) {
      return 'Invalid IP format (e.g., 192.168.1.1)';
    }
    return null;
  }

  static String? validateMac(String? value) {
    if (value == null || value.isEmpty) {
      return 'MAC address is required';
    }
    if (value.contains(' ')) {
      return 'No spaces allowed';
    }
    if (!_macRegex.hasMatch(value)) {
      return 'Invalid MAC format (e.g., AA:BB:CC:DD:EE:01)';
    }
    return null;
  }

  static String? validatePort(String? value) {
    if (value == null || value.isEmpty) {
      return 'Port is required';
    }
    if (value.contains(' ')) {
      return 'No spaces allowed';
    }
    if (!_portRegex.hasMatch(value)) {
      return 'Only digits are allowed';
    }
    final port = int.tryParse(value);
    if (port == null || port <= 0 || port > 65535) {
      return 'Port must be between 1 and 65535';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a $fieldName';
    }
    return null;
  }
}
