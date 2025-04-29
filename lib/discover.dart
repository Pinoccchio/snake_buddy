import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake_buddy/details.dart';
import 'package:snake_buddy/info.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<StatefulWidget> createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage> {
  List<dynamic> snakes = [];
  List<dynamic> filteredSnakes = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSnakeData();
    _searchController.addListener(_filterSnakes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSnakes);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadSnakeData() async {
    try {
      // Load Philippine snakes data
      final String data = await rootBundle.loadString('assets/models/philippine_snakes.json');
      setState(() {
        snakes = json.decode(data);
        // Removed the "Random photos" entry

        filteredSnakes = snakes;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading snake data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterSnakes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredSnakes = snakes.where((snake) {
        final name = snake['name'].toLowerCase();
        final scientificName = snake['scientific_name'].toLowerCase();
        return name.contains(query) || scientificName.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'Philippine Snakes',
              style: TextStyle(
                fontSize: 30,
                fontFamily: 'Actor',
                color: Colors.white,
              ),
            ),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const InfoPage(),
                      transitionDuration: const Duration(milliseconds: 200),
                      transitionsBuilder: (_, a, __, c) =>
                          FadeTransition(opacity: a, child: c),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                ),
                iconSize: 25,
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(color: Colors.white, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(color: Colors.white, width: 1.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    labelText: 'Search',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                    ),
                    fillColor: Theme.of(context).colorScheme.surfaceDim.withOpacity(0.5),
                    filled: true,
                    labelStyle: const TextStyle(
                        color: Colors.white
                    ),
                  ),
                  cursorColor: Colors.white,
                  style: const TextStyle(
                      color: Colors.white
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: filteredSnakes.map<Widget>((snake) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailsPage(
                                  result: snake as Map<String, dynamic>,
                                  showLoading: false,
                                  capturedImage: AssetImage(snake['image_path'] ?? 'assets/images/default.png'),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20.0),
                            height: 125,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceDim,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(19.0),
                                    bottomLeft: Radius.circular(19.0),
                                  ),
                                  child: Image.asset(
                                    snake['image_path'] ?? 'assets/images/default.png',
                                    height: 125,
                                    width: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback if image fails to load
                                      return Container(
                                        height: 125,
                                        width: 150,
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          snake['name'] ?? 'Unknown Snake',
                                          style: const TextStyle(
                                            fontFamily: 'Actor',
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          snake['scientific_name'] ??
                                              'Unknown scientific name',
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          snake['description'] ?? 'No description available',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }
}
