import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeMessagesManagementScreen extends StatefulWidget {
  const WelcomeMessagesManagementScreen({super.key});

  @override
  State<WelcomeMessagesManagementScreen> createState() => _WelcomeMessagesManagementScreenState();
}

class _WelcomeMessagesManagementScreenState extends State<WelcomeMessagesManagementScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _currentMessage;
  
  // Controllers for form
  final _messageHeController = TextEditingController();
  final _messageEnController = TextEditingController();
  final _backgroundColorController = TextEditingController(text: '#2D1B69');
  final _textColorController = TextEditingController(text: '#FFFFFF');
  final _borderColorController = TextEditingController(text: '#E91E63');
  final _borderRadiusController = TextEditingController(text: '16');
  final _borderWidthController = TextEditingController(text: '2');
  final _paddingHorizontalController = TextEditingController(text: '20');
  final _paddingVerticalController = TextEditingController(text: '16');
  final _marginHorizontalController = TextEditingController(text: '16');
  final _marginVerticalController = TextEditingController(text: '8');
  final _fontSizeController = TextEditingController(text: '18');
  
  bool _isActive = true;
  bool _hasBorder = true;
  String _fontWeight = 'bold';
  String _textAlign = 'center';

  @override
  void initState() {
    super.initState();
    _loadWelcomeMessage();
  }

  Future<void> _loadWelcomeMessage() async {
    try {
      final response = await _supabase
          .from('welcome_messages')
          .select('*')
          .order('created_at', ascending: false)
          .limit(1);
      
      if (response.isNotEmpty) {
        final message = response.first;
        setState(() {
          _currentMessage = message;
          _messageHeController.text = message['message_he'] ?? '';
          _messageEnController.text = message['message_en'] ?? '';
          _backgroundColorController.text = message['background_color'] ?? '#2D1B69';
          _textColorController.text = message['text_color'] ?? '#FFFFFF';
          _borderColorController.text = message['border_color'] ?? '#E91E63';
          _borderRadiusController.text = (message['border_radius'] ?? 16).toString();
          _borderWidthController.text = (message['border_width'] ?? 2).toString();
          _paddingHorizontalController.text = (message['padding_horizontal'] ?? 20).toString();
          _paddingVerticalController.text = (message['padding_vertical'] ?? 16).toString();
          _marginHorizontalController.text = (message['margin_horizontal'] ?? 16).toString();
          _marginVerticalController.text = (message['margin_vertical'] ?? 8).toString();
          _fontSizeController.text = (message['font_size'] ?? 18).toString();
          _isActive = message['is_active'] ?? true;
          _hasBorder = message['has_border'] ?? true;
          _fontWeight = message['font_weight'] ?? 'bold';
          _textAlign = message['text_align'] ?? 'center';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בטעינת ההודעה: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWelcomeMessage() async {
    if (_messageHeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להזין הודעה בעברית')),
      );
      return;
    }

    try {
      final messageData = {
        'message_he': _messageHeController.text.trim(),
        'message_en': _messageEnController.text.trim(),
        'background_color': _backgroundColorController.text.trim(),
        'text_color': _textColorController.text.trim(),
        'border_color': _borderColorController.text.trim(),
        'border_radius': int.tryParse(_borderRadiusController.text) ?? 16,
        'border_width': int.tryParse(_borderWidthController.text) ?? 2,
        'padding_horizontal': int.tryParse(_paddingHorizontalController.text) ?? 20,
        'padding_vertical': int.tryParse(_paddingVerticalController.text) ?? 16,
        'margin_horizontal': int.tryParse(_marginHorizontalController.text) ?? 16,
        'margin_vertical': int.tryParse(_marginVerticalController.text) ?? 8,
        'font_size': int.tryParse(_fontSizeController.text) ?? 18,
        'is_active': _isActive,
        'has_border': _hasBorder,
        'font_weight': _fontWeight,
        'text_align': _textAlign,
      };

      if (_currentMessage != null) {
        // Update existing message
        await _supabase
            .from('welcome_messages')
            .update(messageData)
            .eq('id', _currentMessage!['id']);
      } else {
        // Insert new message
        await _supabase
            .from('welcome_messages')
            .insert(messageData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ההודעה נשמרה בהצלחה')),
      );
      
      _loadWelcomeMessage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בשמירת ההודעה: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.waving_hand_outlined,
                  color: Color(0xFFE91E63),
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Text(
                  'ניהול הודעות ברוכים הבאים',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'עריכת ההודעה שמוצגת למשתמשים בדף הבית',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Section
                Expanded(
                  flex: 2,
                  child: _buildFormSection(),
                ),
                
                const SizedBox(width: 24),
                
                // Preview Section
                Expanded(
                  flex: 1,
                  child: _buildPreviewSection(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message Content
          const Text(
            'תוכן ההודעה',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _messageHeController,
            label: 'הודעה בעברית',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _messageEnController,
            label: 'הודעה באנגלית (אופציונלי)',
            maxLines: 2,
          ),
          
          const SizedBox(height: 32),
          
          // Styling Options
          const Text(
            'עיצוב ההודעה',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildColorField(
                  controller: _backgroundColorController,
                  label: 'צבע רקע',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildColorField(
                  controller: _textColorController,
                  label: 'צבע טקסט',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _fontSizeController,
                  label: 'גודל גופן',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  label: 'משקל גופן',
                  value: _fontWeight,
                  items: const [
                    'normal',
                    'bold',
                    'w500',
                    'w600',
                    'w700',
                  ],
                  onChanged: (value) => setState(() => _fontWeight = value!),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildDropdownField(
            label: 'יישור טקסט',
            value: _textAlign,
            items: const [
              'left',
              'center',
              'right',
            ],
            itemLabels: const {
              'left': 'שמאל',
              'center': 'מרכז',
              'right': 'ימין',
            },
            onChanged: (value) => setState(() => _textAlign = value!),
          ),
          
          const SizedBox(height: 24),
          
          // Border Settings
          Row(
            children: [
              Checkbox(
                value: _hasBorder,
                onChanged: (value) => setState(() => _hasBorder = value!),
                activeColor: const Color(0xFFE91E63),
              ),
              const Text(
                'הצגת גבול',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          
          if (_hasBorder) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildColorField(
                    controller: _borderColorController,
                    label: 'צבע גבול',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _borderWidthController,
                    label: 'עובי גבול',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _borderRadiusController,
            label: 'רדיוס פינות',
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 24),
          
          // Spacing Settings
          const Text(
            'ריווחים',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _paddingHorizontalController,
                  label: 'ריווח פנימי אופקי',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _paddingVerticalController,
                  label: 'ריווח פנימי אנכי',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _marginHorizontalController,
                  label: 'ריווח חיצוני אופקי',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _marginVerticalController,
                  label: 'ריווח חיצוני אנכי',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Active Toggle
          Row(
            children: [
              Checkbox(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value!),
                activeColor: const Color(0xFFE91E63),
              ),
              const Text(
                'הודעה פעילה',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveWelcomeMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'שמור הודעה',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'תצוגה מקדימה',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Preview Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D0D), // App background
            ),
            child: _buildMessagePreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagePreview() {
    if (_messageHeController.text.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: const Text(
          'הזן הודעה לתצוגה מקדימה',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: (int.tryParse(_marginHorizontalController.text) ?? 16).toDouble(),
        vertical: (int.tryParse(_marginVerticalController.text) ?? 8).toDouble(),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: (int.tryParse(_paddingHorizontalController.text) ?? 20).toDouble(),
        vertical: (int.tryParse(_paddingVerticalController.text) ?? 16).toDouble(),
      ),
      decoration: BoxDecoration(
        color: _parseColor(_backgroundColorController.text),
        borderRadius: BorderRadius.circular(
          (int.tryParse(_borderRadiusController.text) ?? 16).toDouble(),
        ),
        border: _hasBorder
            ? Border.all(
                color: _parseColor(_borderColorController.text),
                width: (int.tryParse(_borderWidthController.text) ?? 2).toDouble(),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        _messageHeController.text.trim(),
        textAlign: _getTextAlign(_textAlign),
        style: TextStyle(
          color: _parseColor(_textColorController.text),
          fontSize: (int.tryParse(_fontSizeController.text) ?? 18).toDouble(),
          fontWeight: _getFontWeight(_fontWeight),
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF2D1B69);
    }
  }

  TextAlign _getTextAlign(String alignment) {
    switch (alignment) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      default:
        return TextAlign.center;
    }
  }

  FontWeight _getFontWeight(String weight) {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
        return FontWeight.normal;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      default:
        return FontWeight.bold;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE91E63)),
            ),
            fillColor: const Color(0xFF2A2A2A),
            filled: true,
          ),
          onChanged: (value) => setState(() {}), // Trigger preview update
        ),
      ],
    );
  }

  Widget _buildColorField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(controller.text),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333333)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF333333)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF333333)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE91E63)),
                  ),
                  fillColor: const Color(0xFF2A2A2A),
                  filled: true,
                  hintText: '#FFFFFF',
                  hintStyle: const TextStyle(color: Colors.white38),
                ),
                onChanged: (value) => setState(() {}), // Trigger preview update
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    Map<String, String>? itemLabels,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE91E63)),
            ),
            fillColor: const Color(0xFF2A2A2A),
            filled: true,
          ),
          dropdownColor: const Color(0xFF2A2A2A),
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                itemLabels?[item] ?? item,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageHeController.dispose();
    _messageEnController.dispose();
    _backgroundColorController.dispose();
    _textColorController.dispose();
    _borderColorController.dispose();
    _borderRadiusController.dispose();
    _borderWidthController.dispose();
    _paddingHorizontalController.dispose();
    _paddingVerticalController.dispose();
    _marginHorizontalController.dispose();
    _marginVerticalController.dispose();
    _fontSizeController.dispose();
    super.dispose();
  }
}