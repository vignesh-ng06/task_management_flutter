import '../../../core/api/api_client.dart';
import 'models/dashboard_data.dart';

class DashboardRepository {
  final ApiClient _api;
  DashboardRepository(this._api);

  Future<DashboardData> getDashboard() async {
    final data = await _api.get('/dashboard');
    return DashboardData.fromJson(data);
  }
}