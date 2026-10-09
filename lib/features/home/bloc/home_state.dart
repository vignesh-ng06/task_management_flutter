import 'package:equatable/equatable.dart';
import '../data/models/dashboard_data.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final DashboardData? data;
  final String? error;

  const HomeState({
    this.status = HomeStatus.initial,
    this.data,
    this.error,
  });

  HomeState copyWith({
    HomeStatus? status,
    DashboardData? data,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, data, error];
}