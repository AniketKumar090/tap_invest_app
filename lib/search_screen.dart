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
        backgroundColor: Color(0xFFF6F6F6), // Updated background color
        appBar: AppBar(
          title: Text(
            'Home',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Color(0xFFF6F6F6),
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
          titleSpacing: 16,
        ),
        body: Column(
          children: [
            Container(
              color: Color(0xFFF6F6F6),
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
                    return Container(
                      color: Color(0xFFF6F6F6),
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
                    return Container(
                      color: Color(0xFFF6F6F6), // Updated background color
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (_cachedBonds.isNotEmpty && !_showSuggestions) {
                    final bondsToShow = _currentQuery.isEmpty ? _cachedBonds : _getFilteredBonds();
                    
                    if (bondsToShow.isEmpty) {
                      return Container(
                        color: Color(0xFFF6F6F6), // Updated background color
                        child: Center(
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
                      ),
                    );
                  }

                    return _buildHomeView(bondsToShow);
                  }

                  if (state is SearchFailure) {
                    return Container(
                      color: Color(0xFFF6F6F6), // Updated background color
                      child: Center(
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
                      ),
                    );
                  }


                  return Container(
                    color: Color(0xFFF6F6F6), // Updated background color
                    child: Center(
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
      color: Color(0xFFF6F6F6), // Updated background color
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: bonds.length,
                  itemBuilder: (context, index) {
                    return _buildSuggestionItem(bond: bonds[index], terms: terms, index: index, totalItems: bonds.length);
                  },
                ),
              ),
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
        color: Color(0xFFF6F6F6), // Updated background color
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
      color: Color(0xFFF6F6F6), // Updated background color
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    return _buildSuggestionItem(bond: suggestions[index], terms: terms, index: index, totalItems: suggestions.length);
                  },
                ),
              ),
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
          if (suffix.isNotEmpty)
            ..._buildHighlightedTextSpans(
              suffix,
              terms,
              TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem({required dynamic bond, required List<String> terms, required int index, required int totalItems}) {
    BorderRadius borderRadius;
    
    if (index == 0 && index == totalItems - 1) {
      // Single item
      borderRadius = BorderRadius.circular(16);
    } else if (index == 0) {
      // First item
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      );
    } else if (index == totalItems - 1) {
      // Last item
      borderRadius = BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      );
    } else {
      // Middle items
      borderRadius = BorderRadius.zero;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Same as search bar color
        borderRadius: borderRadius,
        border: Border(
          bottom: index == totalItems - 1 ? BorderSide.none : BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.read<SearchBloc>().add(
            CompanySelected(bond['isin']),
          );
        },
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[100]!,
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
      ),
    );
  }

  // Fixed highlighting method
  List<TextSpan> _buildHighlightedTextSpans(String text, List<String> terms, TextStyle style) {
    if (terms.isEmpty || text.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    
    // Create a list to track which characters should be highlighted
    List<bool> shouldHighlight = List.filled(text.length, false);
    
    // Mark characters that match any search term
    for (String term in terms) {
      if (term.isEmpty) continue;
      String lowerTerm = term.toLowerCase();
      
      int index = 0;
      while (index < lowerText.length) {
        int matchIndex = lowerText.indexOf(lowerTerm, index);
        if (matchIndex == -1) break;
        
        // Mark this range as highlighted
        for (int i = matchIndex; i < matchIndex + lowerTerm.length && i < shouldHighlight.length; i++) {
          shouldHighlight[i] = true;
        }
        
        index = matchIndex + 1;
      }
    }
    
    // Build spans based on the highlighting map
    int currentIndex = 0;
    while (currentIndex < text.length) {
      bool isHighlighted = shouldHighlight[currentIndex];
      int spanStart = currentIndex;
      
      // Find the end of this span (consecutive characters with same highlight state)
      while (currentIndex < text.length && shouldHighlight[currentIndex] == isHighlighted) {
        currentIndex++;
      }
      
      String spanText = text.substring(spanStart, currentIndex);
      
      if (isHighlighted) {
        spans.add(TextSpan(
          text: spanText,
          style: style.copyWith(
            backgroundColor: Color(0xFFFFF3CD), // Light yellow color similar to your image
            color: Colors.black,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: spanText,
          style: style,
        ));
      }
    }
    
    return spans.isEmpty ? [TextSpan(text: text, style: style)] : spans;
  }

  Widget _buildMultiTermHighlightedText(
    String text, 
    List<String> terms, 
    TextStyle style, {
    int? maxLines,
    TextOverflow? overflow,
  }) {
    if (terms.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    List<TextSpan> spans = _buildHighlightedTextSpans(text, terms, style);

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}