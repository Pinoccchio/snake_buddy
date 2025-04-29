import 'dart:async';
import 'package:flutter/material.dart';
import 'package:snake_buddy/info.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({
    super.key,
    required this.result,
    this.showLoading = true,
    this.capturedImage,
  });

  final Map<String, dynamic> result;
  final bool showLoading;
  final ImageProvider? capturedImage;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  bool isLoading = true;
  bool isContentVisible = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    if (widget.showLoading) {
      await Future.delayed(const Duration(seconds: 1));
    }

    setState(() {
      isLoading = false;
      isContentVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.only(left: 10.0, top: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.5),
            child: IconButton(
              padding: const EdgeInsets.only(left: 10.0),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
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
      extendBodyBehindAppBar: true,
      body: isLoading
          ? Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Loading...",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 50),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                )
              ],
            ),
          ),
        ],
      )
          : AnimatedOpacity(
        opacity: isContentVisible ? 1.0 : 0.0,
        duration: const Duration(seconds: 1),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 320,
                child: PageView(
                  children: [
                    if (widget.capturedImage != null)
                      Image(
                        image: widget.capturedImage!,
                        fit: BoxFit.cover,
                      ),
                    // Default image as fallback
                    Image.asset(
                      'assets/images/default.png',
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 280),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.result['name'] ?? 'Unknown Snake',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Actor',
                                        ),
                                      ),
                                      Text(
                                        widget.result['scientific_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                          fontFamily: 'Actor',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildDangerBadge(context),
                              ],
                            ),
                            const SizedBox(height: 25),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildInfoCard(
                                    context,
                                    'Venomous',
                                    _getBoolValue(widget.result['venomous']) ? 'Yes' : 'No',
                                    _getBoolValue(widget.result['venomous'])
                                        ? Icons.warning
                                        : Icons.local_florist,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildInfoCard(
                                    context,
                                    'Aquatic',
                                    _getBoolValue(widget.result['marine']) ? 'Yes' : 'No',
                                    Icons.water,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildInfoCard(
                                    context,
                                    'Conservation Status',
                                    widget.result['conservation_status'] ?? 'Unknown',
                                    Icons.eco,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Tab navigation
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  children: [
                                    _buildTabButton(0, 'Overview'),
                                    _buildTabButton(1, 'Identification'),
                                    _buildTabButton(2, 'Safety'),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Tab content
                            _buildTabContent(),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildIdentificationTab();
      case 2:
        return _buildSafetyTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.result['description'] ?? 'No description available',
          style: const TextStyle(
            fontSize: 16,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 20),

        // Habitat section
        _buildSectionTitle('Habitat & Distribution'),
        _buildInfoRow(
          Icons.terrain,
          'Habitat',
          _generateHabitat(),
        ),
        const SizedBox(height: 10),
        _buildInfoRow(
          Icons.public,
          'Geographic Range',
          _generateGeographicRange(),
        ),

        const SizedBox(height: 20),

        // Behavior section
        _buildSectionTitle('Behavior & Diet'),
        _buildInfoRow(
          Icons.psychology,
          'Behavior',
          _generateBehavior(),
        ),
        const SizedBox(height: 10),
        _buildInfoRow(
          Icons.restaurant,
          'Diet',
          _generateDiet(),
        ),

        const SizedBox(height: 20),

        // Fun facts
        _buildSectionTitle('Did You Know?'),
        _buildFunFact(),
      ],
    );
  }

  Widget _buildIdentificationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Theme.of(context).secondaryHeaderColor,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Key Identification Features',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Actor',
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Size: ${_getClassificationValue(widget.result, 'size')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Color Pattern: ${_getClassificationValue(widget.result, 'color_pattern')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Distinct Feature: ${_getClassificationValue(widget.result, 'distinct_feature')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Similar Species'),
        Text(
          _generateSimilarSpecies(),
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Life Cycle'),
        Text(
          _generateLifeCycle(),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSafetyTab() {
    final isVenomous = _getBoolValue(widget.result['venomous']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isVenomous ? Colors.red.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isVenomous ? Colors.red.shade300 : Colors.green.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isVenomous ? Icons.warning_amber_rounded : Icons.check_circle,
                size: 40,
                color: isVenomous ? Colors.red.shade700 : Colors.green.shade700,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVenomous ? 'Venomous Snake' : 'Non-Venomous Snake',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isVenomous ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      isVenomous
                          ? 'This snake is venomous and potentially dangerous. Exercise extreme caution.'
                          : 'This snake is not venomous and generally not dangerous to humans.',
                      style: TextStyle(
                        color: isVenomous ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Safety Guidelines'),
        _buildSafetyGuideline(
          'Keep a safe distance from all snakes, regardless of whether they are venomous.',
          Icons.social_distance,
        ),
        _buildSafetyGuideline(
          'Never attempt to handle, capture, or kill a snake.',
          Icons.pan_tool,
        ),
        _buildSafetyGuideline(
          'If bitten, seek immediate medical attention, even if the snake is non-venomous.',
          Icons.local_hospital,
        ),
        _buildSafetyGuideline(
          'Do not try to suck out venom or apply a tourniquet.',
          Icons.do_not_disturb_alt,
        ),

        const SizedBox(height: 20),

        _buildSectionTitle('If You Encounter This Snake'),
        Text(
          _generateEncounterAdvice(isVenomous),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSafetyGuideline(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Actor',
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFunFact() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade800),
              const SizedBox(width: 10),
              Text(
                'Fun Fact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _generateFunFact(),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerBadge(BuildContext context) {
    final isVenomous = _getBoolValue(widget.result['venomous']);
    if (!isVenomous) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
          SizedBox(width: 5),
          Text(
            'VENOMOUS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  bool _getBoolValue(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
    }
    return false;
  }

  String _getClassificationValue(Map<String, dynamic> data, String key) {
    if (data.containsKey('classification') && data['classification'] is Map) {
      final classification = data['classification'] as Map;
      if (classification.containsKey(key)) {
        return classification[key]?.toString() ?? 'Unknown';
      }
    }
    return 'Unknown';
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon) {
    Color backgroundColor;

    switch (title) {
      case 'Venomous':
        backgroundColor = value == 'Yes' ? Colors.red.withOpacity(0.5) : Colors.lightGreen.withOpacity(0.5);
        break;
      case 'Aquatic':
        backgroundColor = Colors.blue.withOpacity(0.5);
        break;
      case 'Conservation Status':
        backgroundColor = Colors.lightGreen.withOpacity(0.5);
        break;
      default:
        backgroundColor = Theme.of(context).primaryColor.withOpacity(0.5);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Actor',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Actor',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to generate content based on snake type
  String _generateHabitat() {
    final name = widget.result['name']?.toString().toLowerCase() ?? '';
    final isVenomous = _getBoolValue(widget.result['venomous']);
    final isAquatic = _getBoolValue(widget.result['marine']);

    if (isAquatic) {
      return 'Primarily aquatic, found in freshwater environments such as rivers, lakes, and swamps.';
    } else if (name.contains('python') || name.contains('boa')) {
      return 'Found in tropical and subtropical forests, often near water sources.';
    } else if (name.contains('viper') || name.contains('rattlesnake')) {
      return 'Prefers rocky terrain, deserts, and dry forest environments.';
    } else if (name.contains('cobra')) {
      return 'Inhabits a variety of environments including forests, plains, and agricultural areas.';
    } else if (name.contains('mamba')) {
      return 'Primarily arboreal, living in trees in forests and savannas.';
    } else {
      return isVenomous
          ? 'Typically found in diverse habitats including forests, grasslands, and rocky areas.'
          : 'Adaptable to various environments including woodlands, grasslands, and suburban areas.';
    }
  }

  String _generateGeographicRange() {
    final name = widget.result['name']?.toString().toLowerCase() ?? '';

    if (name.contains('python')) {
      return 'Native to Asia, Africa, and Australia.';
    } else if (name.contains('boa')) {
      return 'Found in the Americas, primarily Central and South America.';
    } else if (name.contains('cobra')) {
      return 'Distributed across Africa and Asia.';
    } else if (name.contains('viper')) {
      return 'Found in Europe, Asia, and Africa.';
    } else if (name.contains('rattlesnake')) {
      return 'Native to the Americas, from southern Canada to Argentina.';
    } else if (name.contains('mamba')) {
      return 'Endemic to sub-Saharan Africa.';
    } else {
      return 'Distribution varies based on species, but commonly found across multiple continents.';
    }
  }

  String _generateBehavior() {
    final isVenomous = _getBoolValue(widget.result['venomous']);
    final isAquatic = _getBoolValue(widget.result['marine']);

    if (isAquatic) {
      return 'Excellent swimmer, spends most of its time in or near water. Generally active during the day.';
    } else if (isVenomous) {
      return 'Primarily nocturnal, tends to be secretive and will avoid confrontation when possible, but will defend itself if threatened.';
    } else {
      return 'Can be active during day or night depending on temperature. Generally non-aggressive and will flee rather than confront threats.';
    }
  }

  String _generateDiet() {
    final name = widget.result['name']?.toString().toLowerCase() ?? '';
    final size = _getClassificationValue(widget.result, 'size').toLowerCase();

    if (name.contains('python') || name.contains('boa') || name.contains('anaconda')) {
      return 'Carnivorous, feeding primarily on mammals and birds. Kills prey by constriction.';
    } else if (size.contains('large')) {
      return 'Carnivorous, feeding on a variety of prey including rodents, birds, and occasionally other reptiles.';
    } else if (size.contains('medium')) {
      return 'Primarily feeds on small mammals, birds, and occasionally amphibians.';
    } else {
      return 'Diet consists mainly of small prey such as insects, small rodents, and lizards.';
    }
  }

  String _generateSimilarSpecies() {
    final name = widget.result['name']?.toString().toLowerCase() ?? '';

    if (name.contains('cobra')) {
      return 'May be confused with other cobra species or some non-venomous snakes that mimic cobra defensive postures.';
    } else if (name.contains('python')) {
      return 'Can be confused with other python species or large constrictors like boas.';
    } else if (name.contains('viper') || name.contains('rattlesnake')) {
      return 'May be confused with other pit vipers or harmless snakes with similar patterns.';
    } else {
      return 'Several non-venomous and venomous species may have similar coloration or patterns, making identification challenging without expert knowledge.';
    }
  }

  String _generateLifeCycle() {
    final name = widget.result['name']?.toString().toLowerCase() ?? '';

    if (name.contains('python') || name.contains('boa')) {
      return 'Reproduces by laying eggs or giving live birth depending on species. Young are independent from birth and receive no parental care.';
    } else if (name.contains('viper') || name.contains('rattlesnake')) {
      return 'Viviparous (gives birth to live young). Breeding typically occurs once per year, with litter sizes varying by species and female size.';
    } else {
      return 'Most species lay eggs (oviparous), though some give birth to live young. Hatchlings are fully independent from birth and must fend for themselves.';
    }
  }

  String _generateEncounterAdvice(bool isVenomous) {
    if (isVenomous) {
      return 'Remain calm and slowly back away. Do not make sudden movements or attempt to handle the snake. If you are at a safe distance, you can observe the snake, but always maintain that distance. Alert others in the area about the snake\'s presence.';
    } else {
      return 'While this snake is not venomous, it\'s still best to keep your distance. Observe from afar if you wish, but do not attempt to handle it. Even non-venomous snakes can bite if they feel threatened, which can lead to infection.';
    }
  }

  String _generateFunFact() {
    final name = widget.result['name']?.toString().toLowerCase() ?? '';
    final isVenomous = _getBoolValue(widget.result['venomous']);

    if (name.contains('python')) {
      return 'Pythons have heat-sensing pits that allow them to detect warm-blooded prey even in complete darkness!';
    } else if (name.contains('cobra')) {
      return 'A cobra\'s hood is formed by elongated ribs that extend the loose skin of the neck when the snake feels threatened.';
    } else if (name.contains('rattlesnake')) {
      return 'Rattlesnakes add a new segment to their rattle each time they shed their skin, which can be several times a year.';
    } else if (isVenomous) {
      return 'Snake venom is actually modified saliva that has evolved over millions of years to help snakes immobilize and digest their prey.';
    } else {
      return 'Snakes don\'t have eyelids and can\'t blink! Instead, their eyes are protected by a transparent scale called a spectacle or brille.';
    }
  }
}
