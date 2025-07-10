import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_bloc.dart';
import 'company_details_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _cachedBonds = [];
  String _currentQuery = '';
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    context.read<SearchBloc>().add(LoadBondList());
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus && _currentQuery.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredBonds() {
    if (_currentQuery.isEmpty) {
      return _cachedBonds;
    } else {
      final terms = _currentQuery.toLowerCase().split(' ').where((term) => term.isNotEmpty).toList();
      
      return _cachedBonds.where((bond) {
        final name = bond['company_name']?.toString().toLowerCase() ?? '';
        final isin = bond['isin']?.toString().toLowerCase() ?? '';
        return terms.any((term) => name.contains(term) || isin.contains(term));
      }).toList();
    }
  }

  List<dynamic> _getSuggestedResults() {
    if (_currentQuery.isEmpty) return [];
    
    final terms = _currentQuery.toLowerCase().split(' ').where((term) => term.isNotEmpty).toList();
    
    return _cachedBonds.where((bond) {
      final name = bond['company_name']?.toString().toLowerCase() ?? '';
      final isin = bond['isin']?.toString().toLowerCase() ?? '';
      return terms.any((term) => name.contains(term) || isin.contains(term));
    }).take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        setState(() {
          _showSuggestions = false;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Color(0xFFF3F4F6), // Gray background
        appBar: AppBar(
          title: Text(
            'Home',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          titleSpacing: 16,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search by Issuer Name or ISIN',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (query) {
                  setState(() {
                    _currentQuery = query;
                    _showSuggestions = query.isNotEmpty && _searchFocusNode.hasFocus;
                  });
                },
                onTap: () {
                  setState(() {
                    _showSuggestions = _currentQuery.isNotEmpty;
                  });
                },
              ),
            ),
            
            Expanded(
              child: BlocConsumer<SearchBloc, SearchState>(
                listener: (context, state) {
                  if (state is SearchSuccess) {
                    _cachedBonds = state.bonds;
                  } else if (state is CompanySuccess) {
                    final searchBloc = context.read<SearchBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: searchBloc,
                          child: CompanyDetailsScreen(),
                        ),
                      ),
                    ).then((_) {
                      _searchFocusNode.unfocus();
                      setState(() {
                        _showSuggestions = false;
                      });
                    });
                  } else if (state is CompanyFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${state.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (_showSuggestions && _cachedBonds.isNotEmpty) {
                    return _buildSuggestionsView();
                  }
                  
                  if (state is SearchLoading && _cachedBonds.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading bonds...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state is CompanyLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (_cachedBonds.isNotEmpty && !_showSuggestions) {
                    final bondsToShow = _currentQuery.isEmpty ? _cachedBonds : _getFilteredBonds();
                    
                    if (bondsToShow.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No bonds found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try searching with different keywords',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildHomeView(bondsToShow);
                  }

                  if (state is SearchFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Error: ${state.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[400],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<SearchBloc>().add(LoadBondList());
                            },
                            icon: Icon(Icons.refresh),
                            label: Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading bonds...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView(List<dynamic> bonds) {
    final terms = _currentQuery.toLowerCase().split(' ').where((term) => term.isNotEmpty).toList();
    
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              'SUGGESTED RESULTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: bonds.length,
              itemBuilder: (context, index) {
                final bond = bonds[index];
                return _buildSuggestionItem(bond, terms);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsView() {
    final suggestions = _getSuggestedResults();
    final terms = _currentQuery.toLowerCase().split(' ').where((term) => term.isNotEmpty).toList();
    
    if (suggestions.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'No matching results found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    String headerText = _currentQuery.isEmpty ? 'SUGGESTED RESULTS' : 'SEARCH RESULTS';

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final bond = suggestions[index];
                return _buildSuggestionItem(bond, terms);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildISINDisplay(String isin, List<String> terms, String companyName) {
    if (isin.length < 8) {
      return Text(
        isin,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      );
    }

    String prefix = isin.substring(0, 8);
    String suffix = isin.length > 8 ? isin.substring(8) : '';

    bool suffixMatches = terms.any((term) => 
        suffix.toLowerCase().contains(term.toLowerCase()));
    bool companyNameMatches = terms.any((term) => 
        companyName.toLowerCase().contains(term.toLowerCase()));

    bool shouldPrefixBeBlack = companyNameMatches && suffixMatches;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: prefix,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: shouldPrefixBeBlack ? Colors.black : Colors.grey[500],
            ),
          ),
          TextSpan(
            text: suffix,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              backgroundColor: suffixMatches ? Colors.yellow[200] : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(dynamic bond, List<String> terms) {
    return Container(
      margin: EdgeInsets.only(bottom: 1),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.read<SearchBloc>().add(
            CompanySelected(bond['isin']),
          );
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orange[300]!,
                  width: 1.5,
                ),
              ),
              child: bond['logo'] != null
                  ? ClipOval(
                      child: Image.network(
                        bond['logo'],
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              'INFRA.\nMARKET',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                                height: 1.0,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        'INFRA.\nMARKET',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                          height: 1.0,
                        ),
                      ),
                    ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildISINDisplay(
                    bond['isin']?.toString() ?? 'N/A', 
                    terms,
                    bond['company_name']?.toString() ?? '',
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (bond['rating'] != null) ...[
                        Text(
                          bond['rating'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      Expanded(
                        child: _buildMultiTermHighlightedText(
                          bond['company_name']?.toString() ?? 'Unknown Company',
                          terms,
                          TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiTermHighlightedText(
    String text, 
    List<String> terms, 
    TextStyle style, {
    int? maxLines,
    TextOverflow? overflow,
  }) {
    if (terms.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final lowerText = text.toLowerCase();
    List<TextSpan> spans = [];
    int currentIndex = 0;

    List<Match> matches = [];
    for (final term in terms) {
      matches.addAll(term.allMatches(lowerText));
    }
    matches.sort((a, b) => a.start.compareTo(b.start));

    for (final match in matches) {
      if (currentIndex < match.start) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: style,
        ));
      }
      
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style.copyWith(
          backgroundColor: Colors.yellow[200],
          color: Colors.black,
        ),
      ));
      
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }

    if (spans.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  Widget _buildBondCard(dynamic bond) {
    final terms = _currentQuery.toLowerCase().split(' ').where((term) => term.isNotEmpty).toList();
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.read<SearchBloc>().add(
            CompanySelected(bond['isin']),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange[300]!,
                    width: 1.5,
                  ),
                ),
                child: bond['logo'] != null
                    ? ClipOval(
                        child: Image.network(
                          bond['logo'],
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                'INFRA.\nMARKET',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          'INFRA.\nMARKET',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMultiTermHighlightedText(
                      bond['company_name']?.toString() ?? 'Unknown Company',
                      terms,
                      TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    _buildISINDisplay(
                      bond['isin']?.toString() ?? 'N/A', 
                      terms,
                      bond['company_name']?.toString() ?? '',
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (bond['rating'] != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRatingColor(bond['rating']),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bond['rating'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        if (bond['tags'] != null && bond['tags'].isNotEmpty) ...[
                          ...((bond['tags'] as List).take(2).map((tag) {
                            return Container(
                              margin: EdgeInsets.only(right: 4),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                tag.toString(),
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList()),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(String? rating) {
    if (rating == null) return Colors.grey;
    
    switch (rating.toUpperCase()) {
      case 'AAA':
        return Colors.green[700]!;
      case 'AA+':
      case 'AA':
      case 'AA-':
        return Colors.green[600]!;
      case 'A+':
      case 'A':
      case 'A-':
        return Colors.blue[600]!;
      case 'BBB+':
      case 'BBB':
      case 'BBB-':
        return Colors.orange[600]!;
      default:
        return Colors.red[600]!;
    }
  }
}