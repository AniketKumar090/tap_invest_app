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

  @override
  void initState() {
    super.initState();
    // Load the bond list when the screen initializes
    context.read<SearchBloc>().add(LoadBondList());
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
      return _cachedBonds.where((bond) {
        final name = bond['company_name']?.toString().toLowerCase() ?? '';
        final isin = bond['isin']?.toString().toLowerCase() ?? '';
        final query = _currentQuery.toLowerCase();
        return name.contains(query) || isin.contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // This will unfocus the TextField when tapping anywhere on the screen
      onTap: () {
        _searchFocusNode.unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search by Issuer Name or ISIN',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (query) {
                  setState(() {
                    _currentQuery = query;
                  });
                },
              ),
              SizedBox(height: 16),
              Expanded(
                child: BlocConsumer<SearchBloc, SearchState>(
                  listener: (context, state) {
                    if (state is SearchSuccess) {
                      // Cache the bonds locally
                      _cachedBonds = state.bonds;
                    } else if (state is CompanySuccess) {
                      // Navigate to details screen
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
                        // Unfocus the search field when returning from details screen
                        _searchFocusNode.unfocus();
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
                    // Show loading only when initially loading or when no cached data
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
                    
                    // Show loading indicator for company details
                    if (state is CompanyLoading) {
                      return Center(child: CircularProgressIndicator());
                    }

                    // Always show cached bonds when available
                    if (_cachedBonds.isNotEmpty) {
                      final filteredBonds = _getFilteredBonds();
                      
                      if (filteredBonds.isEmpty) {
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

                      return ListView.builder(
                        itemCount: filteredBonds.length,
                        itemBuilder: (context, index) {
                          final bond = filteredBonds[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: _getRatingColor(bond['rating']),
                                radius: 24,
                                child: bond['logo'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Image.network(
                                          bond['logo'],
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(
                                              _getInitials(bond['company_name']),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Text(
                                        _getInitials(bond['company_name']),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              title: Text(
                                bond['company_name']?.toString() ?? 'Unknown Company',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    'ISIN: ${bond['isin']?.toString() ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (bond['rating'] != null) ...[
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
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
                                      ],
                                    ),
                                  ],
                                  if (bond['tags'] != null && bond['tags'].isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      children: (bond['tags'] as List).take(3).map((tag) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
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
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                              onTap: () {
                                context.read<SearchBloc>().add(
                                  CompanySelected(bond['isin']),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }

                    // Handle error states
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

                    // Default loading state
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
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'B';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
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