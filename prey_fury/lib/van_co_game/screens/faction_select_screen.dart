/// Faction Select Screen - Choose your Ngũ Hành faction
///
/// Displays all 5 factions with:
/// - Visual preview
/// - Stats comparison
/// - Abilities description
/// - Counter relationships

import 'package:flutter/material.dart';

import '../../kernel/models/ngu_hanh_faction.dart';

/// Faction Select Screen Widget
class FactionSelectScreen extends StatefulWidget {
  final void Function(NguHanhFaction faction) onFactionSelected;
  final VoidCallback? onBack;

  const FactionSelectScreen({
    super.key,
    required this.onFactionSelected,
    this.onBack,
  });

  @override
  State<FactionSelectScreen> createState() => _FactionSelectScreenState();
}

class _FactionSelectScreenState extends State<FactionSelectScreen>
    with SingleTickerProviderStateMixin {
  NguHanhFaction? _selectedFaction;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Faction Cards
            Expanded(
              child: _buildFactionGrid(),
            ),

            // Selected Faction Details
            if (_selectedFaction != null) _buildSelectedDetails(),

            // Play Button
            _buildPlayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Back button and title
          Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: widget.onBack,
                ),
              const Expanded(
                child: Text(
                  'CHỌN TỘC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance for back button
            ],
          ),

          const SizedBox(height: 8),

          // Counter chain hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🐝 Kim → 🐍 Mộc → 🦂 Thổ → 🐛 Thủy → 🐸 Hỏa → 🐝 Kim',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactionGrid() {
    final factions = NguHanhFaction.values;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: factions.length,
        itemBuilder: (context, index) {
          final faction = factions[index];
          return _buildFactionCard(faction);
        },
      ),
    );
  }

  Widget _buildFactionCard(NguHanhFaction faction) {
    final data = NguHanhRegistry.get(faction);
    final isSelected = _selectedFaction == faction;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFaction = faction;
        });
        _animController.forward(from: 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? data.primaryColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? data.primaryColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.primaryColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji
              Text(
                data.emoji,
                style: const TextStyle(fontSize: 48),
              ),

              const SizedBox(height: 8),

              // Name
              Text(
                data.nameVi,
                style: TextStyle(
                  color: isSelected ? data.primaryColor : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              // Creature name
              Text(
                data.creatureVi,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 8),

              // Counters info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '⚔️ ${NguHanhRegistry.get(data.counters).emoji}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '💀 ${NguHanhRegistry.get(data.counteredBy).emoji}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDetails() {
    final data = NguHanhRegistry.get(_selectedFaction!);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutBack,
          )),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: data.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: data.primaryColor, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(data.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.nameVi,
                          style: TextStyle(
                            color: data.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          data.creatureVi,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stats
                _buildStatsRow(data),

                const SizedBox(height: 16),

                // Abilities
                _buildAbilitySection('Nội Công', data.passive.nameVi, data.passive.descriptionVi),
                const SizedBox(height: 8),
                _buildAbilitySection('Chiêu Thức', data.active.nameVi, data.active.descriptionVi),

                const SizedBox(height: 12),

                // Counter info
                Row(
                  children: [
                    Expanded(
                      child: _buildCounterInfo(
                        'Khắc chế',
                        data.counters,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildCounterInfo(
                        'Bị khắc',
                        data.counteredBy,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(NguHanhFactionData data) {
    final stats = data.baseStats;

    return Row(
      children: [
        _buildStatBar('HP', stats.hp, 160, Colors.red),
        const SizedBox(width: 8),
        _buildStatBar('ATK', stats.attack, 14, Colors.orange),
        const SizedBox(width: 8),
        _buildStatBar('SPD', stats.speed, 150, Colors.cyan),
        const SizedBox(width: 8),
        _buildStatBar('DEF', (stats.defense * 100).toInt(), 35, Colors.blue),
      ],
    );
  }

  Widget _buildStatBar(String label, int value, int max, Color color) {
    final percentage = value / max;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilitySection(String type, String name, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCounterInfo(String label, NguHanhFaction faction, Color color) {
    final data = NguHanhRegistry.get(faction);

    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        Text(
          data.emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(
          data.nameVi,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    final canPlay = _selectedFaction != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: canPlay
              ? () => widget.onFactionSelected(_selectedFaction!)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canPlay
                ? NguHanhRegistry.get(_selectedFaction!).primaryColor
                : Colors.grey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (canPlay) ...[
                Text(
                  NguHanhRegistry.get(_selectedFaction!).emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
              ],
              const Text(
                'BẮT ĐẦU',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
