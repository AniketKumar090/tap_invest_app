import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'search_bloc.dart';
import 'package:provider/provider.dart';

class CompanyDetailsScreen extends StatefulWidget {
  @override
  _CompanyDetailsScreenState createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedChart = 'EBITDA';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<SearchBloc>(
        builder: (context, searchBloc, child) {
          return BlocBuilder<SearchBloc, SearchState>(
            bloc: searchBloc,
            builder: (context, state) {
              if (state is CompanyLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (state is CompanySuccess) {
                final details = state.details;
                final issuerDetails = (details['issuer_details'] as Map?) ?? {};
                final prosCons = (details['pros_and_cons'] as Map?) ?? {};

                return Column(
                  children: [
                    // Fixed App Bar
                    Container(
                      color: Colors.white,
                      child: SafeArea(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white70,
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.arrow_back, size: 20, color: Colors.black),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Scrollable content with sticky tabs
                    Expanded(
                      child: NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                          return <Widget>[
                            SliverToBoxAdapter(
                              child: Container(
                                color: Colors.white,
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(16, 2, 16, 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Company Logo and Name - Aligned with back button
                                      Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey[200]!),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                details['logo'] ?? '',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'INFRA.\nMARKET',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      
                                      // Company Name
                                      Text(
                                        details['company_name'] ?? 'Unknown Company',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      
                                      // Company Description
                                      Text(
                                        details['description'] ?? 'No description available',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      
                                      // ISIN and Status
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'ISIN: ${details['isin'] ?? 'N/A'}',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              details['status'] ?? 'ACTIVE',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SliverPersistentHeader(
                              delegate: _SliverAppBarDelegate(
                                TabBar(
                                  controller: _tabController,
                                  labelColor: Colors.blue[600],
                                  unselectedLabelColor: Colors.grey[600],
                                  indicatorColor: Colors.blue[600],
                                  indicatorWeight: 3,
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  unselectedLabelStyle: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  tabs: [
                                    Tab(text: 'ISIN Analysis'),
                                    Tab(text: 'Pros & Cons'),
                                  ],
                                ),
                              ),
                              pinned: true,
                            ),
                          ];
                        },
                        body: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildISINAnalysisTab(details, issuerDetails),
                            _buildProsConsTab(prosCons),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              } else if (state is CompanyFailure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error: ${state.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Go Back'),
                      ),
                    ],
                  ),
                );
              }
              return Container();
            },
          );
        },
      ),
    );
  }

  Widget _buildISINAnalysisTab(Map details, Map issuerDetails) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          SizedBox(height: 16),
          
          // Company Financials Section
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with toggle buttons
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'COMPANY FINANCIALS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(maxWidth: 150),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildChartToggle('EBITDA', Colors.blue),
                            _buildChartToggle('Revenue', Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Chart
                if ((details['financials'] as Map?) != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildModernChart(details['financials'] as Map),
                  ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Issuer Details Section
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, size: 18, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Issuer Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                _buildDetailRow('Issuer Name', issuerDetails['issuer_name']),
                _buildDetailRow('Type of Issuer', issuerDetails['type_of_issuer']),
                _buildDetailRow('Sector', issuerDetails['sector']),
                _buildDetailRow('Industry', issuerDetails['industry']),
                _buildDetailRow('Issuer nature', issuerDetails['issuer_nature']),
                _buildDetailRow('Corporate Identity Number (CIN)', issuerDetails['cin']),
                _buildDetailRow('Name of the Lead Manager', issuerDetails['lead_manager'] ?? '-'),
                _buildDetailRow('Registrar', issuerDetails['registrar']),
                _buildDetailRow('Name of Debenture Trustee', issuerDetails['debenture_trustee']),
              ],
            ),
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProsConsTab(Map prosCons) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 20),
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pros and Cons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            
            // Pros Section
            Text(
              'Pros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 12),
            
            if (prosCons['pros'] != null)
              ...((prosCons['pros'] as List).map((pro) => _buildProsConsItem(pro, true))),
            
            SizedBox(height: 20),
            
            // Cons Section
            Text(
              'Cons',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
            SizedBox(height: 12),
            
            if (prosCons['cons'] != null)
              ...((prosCons['cons'] as List).map((con) => _buildProsConsItem(con, false))),
          ],
        ),
      ),
    );
  }

  Widget _buildProsConsItem(String text, bool isPros) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isPros ? Colors.green[100] : Colors.orange[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPros ? Icons.check : Icons.warning_amber_rounded,
              size: 14,
              color: isPros ? Colors.green[700] : Colors.orange[700],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggle(String label, Color color) {
    final isSelected = _selectedChart == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChart = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildModernChart(Map financials) {
    final data = _selectedChart == 'EBITDA' 
        ? (financials['ebitda'] as List?) ?? []
        : (financials['revenue'] as List?) ?? [];
    
    if (data.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No data available for $_selectedChart',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final value = (item['value'] as num?)?.toDouble() ?? 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: _selectedChart == 'EBITDA' ? Colors.blue[600] : Colors.grey[700],
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue(data) * 1.2,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      data[index]['month']?.toString().substring(0, 1) ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    _formatValue(value),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.blue[600],
            ),
          ),
          SizedBox(height: 3),
          Text(
            value?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxValue(List<dynamic> data) {
    double max = 0;
    for (var item in data) {
      final value = (item['value'] as num?)?.toDouble() ?? 0.0;
      if (value > max) max = value;
    }
    return max;
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '₹${(value / 1000000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${value.toStringAsFixed(0)}';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!, width: 1),
          ),
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}