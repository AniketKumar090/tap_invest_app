part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadBondList extends SearchEvent {}
class ResetToSearchState extends SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  final String query;
  
  const SearchQueryChanged(this.query);
  
  @override
  List<Object?> get props => [query];
}

class CompanySelected extends SearchEvent {
  final String isin;
  
  const CompanySelected(this.isin);
  
  @override
  List<Object?> get props => [isin];
}