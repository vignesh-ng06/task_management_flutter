import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../data/dashboard_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DashboardRepository _repo;

  HomeBloc(this._repo) : super(const HomeState()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onLoad);
  }

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    try {
      final data = await _repo.getDashboard();
      emit(state.copyWith(status: HomeStatus.loaded, data: data));
    } on ApiException catch (e) {
      emit(state.copyWith(status: HomeStatus.error, error: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: HomeStatus.error,
        error: 'Failed to load dashboard',
      ));
    }
  }
}