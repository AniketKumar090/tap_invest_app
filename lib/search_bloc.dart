import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final TapInvestRepository repository;
  List<dynamic> _allBonds = [];

  SearchBloc(this.repository) : super(SearchInitial()) {
    on<LoadBondList>(_onLoadBondList);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<CompanySelected>(_onCompanySelected);
    
    // Auto-load bonds when bloc is created
    add(LoadBondList());
  }

  Future<void> _onLoadBondList(LoadBondList event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    try {
      print('Loading bond list...');
      _allBonds = await repository.fetchBondList();
      print('Loaded ${_allBonds.length} bonds');
      emit(SearchSuccess(_allBonds));
    } catch (e) {
      print('Error loading bonds: $e');
      emit(SearchFailure(e.toString()));
    }
  }

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    if (event.query.isEmpty) {
      emit(SearchSuccess(_allBonds));
    } else {
      final filteredBonds = _allBonds.where((bond) {
        final name = bond['company_name']?.toString().toLowerCase() ?? '';
        final isin = bond['isin']?.toString().toLowerCase() ?? '';
        final query = event.query.toLowerCase();
        return name.contains(query) || isin.contains(query);
      }).toList();
      
      print('Filtered ${filteredBonds.length} bonds for query: ${event.query}');
      emit(SearchSuccess(filteredBonds));
    }
  }

  Future<void> _onCompanySelected(CompanySelected event, Emitter<SearchState> emit) async {
    emit(CompanyLoading());
    try {
      print('Loading company details for ISIN: ${event.isin}');
      final details = await repository.fetchBondDetails(event.isin);
      print('Loaded company details successfully');
      emit(CompanySuccess(details));
    } catch (e) {
      print('Error loading company details: $e');
      emit(CompanyFailure(e.toString()));
    }
  }
}