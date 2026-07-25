class AppLogger {
  static final List<String> _logs = [];
  static const int maxLogs = 200;

  static void debug(String msg) => _log('DEBUG', msg);
  static void info(String msg) => _log('INFO', msg);
  static void warning(String msg) => _log('WARN', msg);
  // Alias for warning() — used in some callers
  static void warn(String msg) => warning(msg);
  static void error(String msg, [dynamic e]) {
    _log('ERROR', msg);
    if (e != null) _log('ERROR', '  → $e');
  }

  static void _log(String level, String msg) {
    final t = DateTime.now();
    final ts = '${t.hour}:${t.minute}:${t.second}.${t.millisecond}';
    final line = '[$ts][$level] $msg';
    // ignore: avoid_print
    print(line);
    _logs.add(line);
    if (_logs.length > maxLogs) _logs.removeAt(0);
  }

  static List<String> getAll() => List.from(_logs);
}
