import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/homestay.dart';

class HomestayListScreen extends StatefulWidget {
  const HomestayListScreen({super.key});

  @override
  State<HomestayListScreen> createState() => _HomestayListScreenState();
}

class _HomestayListScreenState extends State<HomestayListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Homestay> _allHomestays = [];
  List<Homestay> _homestays = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedState = 'All States';
  String _selectedDistrict = 'All Districts';
  int _resultLimit = 20;

  static const double _imageHeight = 170;
  static const List<int> _resultLimits = [10, 20, 50];
  static const List<String> _stateOptions = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
  ];
  static const String _baseUrl =
      'http://slum78.myddns.me/homestay2u/api/homestays/';

  @override
  void initState() {
    super.initState();
    _fetchHomestays();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHomestays({String search = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final Map<String, String> queryParameters = {
        'limit': _resultLimit.toString(),
      };

      if (search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      if (_selectedState != 'All States') {
        queryParameters['state'] = _selectedState;
      }

      if (_selectedDistrict != 'All Districts') {
        queryParameters['district'] = _selectedDistrict;
      }

      final Uri url = Uri.parse(
        _baseUrl,
      ).replace(queryParameters: queryParameters);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = _getHomestayList(response.body);
        final homestays = jsonList
            .map((json) => Homestay.fromJson(json))
            .take(_resultLimit)
            .toList();

        setState(() {
          _allHomestays = homestays;
          _applyFilters();
        });
      } else {
        setState(() {
          _errorMessage = 'Unable to load data from server';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Internet connection failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getHomestayList(String responseBody) {
    final decodedData = jsonDecode(responseBody);

    if (decodedData is List) {
      return decodedData;
    }

    if (decodedData is Map<String, dynamic>) {
      if (decodedData['data'] is List) {
        return decodedData['data'];
      }

      if (decodedData['homestays'] is List) {
        return decodedData['homestays'];
      }
    }

    return [];
  }

  void _searchHomestays() {
    final keyword = _searchController.text.trim();
    if (keyword.isNotEmpty) {
      setState(() {
        _searchHistory = [
          keyword,
          ..._searchHistory.where(
            (item) => item.toLowerCase() != keyword.toLowerCase(),
          ),
        ].take(5).toList();
      });
    }
    _fetchHomestays(search: keyword);
  }

  Future<void> _refreshHomestays() {
    return _fetchHomestays(search: _searchController.text.trim());
  }

  List<String> get _states {
    return ['All States', ..._stateOptions];
  }

  List<String> get _districts {
    final source = _selectedState == 'All States'
        ? _allHomestays
        : _allHomestays
              .where((homestay) => homestay.state == _selectedState)
              .toList();

    final districts =
        source
            .map((homestay) => homestay.district)
            .where(
              (district) => district.isNotEmpty && district != 'No district',
            )
            .toSet()
            .toList()
          ..sort();

    return ['All Districts', ...districts];
  }

  void _applyFilters() {
    final filtered = _allHomestays.where((homestay) {
      final matchesState =
          _selectedState == 'All States' || homestay.state == _selectedState;
      final matchesDistrict =
          _selectedDistrict == 'All Districts' ||
          homestay.district == _selectedDistrict;

      return matchesState && matchesDistrict;
    }).toList();

    _homestays = filtered.take(_resultLimit).toList();
    _errorMessage = _homestays.isEmpty ? 'No homestay found' : '';
  }

  void _openDetails(Homestay homestay) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HomestayDetailScreen(homestay: homestay),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshHomestays,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _homestays.length,
        itemBuilder: (context, index) {
          final homestay = _homestays[index];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => _openDetails(homestay),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _imageHeight,
                    width: double.infinity,
                    child: _buildHomestayImage(homestay),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homestay.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(Icons.location_on, homestay.state),
                            _buildInfoChip(Icons.map, homestay.district),
                            _buildInfoChip(
                              Icons.payments,
                              'RM ${homestay.price}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          homestay.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            height: 1.4,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'View details',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    final states = _states;
    final districts = _districts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search homestay',
              hintText: 'Enter keyword',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: _searchHomestays,
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) => _searchHomestays(),
          ),
          if (_searchHistory.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((keyword) {
                return InputChip(
                  avatar: const Icon(Icons.history, size: 18),
                  label: Text(keyword),
                  onPressed: () {
                    _searchController.text = keyword;
                    _searchHomestays();
                  },
                  onDeleted: () {
                    setState(() {
                      _searchHistory.remove(keyword);
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: states.contains(_selectedState)
                      ? _selectedState
                      : 'All States',
                  decoration: const InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: states.map((state) {
                    return DropdownMenuItem(value: state, child: Text(state));
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedState = value;
                      _selectedDistrict = 'All Districts';
                    });
                    _fetchHomestays(search: _searchController.text.trim());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: districts.contains(_selectedDistrict)
                      ? _selectedDistrict
                      : 'All Districts',
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: districts.map((district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedDistrict = value;
                    });
                    _fetchHomestays(search: _searchController.text.trim());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${_homestays.length} result${_homestays.length == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Text('Limit'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _resultLimit,
                items: _resultLimits.map((limit) {
                  return DropdownMenuItem(
                    value: limit,
                    child: Text(limit.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _resultLimit = value;
                  });
                  _fetchHomestays(search: _searchController.text.trim());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomestayImage(Homestay homestay) {
    if (homestay.imageUrl.isEmpty) {
      return _buildImagePlaceholder();
    }

    return Image.network(
      homestay.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder();
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.teal.shade700),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.teal.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.teal.shade50,
      alignment: Alignment.center,
      child: Icon(Icons.home_work, size: 48, color: Colors.teal.shade200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homestay2U Malaysia')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

class HomestayDetailScreen extends StatelessWidget {
  const HomestayDetailScreen({super.key, required this.homestay});

  final Homestay homestay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(homestay.name)),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: homestay.imageUrl.isNotEmpty
                ? Image.network(
                    homestay.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const _DetailImagePlaceholder();
                    },
                  )
                : const _DetailImagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homestay.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'State',
                  value: homestay.state,
                ),
                _DetailRow(
                  icon: Icons.map,
                  label: 'District',
                  value: homestay.district,
                ),
                _DetailRow(
                  icon: Icons.payments,
                  label: 'Price Min',
                  value: 'RM ${homestay.price}',
                ),
                const SizedBox(height: 18),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  homestay.description,
                  style: const TextStyle(height: 1.5, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(
                  context,
                ).style.copyWith(fontSize: 16, height: 1.35),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.teal.shade50,
      alignment: Alignment.center,
      child: Icon(Icons.home_work, size: 64, color: Colors.teal.shade200),
    );
  }
}
