import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppLogo extends StatefulWidget {
  final double size;
  final bool isIcon; // true for app icon, false for app logo

  const AppLogo({
    super.key,
    required this.size,
    this.isIcon = false,
  });

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> {
  final _supabase = Supabase.instance.client;
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final response = await _supabase
          .from('app_configuration')
          .select(widget.isIcon ? 'app_icon_url' : 'app_logo_url')
          .eq('is_active', true)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _imageUrl = widget.isIcon 
              ? response['app_icon_url'] 
              : response['app_logo_url'];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE91E63),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.isIcon ? 8 : 12),
        child: Image.network(
          _imageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE91E63),
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF00BCD4)],
        ),
        borderRadius: BorderRadius.circular(widget.isIcon ? 8 : 12),
      ),
      child: Icon(
        widget.isIcon ? Icons.apps : Icons.account_balance,
        size: widget.size * 0.5,
        color: Colors.white,
      ),
    );
  }
}