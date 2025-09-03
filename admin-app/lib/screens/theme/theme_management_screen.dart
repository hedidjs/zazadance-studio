import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class ThemeManagementScreen extends StatefulWidget {
  const ThemeManagementScreen({super.key});

  @override
  State<ThemeManagementScreen> createState() => _ThemeManagementScreenState();
}

class _ThemeManagementScreenState extends State<ThemeManagementScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  Map<String, dynamic>? _currentTheme;
  bool _isLoading = true;
  bool _isSaving = false;

  // Background settings
  String _backgroundType = 'solid';
  Color _backgroundColor = const Color(0xFF121212);
  Color _gradientStartColor = const Color(0xFFE91E63);
  Color _gradientEndColor = const Color(0xFF00BCD4);
  String _gradientDirection = 'topLeft-bottomRight';
  String? _backgroundImageUrl;
  double _backgroundImageOpacity = 1.0;
  String _backgroundImageFit = 'cover';
  Color? _overlayColor;
  double _overlayOpacity = 0.5;

  // Text colors
  Color _primaryTextColor = Colors.white;
  Color _secondaryTextColor = Colors.white70;
  Color _accentTextColor = const Color(0xFF00BCD4);

  // UI colors
  Color _primaryColor = const Color(0xFFE91E63);
  Color _secondaryColor = const Color(0xFF00BCD4);
  Color _surfaceColor = const Color(0xFF1E1E1E);
  Color _cardColor = const Color(0xFF1E1E1E);

  // Button colors
  Color _buttonPrimaryBg = const Color(0xFFE91E63);
  Color _buttonPrimaryText = Colors.white;
  Color _buttonSecondaryBg = const Color(0xFF00BCD4);
  Color _buttonSecondaryText = Colors.white;

  // Navigation colors
  Color _bottomNavBg = const Color(0xFF1E1E1E);
  Color _bottomNavSelected = const Color(0xFFE91E63);
  Color _bottomNavUnselected = Colors.grey;
  Color _drawerBg = const Color(0xFF1E1E1E);
  Color _drawerHeaderGradientStart = const Color(0xFFE91E63);
  Color _drawerHeaderGradientEnd = const Color(0xFF00BCD4);

  // Input colors
  Color _inputBg = const Color(0xFF2A2A2A);
  Color _inputBorder = const Color(0xFF333333);
  Color _inputFocusBorder = const Color(0xFFE91E63);
  Color _inputText = Colors.white;
  Color _inputLabel = const Color(0xFF00BCD4);

  // Login/Register screen colors
  Color _loginBg = const Color(0xFF121212);
  Color _loginCardBg = const Color(0xFF1E1E1E);
  Color _loginWelcomeText = Colors.white;
  Color _loginSubtitleText = Colors.white70;
  Color _loginLogoTint = Colors.white;
  Color _loginButtonPrimary = const Color(0xFFE91E63);
  Color _loginButtonPrimaryText = Colors.white;
  Color _loginButtonSecondary = const Color(0xFF00BCD4);
  Color _loginButtonSecondaryText = Colors.white;
  Color _loginLinkText = const Color(0xFF00BCD4);
  Color _loginErrorText = Colors.red;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadCurrentTheme();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTheme() async {
    try {
      final response = await _supabase
          .from('app_theme')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        _currentTheme = response;
        _loadThemeValues(response);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('שגיאה בטעינת הנושא: $e');
    }
  }

  void _loadThemeValues(Map<String, dynamic> theme) {
    setState(() {
      _backgroundType = theme['background_type'] ?? 'solid';
      _backgroundColor = _colorFromHex(theme['background_color']) ?? const Color(0xFF121212);
      _gradientStartColor = _colorFromHex(theme['gradient_start_color']) ?? const Color(0xFFE91E63);
      _gradientEndColor = _colorFromHex(theme['gradient_end_color']) ?? const Color(0xFF00BCD4);
      _gradientDirection = theme['gradient_direction'] ?? 'topLeft-bottomRight';
      _backgroundImageUrl = theme['background_image_url'];
      _backgroundImageOpacity = (theme['background_image_opacity'] as num?)?.toDouble() ?? 1.0;
      _backgroundImageFit = theme['background_image_fit'] ?? 'cover';
      _overlayColor = _colorFromHex(theme['overlay_color']);
      _overlayOpacity = (theme['overlay_opacity'] as num?)?.toDouble() ?? 0.5;

      _primaryTextColor = _colorFromHex(theme['primary_text_color']) ?? Colors.white;
      _secondaryTextColor = _colorFromHex(theme['secondary_text_color']) ?? Colors.white70;
      _accentTextColor = _colorFromHex(theme['accent_text_color']) ?? const Color(0xFF00BCD4);

      _primaryColor = _colorFromHex(theme['primary_color']) ?? const Color(0xFFE91E63);
      _secondaryColor = _colorFromHex(theme['secondary_color']) ?? const Color(0xFF00BCD4);
      _surfaceColor = _colorFromHex(theme['surface_color']) ?? const Color(0xFF1E1E1E);
      _cardColor = _colorFromHex(theme['card_color']) ?? const Color(0xFF1E1E1E);

      _buttonPrimaryBg = _colorFromHex(theme['button_primary_bg']) ?? const Color(0xFFE91E63);
      _buttonPrimaryText = _colorFromHex(theme['button_primary_text']) ?? Colors.white;
      _buttonSecondaryBg = _colorFromHex(theme['button_secondary_bg']) ?? const Color(0xFF00BCD4);
      _buttonSecondaryText = _colorFromHex(theme['button_secondary_text']) ?? Colors.white;

      _bottomNavBg = _colorFromHex(theme['bottom_nav_bg']) ?? const Color(0xFF1E1E1E);
      _bottomNavSelected = _colorFromHex(theme['bottom_nav_selected']) ?? const Color(0xFFE91E63);
      _bottomNavUnselected = _colorFromHex(theme['bottom_nav_unselected']) ?? Colors.grey;
      _drawerBg = _colorFromHex(theme['drawer_bg']) ?? const Color(0xFF1E1E1E);
      _drawerHeaderGradientStart = _colorFromHex(theme['drawer_header_gradient_start']) ?? const Color(0xFFE91E63);
      _drawerHeaderGradientEnd = _colorFromHex(theme['drawer_header_gradient_end']) ?? const Color(0xFF00BCD4);

      _inputBg = _colorFromHex(theme['input_bg']) ?? const Color(0xFF2A2A2A);
      _inputBorder = _colorFromHex(theme['input_border']) ?? const Color(0xFF333333);
      _inputFocusBorder = _colorFromHex(theme['input_focus_border']) ?? const Color(0xFFE91E63);
      _inputText = _colorFromHex(theme['input_text']) ?? Colors.white;
      _inputLabel = _colorFromHex(theme['input_label']) ?? const Color(0xFF00BCD4);

      _loginBg = _colorFromHex(theme['login_bg']) ?? const Color(0xFF121212);
      _loginCardBg = _colorFromHex(theme['login_card_bg']) ?? const Color(0xFF1E1E1E);
      _loginWelcomeText = _colorFromHex(theme['login_welcome_text']) ?? Colors.white;
      _loginSubtitleText = _colorFromHex(theme['login_subtitle_text']) ?? Colors.white70;
      _loginLogoTint = _colorFromHex(theme['login_logo_tint']) ?? Colors.white;
      _loginButtonPrimary = _colorFromHex(theme['login_button_primary']) ?? const Color(0xFFE91E63);
      _loginButtonPrimaryText = _colorFromHex(theme['login_button_primary_text']) ?? Colors.white;
      _loginButtonSecondary = _colorFromHex(theme['login_button_secondary']) ?? const Color(0xFF00BCD4);
      _loginButtonSecondaryText = _colorFromHex(theme['login_button_secondary_text']) ?? Colors.white;
      _loginLinkText = _colorFromHex(theme['login_link_text']) ?? const Color(0xFF00BCD4);
      _loginErrorText = _colorFromHex(theme['login_error_text']) ?? Colors.red;
    });
  }

  Color? _colorFromHex(String? hexString) {
    if (hexString == null) return null;
    try {
      if (hexString.length == 9) {
        // Handle colors with alpha
        return Color(int.parse(hexString.substring(1), radix: 16));
      } else {
        return Color(int.parse(hexString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      return null;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('עיצוב האפליקציה'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'רקע'),
            Tab(text: 'טקסטים'),
            Tab(text: 'ממשק'),
            Tab(text: 'כפתורים'),
            Tab(text: 'ניווט'),
            Tab(text: 'כניסה'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBackgroundTab(),
                _buildTextColorsTab(),
                _buildUIColorsTab(),
                _buildButtonColorsTab(),
                _buildNavigationColorsTab(),
                _buildLoginTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveTheme,
        backgroundColor: Colors.blue,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isSaving ? 'שומר...' : 'שמירת עיצוב',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBackgroundTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('סוג רקע'),
          _buildBackgroundTypeSelector(),
          const SizedBox(height: 20),
          
          if (_backgroundType == 'solid') ...[
            _buildColorPicker('צבע רקע', _backgroundColor, (color) {
              setState(() => _backgroundColor = color);
            }),
          ],
          
          if (_backgroundType == 'gradient') ...[
            _buildColorPicker('צבע התחלה', _gradientStartColor, (color) {
              setState(() => _gradientStartColor = color);
            }),
            const SizedBox(height: 16),
            _buildColorPicker('צבע סיום', _gradientEndColor, (color) {
              setState(() => _gradientEndColor = color);
            }),
            const SizedBox(height: 16),
            _buildGradientDirectionSelector(),
          ],
          
          if (_backgroundType == 'image' || _backgroundType == 'image_with_overlay') ...[
            _buildImageUploadSection(),
            const SizedBox(height: 16),
            _buildImageSettingsSection(),
          ],
          
          if (_backgroundType == 'image_with_overlay') ...[
            const SizedBox(height: 16),
            _buildOverlaySection(),
          ],
        ],
      ),
    );
  }

  Widget _buildTextColorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildColorPicker('צבע טקסט ראשי', _primaryTextColor, (color) {
            setState(() => _primaryTextColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('צבע טקסט משני', _secondaryTextColor, (color) {
            setState(() => _secondaryTextColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('צבע טקסט מודגש', _accentTextColor, (color) {
            setState(() => _accentTextColor = color);
          }),
        ],
      ),
    );
  }

  Widget _buildUIColorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildColorPicker('צבע ראשי', _primaryColor, (color) {
            setState(() => _primaryColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('צבע משני', _secondaryColor, (color) {
            setState(() => _secondaryColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('צבע משטח', _surfaceColor, (color) {
            setState(() => _surfaceColor = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('צבע כרטיס', _cardColor, (color) {
            setState(() => _cardColor = color);
          }),
        ],
      ),
    );
  }

  Widget _buildButtonColorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle('כפתור ראשי'),
          _buildColorPicker('רקע כפתור ראשי', _buttonPrimaryBg, (color) {
            setState(() => _buttonPrimaryBg = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('טקסט כפתור ראשי', _buttonPrimaryText, (color) {
            setState(() => _buttonPrimaryText = color);
          }),
          const SizedBox(height: 24),
          
          _buildSectionTitle('כפתור משני'),
          _buildColorPicker('רקע כפתור משני', _buttonSecondaryBg, (color) {
            setState(() => _buttonSecondaryBg = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('טקסט כפתור משני', _buttonSecondaryText, (color) {
            setState(() => _buttonSecondaryText = color);
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationColorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle('ניווט תחתון'),
          _buildColorPicker('רקע', _bottomNavBg, (color) {
            setState(() => _bottomNavBg = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('פריט נבחר', _bottomNavSelected, (color) {
            setState(() => _bottomNavSelected = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('פריט לא נבחר', _bottomNavUnselected, (color) {
            setState(() => _bottomNavUnselected = color);
          }),
          const SizedBox(height: 24),
          
          _buildSectionTitle('תפריט צד'),
          _buildColorPicker('רקע תפריט', _drawerBg, (color) {
            setState(() => _drawerBg = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('כותרת - תחילת גרדיאנט', _drawerHeaderGradientStart, (color) {
            setState(() => _drawerHeaderGradientStart = color);
          }),
          const SizedBox(height: 16),
          _buildColorPicker('כותרת - סוף גרדיאנט', _drawerHeaderGradientEnd, (color) {
            setState(() => _drawerHeaderGradientEnd = color);
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBackgroundTypeSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('צבע אחיד', style: TextStyle(color: Colors.white)),
          value: 'solid',
          groupValue: _backgroundType,
          activeColor: Colors.blue,
          onChanged: (value) => setState(() => _backgroundType = value!),
        ),
        RadioListTile<String>(
          title: const Text('גרדיאנט צבעים', style: TextStyle(color: Colors.white)),
          value: 'gradient',
          groupValue: _backgroundType,
          activeColor: Colors.blue,
          onChanged: (value) => setState(() => _backgroundType = value!),
        ),
        RadioListTile<String>(
          title: const Text('תמונת רקע', style: TextStyle(color: Colors.white)),
          value: 'image',
          groupValue: _backgroundType,
          activeColor: Colors.blue,
          onChanged: (value) => setState(() => _backgroundType = value!),
        ),
        RadioListTile<String>(
          title: const Text('תמונת רקע עם שכבת צבע', style: TextStyle(color: Colors.white)),
          value: 'image_with_overlay',
          groupValue: _backgroundType,
          activeColor: Colors.blue,
          onChanged: (value) => setState(() => _backgroundType = value!),
        ),
      ],
    );
  }

  Widget _buildGradientDirectionSelector() {
    return DropdownButtonFormField<String>(
      value: _gradientDirection,
      decoration: const InputDecoration(
        labelText: 'כיוון גרדיאנט',
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Color(0xFF2A2A2A),
      ),
      dropdownColor: const Color(0xFF2A2A2A),
      style: const TextStyle(color: Colors.white),
      items: const [
        DropdownMenuItem(value: 'topLeft-bottomRight', child: Text('מלמעלה שמאל לתחתית ימין')),
        DropdownMenuItem(value: 'topRight-bottomLeft', child: Text('מלמעלה ימין לתחתית שמאל')),
        DropdownMenuItem(value: 'top-bottom', child: Text('מלמעלה לתחתית')),
        DropdownMenuItem(value: 'left-right', child: Text('משמאל לימין')),
        DropdownMenuItem(value: 'center-radial', child: Text('רדיאלי מהמרכז')),
      ],
      onChanged: (value) => setState(() => _gradientDirection = value!),
    );
  }

  Widget _buildColorPicker(String label, Color currentColor, Function(Color) onColorChanged) {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: Container(
          width: 50,
          height: 30,
          decoration: BoxDecoration(
            color: currentColor,
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        onTap: () => _showColorPicker(currentColor, onColorChanged),
      ),
    );
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('בחירת צבע', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            labelTypes: const [],
            pickerAreaBorderRadius: BorderRadius.circular(8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('תמונת רקע', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_backgroundImageUrl != null) ...[
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_backgroundImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _uploadBackgroundImage,
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text('העלאת תמונה', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSettingsSection() {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('הגדרות תמונה', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _backgroundImageFit,
              decoration: const InputDecoration(
                labelText: 'התאמת תמונה',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
              ),
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'cover', child: Text('כיסוי מלא')),
                DropdownMenuItem(value: 'contain', child: Text('התאמה מלאה')),
                DropdownMenuItem(value: 'fill', child: Text('מילוי')),
                DropdownMenuItem(value: 'fitWidth', child: Text('התאמה לרוחב')),
                DropdownMenuItem(value: 'fitHeight', child: Text('התאמה לגובה')),
              ],
              onChanged: (value) => setState(() => _backgroundImageFit = value!),
            ),
            const SizedBox(height: 16),
            Text('שקיפות: ${(_backgroundImageOpacity * 100).toInt()}%', style: const TextStyle(color: Colors.white)),
            Slider(
              value: _backgroundImageOpacity,
              onChanged: (value) => setState(() => _backgroundImageOpacity = value),
              min: 0.1,
              max: 1.0,
              divisions: 9,
              activeColor: Colors.blue,
              inactiveColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlaySection() {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('שכבת צבע', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildColorPicker('צבע השכבה', _overlayColor ?? Colors.black, (color) {
              setState(() => _overlayColor = color);
            }),
            const SizedBox(height: 16),
            Text('שקיפות שכבה: ${(_overlayOpacity * 100).toInt()}%', style: const TextStyle(color: Colors.white)),
            Slider(
              value: _overlayOpacity,
              onChanged: (value) => setState(() => _overlayOpacity = value),
              min: 0.0,
              max: 1.0,
              divisions: 10,
              activeColor: Colors.blue,
              inactiveColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadBackgroundImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        
        if (bytes != null) {
          final fileName = 'background_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';
          
          await _supabase.storage
              .from('app-assets')
              .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
          
          final imageUrl = _supabase.storage
              .from('app-assets')
              .getPublicUrl(fileName);
          
          setState(() {
            _backgroundImageUrl = imageUrl;
          });
          
          _showSuccessSnackBar('התמונה הועלתה בהצלחה');
        }
      }
    } catch (e) {
      _showErrorSnackBar('שגיאה בהעלאת התמונה: $e');
    }
  }

  Future<void> _saveTheme() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final themeData = {
        'background_type': _backgroundType,
        'background_color': _colorToHex(_backgroundColor),
        'gradient_start_color': _colorToHex(_gradientStartColor),
        'gradient_end_color': _colorToHex(_gradientEndColor),
        'gradient_direction': _gradientDirection,
        'background_image_url': _backgroundImageUrl,
        'background_image_opacity': _backgroundImageOpacity,
        'background_image_fit': _backgroundImageFit,
        'overlay_color': _overlayColor != null ? _colorToHex(_overlayColor!) : null,
        'overlay_opacity': _overlayOpacity,
        'primary_text_color': _colorToHex(_primaryTextColor),
        'secondary_text_color': _colorToHex(_secondaryTextColor),
        'accent_text_color': _colorToHex(_accentTextColor),
        'primary_color': _colorToHex(_primaryColor),
        'secondary_color': _colorToHex(_secondaryColor),
        'surface_color': _colorToHex(_surfaceColor),
        'card_color': _colorToHex(_cardColor),
        'button_primary_bg': _colorToHex(_buttonPrimaryBg),
        'button_primary_text': _colorToHex(_buttonPrimaryText),
        'button_secondary_bg': _colorToHex(_buttonSecondaryBg),
        'button_secondary_text': _colorToHex(_buttonSecondaryText),
        'bottom_nav_bg': _colorToHex(_bottomNavBg),
        'bottom_nav_selected': _colorToHex(_bottomNavSelected),
        'bottom_nav_unselected': _colorToHex(_bottomNavUnselected),
        'drawer_bg': _colorToHex(_drawerBg),
        'drawer_header_gradient_start': _colorToHex(_drawerHeaderGradientStart),
        'drawer_header_gradient_end': _colorToHex(_drawerHeaderGradientEnd),
        'input_bg': _colorToHex(_inputBg),
        'input_border': _colorToHex(_inputBorder),
        'input_focus_border': _colorToHex(_inputFocusBorder),
        'input_text': _colorToHex(_inputText),
        'input_label': _colorToHex(_inputLabel),
        
        // Login/Register colors
        'login_bg': _colorToHex(_loginBg),
        'login_card_bg': _colorToHex(_loginCardBg),
        'login_welcome_text': _colorToHex(_loginWelcomeText),
        'login_subtitle_text': _colorToHex(_loginSubtitleText),
        'login_logo_tint': _colorToHex(_loginLogoTint),
        'login_button_primary': _colorToHex(_loginButtonPrimary),
        'login_button_primary_text': _colorToHex(_loginButtonPrimaryText),
        'login_button_secondary': _colorToHex(_loginButtonSecondary),
        'login_button_secondary_text': _colorToHex(_loginButtonSecondaryText),
        'login_link_text': _colorToHex(_loginLinkText),
        'login_error_text': _colorToHex(_loginErrorText),
        
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_currentTheme != null) {
        await _supabase
            .from('app_theme')
            .update(themeData)
            .eq('id', _currentTheme!['id']);
      } else {
        themeData['is_active'] = true;
        themeData['name'] = 'Default Theme';
        await _supabase.from('app_theme').insert(themeData);
      }

      _showSuccessSnackBar('העיצוב נשמר בהצלחה!');
    } catch (e) {
      _showErrorSnackBar('שגיאה בשמירת העיצוב: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // כותרת
          const Text(
            'עיצוב מסכי כניסה והרשמה',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Background
          Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'רקע וכרטיסיות',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Login Background
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginBg,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('רקע מסך הכניסה', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginBg, (color) => setState(() => _loginBg = color)),
                  ),
                  
                  // Login Card Background
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginCardBg,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('רקע כרטיסיית הכניסה', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginCardBg, (color) => setState(() => _loginCardBg = color)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Text Colors
          Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'צבעי טקסט',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Welcome Text
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginWelcomeText,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('טקסט ברוכים הבאים', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginWelcomeText, (color) => setState(() => _loginWelcomeText = color)),
                  ),
                  
                  // Subtitle Text
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginSubtitleText,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('טקסט משני', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginSubtitleText, (color) => setState(() => _loginSubtitleText = color)),
                  ),
                  
                  // Link Text
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginLinkText,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('צבע קישורים', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginLinkText, (color) => setState(() => _loginLinkText = color)),
                  ),
                  
                  // Error Text
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginErrorText,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('צבע הודעות שגיאה', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginErrorText, (color) => setState(() => _loginErrorText = color)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logo & Branding
          Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'לוגו ומיתוג',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Logo Tint
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginLogoTint,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('גוון לוגו', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginLogoTint, (color) => setState(() => _loginLogoTint = color)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Buttons
          Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'כפתורים',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Primary Button Background
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginButtonPrimary,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('רקע כפתור ראשי', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginButtonPrimary, (color) => setState(() => _loginButtonPrimary = color)),
                  ),
                  
                  // Primary Button Text
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginButtonPrimaryText,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('טקסט כפתור ראשי', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginButtonPrimaryText, (color) => setState(() => _loginButtonPrimaryText = color)),
                  ),
                  
                  // Secondary Button Background
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginButtonSecondary,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('רקע כפתור משני', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginButtonSecondary, (color) => setState(() => _loginButtonSecondary = color)),
                  ),
                  
                  // Secondary Button Text
                  ListTile(
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _loginButtonSecondaryText,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: const Text('טקסט כפתור משני', style: TextStyle(color: Colors.white)),
                    onTap: () => _showColorPicker(_loginButtonSecondaryText, (color) => setState(() => _loginButtonSecondaryText = color)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100), // מקום לכפתור השמירה
        ],
      ),
    );
  }
}