import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../graphics/pet_painter.dart';
import '../../models/companion_model.dart';
import '../../models/pet_state.dart';

class CompanionBuilderDialog extends StatefulWidget {
  final CompanionModel currentCompanion;
  final ValueChanged<CompanionModel> onSave;

  const CompanionBuilderDialog({
    super.key,
    required this.currentCompanion,
    required this.onSave,
  });

  @override
  State<CompanionBuilderDialog> createState() => _CompanionBuilderDialogState();
}

class _CompanionBuilderDialogState extends State<CompanionBuilderDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CompanionModel _previewCompanion;
  late TextEditingController _nameController;
  late TextEditingController _promptController;

  Offset _previewGaze = Offset.zero;
  double _previewAnimTime = 0.0;
  late final Stream<int> _animStream;

  final List<String> _samplePrompts = [
    'A sleepy matcha dragon with tiny golden horns who loves code files',
    'A cyberpunk galaxy blue bunny with cool shades that loves music',
    'A sweet pink sakura kitten with a star badge who loves pictures',
    'A cozy golden shiba with a warm red winter scarf named Hachi',
    'A mysterious lavender kitsune fox wizard who loves books and pdfs',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _previewCompanion = widget.currentCompanion.copyWith();
    _nameController = TextEditingController(text: _previewCompanion.name);
    _promptController = TextEditingController();

    _animStream = Stream.periodic(const Duration(milliseconds: 32), (i) => i);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _generateFromPrompt(String prompt) {
    if (prompt.trim().isEmpty) return;
    setState(() {
      _previewCompanion = CompanionModel.fromPrompt(prompt);
      _nameController.text = _previewCompanion.name;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Generated "${_previewCompanion.name}" (${_previewCompanion.archetype.name})!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.purple.shade700,
      ),
    );
  }

  Future<void> _pickCustomSprite() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _previewCompanion = _previewCompanion.copyWith(
            archetype: CompanionArchetype.customSprite,
            customSpritePath: result.files.single.path,
          );
        });
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 840,
        height: 620,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Row(
                  children: [
                    // Left: Live Preview Stage
                    _buildPreviewStage(),
                    Container(width: 1, color: Colors.white.withValues(alpha: 0.1)),
                    // Right: Customizer Tabs
                    Expanded(child: _buildCustomizerTabs()),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF282A3A),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 26),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Companion Builder Wizard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Create your custom companion from prompts, palettes, or image files',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStage() {
    return Container(
      width: 290,
      color: const Color(0xFF181824),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            _previewCompanion.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_previewCompanion.archetype.name.toUpperCase()} • ${_previewCompanion.personality.name.toUpperCase()}',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          // Interactive Preview Canvas tracking cursor
          MouseRegion(
            onHover: (event) {
              setState(() {
                final local = event.localPosition;
                final dx = (local.dx - 110) / 110;
                final dy = (local.dy - 110) / 110;
                _previewGaze = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
              });
            },
            child: StreamBuilder<int>(
              stream: _animStream,
              builder: (context, snapshot) {
                _previewAnimTime += 0.032;
                return Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: CustomPaint(
                    painter: PetPainter(
                      companion: _previewCompanion,
                      mood: PetMood.idle,
                      animationTime: _previewAnimTime,
                      gazeOffset: _previewGaze,
                      gazeDistance: 100.0,
                      trickProgress: 0.0,
                      activeTrickId: null,
                      particles: [],
                      hasBurrow: false,
                    ),
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          const Text(
            'Move mouse over companion to preview eye gaze!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizerTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.psychology, size: 20), text: 'Prompt Magic'),
            Tab(icon: Icon(Icons.palette, size: 20), text: 'Archetype & Colors'),
            Tab(icon: Icon(Icons.image, size: 20), text: 'Custom Sprite'),
            Tab(icon: Icon(Icons.settings, size: 20), text: 'Personality & Files'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPromptTab(),
              _buildPaletteTab(),
              _buildSpriteTab(),
              _buildPersonalityTab(),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 1: PROMPT GENERATOR ---
  Widget _buildPromptTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Describe your dream companion in natural language:',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _promptController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. A sleepy matcha dragon with tiny golden horns who loves markdown files...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _generateFromPrompt(_promptController.text),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate Companion with Magic ✨'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E44AD),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Or tap an inspiration idea to try:',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._samplePrompts.map((prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  _promptController.text = prompt;
                  _generateFromPrompt(prompt);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 12),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  // --- TAB 2: ARCHETYPE & PALETTE ---
  Widget _buildPaletteTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Choose Archetype:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CompanionArchetype.values
              .where((a) => a != CompanionArchetype.customSprite)
              .map((archetype) {
            final isSelected = _previewCompanion.archetype == archetype;
            return ChoiceChip(
              label: Text(archetype.name.toUpperCase()),
              selected: isSelected,
              selectedColor: Colors.amber.shade700,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _previewCompanion = _previewCompanion.copyWith(archetype: archetype);
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Color Palette:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildColorPickerRow('Body / Fur Color', _previewCompanion.primaryColor, (c) {
          setState(() => _previewCompanion = _previewCompanion.copyWith(primaryColor: c));
        }),
        _buildColorPickerRow('Belly / Muzzle Color', _previewCompanion.secondaryColor, (c) {
          setState(() => _previewCompanion = _previewCompanion.copyWith(secondaryColor: c));
        }),
        _buildColorPickerRow('Accent (Ears/Tail)', _previewCompanion.accentColor, (c) {
          setState(() => _previewCompanion = _previewCompanion.copyWith(accentColor: c));
        }),
        _buildColorPickerRow('Eye Color', _previewCompanion.eyeColor, (c) {
          setState(() => _previewCompanion = _previewCompanion.copyWith(eyeColor: c));
        }),
        const SizedBox(height: 20),
        const Text('Accessory:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CompanionAccessory.values.map((acc) {
            final isSelected = _previewCompanion.accessory == acc;
            return ChoiceChip(
              label: Text(acc.name),
              selected: isSelected,
              selectedColor: Colors.purple.shade600,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _previewCompanion = _previewCompanion.copyWith(accessory: acc));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorPickerRow(String label, Color currentColor, ValueChanged<Color> onColorChanged) {
    final palette = [
      const Color(0xFFE67E22), // Orange
      const Color(0xFFE74C3C), // Red
      const Color(0xFFFF8DA1), // Pink
      const Color(0xFFF4D03F), // Gold
      const Color(0xFF58D68D), // Mint Green
      const Color(0xFF3498DB), // Sky Blue
      const Color(0xFFA569BD), // Purple
      const Color(0xFF2C3E50), // Navy
      const Color(0xFFFFF8E7), // Cream
      const Color(0xFFFFFFFF), // White
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: palette.map((col) {
              final isChosen = currentColor.toARGB32() == col.toARGB32();
              return GestureDetector(
                onTap: () => onColorChanged(col),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isChosen ? Colors.white : Colors.transparent,
                      width: isChosen ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: CUSTOM SPRITE IMPORTER ---
  Widget _buildSpriteTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Import Custom Mascot Image',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your own PNG, GIF, or JPEG graphic to use as your desktop buddy.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickCustomSprite,
            icon: const Icon(Icons.file_upload),
            label: const Text('Select Image File...'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2980B9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          if (_previewCompanion.customSpritePath != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _previewCompanion.customSpritePath!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 4: PERSONALITY & FILE TASTES ---
  Widget _buildPersonalityTab() {
    final allExts = ['.dart', '.png', '.jpg', '.pdf', '.md', '.txt', '.js', '.py', '.mp3', '.json'];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Companion Name:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          onChanged: (val) {
            setState(() => _previewCompanion.name = val.trim().isEmpty ? 'Buddy' : val.trim());
          },
          decoration: InputDecoration(
            hintText: 'Enter name (e.g. Mochi, Pip, Sparky)...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Personality Trait:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PetPersonality.values.map((pers) {
            final isSelected = _previewCompanion.personality == pers;
            return ChoiceChip(
              label: Text(pers.name.toUpperCase()),
              selected: isSelected,
              selectedColor: Colors.teal.shade600,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _previewCompanion = _previewCompanion.copyWith(personality: pers));
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Favorite Desktop File Types to Sniff:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allExts.map((ext) {
            final isFav = _previewCompanion.favoriteFileExtensions.contains(ext);
            return FilterChip(
              label: Text(ext),
              selected: isFav,
              selectedColor: Colors.amber.shade700,
              onSelected: (selected) {
                setState(() {
                  final list = List<String>.from(_previewCompanion.favoriteFileExtensions);
                  if (selected) {
                    list.add(ext);
                  } else {
                    list.remove(ext);
                  }
                  _previewCompanion = _previewCompanion.copyWith(favoriteFileExtensions: list);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF282A3A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              widget.onSave(_previewCompanion);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('Activate Companion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
