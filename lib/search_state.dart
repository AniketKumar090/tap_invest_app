part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchSuccess extends SearchState {
  final List<dynamic> bonds;
  
  const SearchSuccess(this.bonds);
  
  @override
  List<Object?> get props => [bonds];
}

class SearchFailure extends SearchState {
  final String error;
  
  const SearchFailure(this.error);
  
  @override
  List<Object?> get props => [error];
}

class CompanyLoading extends SearchState {}

class CompanySuccess extends SearchState {
  final Map<String, dynamic> details;
  
  const CompanySuccess(this.details);
  
  @override
  List<Object?> get props => [details];
}

class CompanyFailure extends SearchState {
  final String error;
  
  const CompanyFailure(this.error);
  
  @override
  List<Object?> get props => [error];
}