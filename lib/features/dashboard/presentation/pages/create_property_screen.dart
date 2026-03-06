import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/core/utils/property_coordinates.dart';
import 'package:rentora/features/dashboard/presentation/widgets/location_picker_card.dart';

class CreatePropertyScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? property;
  final String? propertyId;

  const CreatePropertyScreen({super.key, this.property, this.propertyId});

  @override
  ConsumerState<CreatePropertyScreen> createState() =>
      _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends ConsumerState<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _bedroomsCtrl = TextEditingController();
  final _bathroomsCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();

  String _propertyType = 'room';
  String _petPolicy = 'not-allowed';
  bool _furnished = false;
  bool _parking = false;
  final List<String> _amenities = [];
  final List<XFile> _images = [];
  final List<String> _remoteImages = [];
  final List<String> _removedRemoteImages = [];
  bool _isEdit = false;
  PropertyCoordinates? _pinnedCoordinates;

  DateTime? _availStart;
  DateTime? _availEnd;
  bool _submitting = false;

  final _amenityOptions = [
    'WiFi',
    'AC',
    'Washing Machine',
    'Kitchen',
    'TV',
    'Gym',
    'Swimming Pool',
    'Security',
    'Power Backup',
    'Water Supply',
    'Elevator',
    'Garden',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _bedroomsCtrl.dispose();
    _bathroomsCtrl.dispose();
    _areaCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final prop = widget.property;
    if (prop != null) {
      _isEdit = true;
      _titleCtrl.text = (prop['title'] ?? '') as String;
      _descCtrl.text = (prop['description'] ?? '') as String;
      _locationCtrl.text = (prop['location'] ?? '') as String;
      _priceCtrl.text = (prop['price'] ?? '')?.toString() ?? '';
      _propertyType = (prop['propertyType'] ?? _propertyType) as String;
      _petPolicy = (prop['petPolicy'] ?? _petPolicy) as String;
      _furnished = (prop['furnished'] ?? _furnished) as bool;
      _parking = (prop['parking'] ?? _parking) as bool;
      _pinnedCoordinates = parsePropertyCoordinates(prop);

      if (prop['bedrooms'] != null) {
        _bedroomsCtrl.text = prop['bedrooms'].toString();
      }
      if (prop['bathrooms'] != null) {
        _bathroomsCtrl.text = prop['bathrooms'].toString();
      }
      if (prop['area'] != null) {
        _areaCtrl.text = prop['area'].toString();
      }
      if (prop['floor'] != null) {
        _floorCtrl.text = prop['floor'].toString();
      }

      // Amenities
      final List? amen = prop['amenities'] as List?;
      if (amen != null) {
        _amenities.addAll(amen.whereType<String>());
      }

      // Availability
      final List? avail = prop['availability'] as List?;
      if (avail != null && avail.isNotEmpty) {
        try {
          final first = avail.first as Map<String, dynamic>;
          _availStart = DateTime.parse(first['startDate'] as String);
          _availEnd = DateTime.parse(first['endDate'] as String);
        } catch (_) {}
      }

      // Images (expecting list of URLs)
      final List? imgs = prop['images'] as List?;
      if (imgs != null) {
        for (final img in imgs) {
          if (img == null) continue;
          if (img is String) {
            _remoteImages.add(img);
            continue;
          }

          if (img is Map) {
            final url =
                img['url'] ??
                img['path'] ??
                img['src'] ??
                img['image'] ??
                img['imageUrl'];
            if (url is String && url.isNotEmpty) {
              _remoteImages.add(url);
              continue;
            }
          }

          // fallback to toString()
          final text = img.toString().trim();
          if (text.isNotEmpty) _remoteImages.add(text);
        }
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked);
        if (_images.length > 10) {
          _images.removeRange(10, _images.length);
        }
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null && _images.length < 10) {
      setState(() => _images.add(photo));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Images',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5F4),
                  child: Icon(Icons.photo_library, color: Color(0xFF2F9E9A)),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select multiple images'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5F4),
                  child: Icon(Icons.camera_alt, color: Color(0xFF2F9E9A)),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeRemoteImage(int index) {
    setState(() {
      final removed = _remoteImages.removeAt(index);
      _removedRemoteImages.add(removed);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_images.length + _remoteImages.length) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    if (_availStart == null || _availEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set availability start and end dates'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final client = ref.read(apiClientProvider);

      final formData = FormData();

      formData.fields.addAll([
        MapEntry('title', _titleCtrl.text.trim()),
        MapEntry('description', _descCtrl.text.trim()),
        MapEntry('location', _locationCtrl.text.trim()),
        MapEntry('price', _priceCtrl.text.trim()),
        MapEntry('propertyType', _propertyType),
        MapEntry('petPolicy', _petPolicy),
        MapEntry('furnished', _furnished.toString()),
        MapEntry('parking', _parking.toString()),
      ]);

      if (isValidCoordinates(_pinnedCoordinates)) {
        formData.fields.add(
          MapEntry('coordinates', jsonEncode(_pinnedCoordinates!.toJson())),
        );
      }

      if (_bedroomsCtrl.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('bedrooms', _bedroomsCtrl.text.trim()));
      }
      if (_bathroomsCtrl.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('bathrooms', _bathroomsCtrl.text.trim()));
      }
      if (_areaCtrl.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('area', _areaCtrl.text.trim()));
      }
      if (_floorCtrl.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('floor', _floorCtrl.text.trim()));
      }

      for (final amenity in _amenities) {
        formData.fields.add(MapEntry('amenities', amenity));
      }

      // Availability (required by backend)
      if (_availStart != null && _availEnd != null) {
        final avail = jsonEncode([
          {
            'startDate': _availStart!.toIso8601String(),
            'endDate': _availEnd!.toIso8601String(),
          },
        ]);
        formData.fields.add(MapEntry('availability', avail));
      }

      for (final img in _images) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(img.path, filename: img.name),
          ),
        );
      }

      // Inform backend which existing remote images to keep/remove when editing
      formData.fields.add(
        MapEntry('existingImages', jsonEncode(_remoteImages)),
      );
      formData.fields.add(
        MapEntry('removedImages', jsonEncode(_removedRemoteImages)),
      );

      if (_isEdit) {
        final id =
            widget.propertyId ??
            widget.property?['_id'] ??
            widget.property?['id'];
        if (id == null) throw 'Missing property id for update';
        await client.put(
          ApiEndpoints.propertyById(id.toString()),
          data: formData,
        );
      } else {
        await client.uploadFile(ApiEndpoints.propertyList, formData: formData);
      }

      if (!mounted) return;
      final successMessage = _isEdit
          ? 'Property updated successfully!'
          : 'Property created successfully!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successMessage,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create property: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete property'),
        content: const Text('Are you sure you want to delete this property?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _deleteProperty();
    }
  }

  Future<void> _deleteProperty() async {
    try {
      setState(() => _submitting = true);
      final client = ref.read(apiClientProvider);
      final id =
          widget.propertyId ??
          widget.property?['_id'] ??
          widget.property?['id'];
      if (id == null) throw 'Missing property id for delete';
      await client.delete(ApiEndpoints.propertyById(id.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Property deleted',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2F9E9A), Color(0xFF6CCBC7), Color(0xFFD8F3F2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isEdit ? 'Edit Property' : 'Add New Property',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (_isEdit)
                      IconButton(
                        onPressed: _confirmDelete,
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Form body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Images section
                        _SectionCard(
                          title: 'Property Images',
                          icon: Icons.photo_library_outlined,
                          child: Column(
                            children: [
                              if (_remoteImages.isNotEmpty ||
                                  _images.isNotEmpty)
                                SizedBox(
                                  height: 100,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        _remoteImages.length + _images.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (_, i) {
                                      if (i < _remoteImages.length) {
                                        final url = _remoteImages[i];
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                url,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      width: 100,
                                                      height: 100,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _removeRemoteImage(i),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      final localIndex =
                                          i - _remoteImages.length;
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.file(
                                              File(_images[localIndex].path),
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _removeImage(localIndex),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              if (_images.isNotEmpty)
                                const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed:
                                    (_remoteImages.length + _images.length) >=
                                        10
                                    ? null
                                    : _showImageSourceSheet,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: Text(
                                  (_remoteImages.length + _images.length) == 0
                                      ? 'Add Images (max 10)'
                                      : '${_remoteImages.length + _images.length}/10 — Add More',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2F9E9A),
                                  side: const BorderSide(
                                    color: Color(0xFF2F9E9A),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Basic Info
                        _SectionCard(
                          title: 'Basic Information',
                          icon: Icons.info_outline,
                          child: Column(
                            children: [
                              _FormField(
                                controller: _titleCtrl,
                                label: 'Property Title',
                                hint: 'e.g. Cozy 2BHK near Mall',
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Title is required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _FormField(
                                controller: _descCtrl,
                                label: 'Description',
                                hint: 'Describe your property...',
                                maxLines: 3,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Description is required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _FormField(
                                controller: _locationCtrl,
                                label: 'Location',
                                hint: 'e.g. Baneshwor, Kathmandu',
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Location is required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              LocationPickerCard(
                                locationController: _locationCtrl,
                                coordinates: _pinnedCoordinates,
                                onCoordinatesChanged: (coordinates) {
                                  setState(
                                    () => _pinnedCoordinates = coordinates,
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _FormField(
                                controller: _priceCtrl,
                                label: 'Price (per month)',
                                hint: 'e.g. 15000',
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Price is required';
                                  }
                                  if (double.tryParse(v.trim()) == null) {
                                    return 'Enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Property Details
                        _SectionCard(
                          title: 'Property Details',
                          icon: Icons.house_outlined,
                          child: Column(
                            children: [
                              // Property Type
                              DropdownButtonFormField<String>(
                                value: _propertyType,
                                decoration: _inputDecoration('Property Type'),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'room',
                                    child: Text('Room'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'house',
                                    child: Text('House'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'apartment',
                                    child: Text('Apartment'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'studio',
                                    child: Text('Studio'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'other',
                                    child: Text('Other'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _propertyType = v);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _FormField(
                                      controller: _bedroomsCtrl,
                                      label: 'Bedrooms',
                                      hint: '0',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _FormField(
                                      controller: _bathroomsCtrl,
                                      label: 'Bathrooms',
                                      hint: '0',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _FormField(
                                      controller: _areaCtrl,
                                      label: 'Area (sqft)',
                                      hint: 'e.g. 800',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _FormField(
                                      controller: _floorCtrl,
                                      label: 'Floor',
                                      hint: 'e.g. 2',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Pet Policy
                              DropdownButtonFormField<String>(
                                value: _petPolicy,
                                decoration: _inputDecoration('Pet Policy'),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'allowed',
                                    child: Text('Allowed'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'not-allowed',
                                    child: Text('Not Allowed'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'on-request',
                                    child: Text('On Request'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _petPolicy = v);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              // Toggles
                              Row(
                                children: [
                                  Expanded(
                                    child: SwitchListTile(
                                      title: const Text(
                                        'Furnished',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      value: _furnished,
                                      activeColor: const Color(0xFF2F9E9A),
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (v) =>
                                          setState(() => _furnished = v),
                                    ),
                                  ),
                                  Expanded(
                                    child: SwitchListTile(
                                      title: const Text(
                                        'Parking',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      value: _parking,
                                      activeColor: const Color(0xFF2F9E9A),
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (v) =>
                                          setState(() => _parking = v),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Availability
                        _SectionCard(
                          title: 'Availability',
                          icon: Icons.calendar_month_outlined,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _DatePickerField(
                                      label: 'Start Date',
                                      date: _availStart,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _availStart ?? DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 730),
                                          ),
                                        );
                                        if (picked != null) {
                                          setState(() => _availStart = picked);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _DatePickerField(
                                      label: 'End Date',
                                      date: _availEnd,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _availEnd ??
                                              (_availStart ?? DateTime.now())
                                                  .add(
                                                    const Duration(days: 30),
                                                  ),
                                          firstDate:
                                              _availStart ?? DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 730),
                                          ),
                                        );
                                        if (picked != null) {
                                          setState(() => _availEnd = picked);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Amenities
                        _SectionCard(
                          title: 'Amenities',
                          icon: Icons.checklist_outlined,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _amenityOptions.map((a) {
                              final selected = _amenities.contains(a);
                              return FilterChip(
                                label: Text(a),
                                selected: selected,
                                selectedColor: const Color(
                                  0xFF2F9E9A,
                                ).withOpacity(0.2),
                                checkmarkColor: const Color(0xFF2F9E9A),
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      _amenities.add(a);
                                    } else {
                                      _amenities.remove(a);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F9E9A),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(
                                0xFF2F9E9A,
                              ).withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Create Property',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2F9E9A), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ──────────── Helper Widgets ────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2F9E9A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2F9E9A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          suffixIcon: const Icon(
            Icons.calendar_today,
            size: 18,
            color: Color(0xFF2F9E9A),
          ),
        ),
        child: Text(
          date != null
              ? DateFormat('MMM dd, yyyy').format(date!)
              : 'Select date',
          style: TextStyle(
            color: date != null ? Colors.black87 : Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
