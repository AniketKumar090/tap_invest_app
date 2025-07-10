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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
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

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Company Header Section
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Company Logo and Name
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'INFRA.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                               
                              ],
                            ),
                            SizedBox(height: 24),
                            
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
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'ISIN: ${details['isin'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    details['status'] ?? 'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Tab Bar
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.blue[600],
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: Colors.blue[600],
                          indicatorWeight: 3,
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
                      
                      // Tab Content
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // ISIN Analysis Tab
                            _buildISINAnalysisTab(details, issuerDetails),
                            // Pros & Cons Tab
                            _buildProsConsTab(prosCons),
                          ],
                        ),
                      ),
                    ],
                  ),
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
      child: Column(
        children: [
          SizedBox(height: 16),
          
          // Company Financials Section
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'COMPANY FINANCIALS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        _buildChartToggle('EBITDA', Colors.blue),
                        SizedBox(width: 16),
                        _buildChartToggle('Revenue', Colors.grey),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Chart
                if ((details['financials'] as Map?) != null)
                  _buildModernChart(details['financials'] as Map),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Issuer Details Section
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(20),
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
                    Icon(Icons.business, size: 20, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      'Issuer Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
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
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 24),
            
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
            
            SizedBox(height: 24),
            
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
            margin: EdgeInsets.only(top: 4),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isPros ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPros ? Icons.check : Icons.warning,
              size: 12,
              color: isPros ? Colors.green[600] : Colors.orange[600],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.blue[600] : Colors.grey[500],
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
              color: _selectedChart == 'EBITDA' ? Colors.blue : Colors.grey[800],
              width: 12,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue(data) * 1.2,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[index]['month']?.toString().substring(0, 1) ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatValue(value),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
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
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
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
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}