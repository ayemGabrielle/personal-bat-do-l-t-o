import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  Future<bool> isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print("🚫 No network connection.");
      return false;
    }

    // 🔹 Use a different CORS-friendly API
    try {
      final response = await http.get(Uri.parse('https://api64.ipify.org?format=json'))
          .timeout(const Duration(seconds: 3)); // Timeout for fast failure

      if (response.statusCode == 200) {
        print("✅ Internet is accessible.");
        return true;
      }
    } catch (e) {
      print("❌ Connected but no internet access: $e");
    }

    print("🚫 Network detected, but no internet access.");
    return false;
  }
}
