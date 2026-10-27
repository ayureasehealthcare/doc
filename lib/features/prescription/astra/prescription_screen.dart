import 'package:flutter/material.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/content_origin_badge.dart';
import 'package:doctro/widgets/osler_button.dart';
import 'package:doctro/widgets/osler_card.dart';
import 'package:doctro/widgets/osler_dropdown.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/widgets/astra_fill_display.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;

class PrescriptionScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String? patientPhone;
  final String? doctorId;
  final Map<String, dynamic>? astraFillData;

  const PrescriptionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.patientPhone,
    this.doctorId,
    this.astraFillData,
  });

  @override
  _PrescriptionScreenState createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen>
    with SingleTickerProviderStateMixin {
  final _diagnosisController = TextEditingController();
  final AstraApiService _astraApiService = AstraApiService();

  final List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = false;
  Map<String, dynamic>? _patientData;
  Uint8List? _signatureBytes;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    if (widget.astraFillData != null && widget.astraFillData!.isNotEmpty) {
      _patientData = {'latest_astra_fill': widget.astraFillData};
      _processAstraFillData(widget.astraFillData!);
    } else {
      _loadPatientData();
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// The diagnosis text Astra pre-filled from the patient's intake, so the
  /// field can say whether it still shows Astra's draft or the doctor's own
  /// words.
  String? _astraDiagnosisDraft;

  void _processAstraFillData(Map<String, dynamic> astraFill) {
    if (astraFill['extracted_symptoms'] != null) {
      dynamic symptoms = astraFill['extracted_symptoms'];
      if (symptoms != null) {
        String symptomsText =
            (symptoms is List) ? symptoms.join(', ') : symptoms.toString();
        _diagnosisController.text =
            "Possible condition related to: $symptomsText";
        _astraDiagnosisDraft = _diagnosisController.text;
      }
    }
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _astraApiService.getPatientProfile(widget.patientId);
      if (!mounted) return;
      setState(() {
        _patientData = data;
        var latestFill = data['latest_astra_fill'];
        if (latestFill != null &&
            latestFill is Map<String, dynamic> &&
            latestFill.isNotEmpty) {
          _processAstraFillData(latestFill);
        } else {
          if (_patientData != null) _patientData!['latest_astra_fill'] = null;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load patient AI view")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addMedicine(Map<String, dynamic> medicine) {
    final List variants =
        (medicine['variants'] is List) ? medicine['variants'] : [];
    final Map<String, dynamic>? firstVariant =
        variants.isNotEmpty && variants.first is Map<String, dynamic>
            ? variants.first as Map<String, dynamic>
            : null;

    final dynamic variantId = medicine['shopify_variant_id'] ??
        medicine['variant_id'] ??
        medicine['id'] ??
        firstVariant?['id'];

    final dynamic variantPrice = medicine['price'] ?? firstVariant?['price'];

    setState(() {
      _medicines.add({
        "medicine_name": medicine['medicine_name'] ?? medicine['title'],
        "shopify_variant_id": variantId,
        "price": variantPrice,
        "dosage": "1 tablet",
        "frequency": "twice_daily",
        "timing": "After Food",
        "duration_days": 5,
        "quantity": 1,
        "instructions": "",
      });
    });
  }

  void _updateMedicineQuantity(int index, int quantity) {
    setState(() {
      _medicines[index]['quantity'] = quantity;
    });
  }

  Future<void> _editMedicineDetails(int index) async {
    final med = _medicines[index];
    final TextEditingController dosageController =
        TextEditingController(text: (med['dosage'] ?? '1 tablet').toString());
    final TextEditingController durationController =
        TextEditingController(text: (med['duration_days'] ?? 5).toString());
    String frequency = (med['frequency'] ?? 'twice_daily').toString();
    final textTheme = Theme.of(context).textTheme;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AyurezeTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl)),
          title: Text(
            "Edit Dosage",
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AyurezeTheme.textPrimary,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dosageController,
                    decoration: InputDecoration(
                      labelText: "Dosage (e.g. 1 tablet)",
                      labelStyle: textTheme.bodyMedium
                          ?.copyWith(color: AyurezeTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OslerDropdown(
                    label: '',
                    hint: "Select frequency",
                    value: frequency,
                    items: const ['Once daily', 'Twice daily', 'Thrice daily'],
                    onChanged: (v) {
                      if (v != null) {
                        setLocalState(() => frequency = v);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Duration (days)",
                      labelStyle: textTheme.bodyMedium
                          ?.copyWith(color: AyurezeTheme.textSecondary),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: textTheme.labelLarge
                      ?.copyWith(color: AyurezeTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final int parsedDays =
                    int.tryParse(durationController.text.trim()) ?? 5;
                setState(() {
                  _medicines[index]['dosage'] =
                      dosageController.text.trim().isEmpty
                          ? '1 tablet'
                          : dosageController.text.trim();
                  _medicines[index]['frequency'] = frequency;
                  _medicines[index]['duration_days'] =
                      parsedDays < 1 ? 1 : parsedDays;
                });
                Navigator.pop(context);
              },
              child: Text("Save",
                  style: textTheme.labelLarge?.copyWith(
                      color: AyurezeTheme.textPrimary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitPrescription() async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add at least one medicine")));
      return;
    }

    if (_signatureBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please provide your signature")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final String doctorId =
          (widget.doctorId != null && widget.doctorId!.isNotEmpty)
              ? widget.doctorId!
              : SharedPreferenceHelper.getString(Preferences.doctorId);
      if (doctorId.isEmpty || doctorId == 'N_A') {
        throw Exception("Doctor ID missing. Please re-login once.");
      }

      bool allHaveShopify = _medicines.every((m) =>
          m['shopify_variant_id'] != null &&
          m['shopify_variant_id'].toString().isNotEmpty);

      final payload = {
        "doctor_id": doctorId,
        "patient_id": widget.patientId,
        "patient_name": widget.patientName,
        "patient_phone": widget.patientPhone,
        "diagnosis": _diagnosisController.text,
        "medicines": _medicines,
        "lifestyle_advice": "Rest and hydration",
        "auto_process": true,
        "create_shopify_cart": allHaveShopify,
        "signature_image": base64Encode(_signatureBytes!),
      };

      await _astraApiService.executePrescriptionWorkflow(payload);

      if (!mounted) return;

      String msg = "Prescription Sent via WhatsApp!";
      if (allHaveShopify) {
        msg += " & Shopify Cart Created!";
      } else {
        msg += "\n(Note: Some items were not in stock, Shopify cart skipped)";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: allHaveShopify
            ? AyurezeTheme.healingGreen100
            : AyurezeTheme.sunshineYellow50,
        duration: const Duration(seconds: 4),
      ));

      Navigator.pop(context);
    } catch (e) {
      final String err = e.toString();
      String message = err
          .replaceFirst('Exception: ', '')
          .replaceFirst('AstraApiException: ', '')
          .trim();
      if (message.isEmpty) {
        message = "Submission failed. Please try again.";
      }
      if (err.contains("Doctor ID missing")) {
        message = "Doctor session missing. Please login again.";
      } else if (err.contains("unreachable") ||
          err.contains("Network error") ||
          err.contains("connection") ||
          err.contains("timeout")) {
        message = "Astra server unreachable. Check internet/VPN and retry.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AyurezeTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AyurezeTheme.radius2xl)),
      ),
      builder: (context) => SearchMedicineSheet(
        onSelect: (medicine) {
          _addMedicine(medicine);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AyurezeTheme.canvas,
      appBar: AppBar(
        // Patient name on its own line: "Prescription for <name>" was
        // truncated mid-name on phones.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Prescription",
              style: textTheme.titleLarge
                  ?.copyWith(color: AyurezeTheme.textPrimary),
            ),
            Text(
              widget.patientName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AyurezeTheme.textSecondary),
            ),
          ],
        ),
        backgroundColor: AyurezeTheme.canvas,
        leading: IconButton(
          icon: HugeIcon(
              icon: AppIcons.back, color: AyurezeTheme.iconPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoading && _patientData == null
          ? Center(
              child: CircularProgressIndicator(color: AyurezeTheme.iconPrimary))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: AyurezeTheme.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_patientData != null &&
                            _patientData!['latest_astra_fill'] != null)
                          AstraFillCompactWidget(
                              astraFillData:
                                  _patientData!['latest_astra_fill']),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _diagnosisController,
                          decoration: InputDecoration(
                            labelText: "Diagnosis",
                            hintText: "Enter clinical diagnosis",
                            suffixIcon: HugeIcon(
                                icon: HugeIcons.strokeRoundedStethoscope02,
                                size: 22,
                                color: AyurezeTheme.iconPrimary),
                          ),
                        ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _diagnosisController,
                          builder: (context, value, _) {
                            final origin = ContentOrigin.forDraft(value.text,
                                astraDraft: _astraDiagnosisDraft);
                            if (origin == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(
                                  top: AyurezeTheme.spaceSm),
                              child: Row(
                                children: [
                                  ContentOriginBadge(origin: origin),
                                  if (origin ==
                                      ContentOrigin.astraSuggestion) ...[
                                    const SizedBox(width: AyurezeTheme.spaceSm),
                                    Expanded(
                                      child: Text(
                                        "Drafted from the patient's intake. "
                                        "Review before prescribing.",
                                        style: textTheme.bodySmall?.copyWith(
                                            color: AyurezeTheme.textSecondary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Medicines",
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AyurezeTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._medicines.asMap().entries.map((entry) {
                          int idx = entry.key;
                          Map med = entry.value;
                          bool noShopify = med['shopify_variant_id'] == null;

                          return OslerCard(
                            margin: const EdgeInsets.only(
                                bottom: AyurezeTheme.spaceMd),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AyurezeTheme.spaceSm),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: noShopify
                                      ? AyurezeTheme.sunshineYellow50
                                      : AyurezeTheme.healingGreen100,
                                  child: Text(
                                    "${idx + 1}",
                                    style: textTheme.labelLarge
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        med['medicine_name'] ?? 'Unknown',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AyurezeTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (noShopify)
                                      Tooltip(
                                        message: "Not available for Auto-Cart",
                                        child: HugeIcon(
                                            icon:
                                                HugeIcons.strokeRoundedAlert01,
                                            color:
                                                AyurezeTheme.sunshineYellow50,
                                            size: 20),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${med['dosage']} | ${med['frequency']} | ${med['duration_days']} days",
                                      style: textTheme.bodySmall?.copyWith(
                                          color: AyurezeTheme.textSecondary),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: HugeIcon(
                                              icon:
                                                  HugeIcons.strokeRoundedEdit02,
                                              size: 18,
                                              color: AyurezeTheme.iconPrimary),
                                          tooltip: "Edit dosage",
                                          onPressed: () =>
                                              _editMedicineDetails(idx),
                                        ),
                                        Text(
                                          "Qty: ",
                                          style: textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AyurezeTheme.textPrimary,
                                          ),
                                        ),
                                        DropdownButton<int>(
                                          value: med['quantity'],
                                          dropdownColor: AyurezeTheme.surface,
                                          items: [1, 2, 3, 5, 10, 20, 30]
                                              .map((int value) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(
                                                value.toString(),
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: AyurezeTheme
                                                            .textPrimary),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) =>
                                              _updateMedicineQuantity(
                                                  idx, val!),
                                        ),
                                        const Spacer(),
                                        if (med['price'] != null)
                                          Text(
                                            "₹ ${med['price']}",
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              color: AyurezeTheme.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: HugeIcon(
                                      icon: AppIcons.delete,
                                      color: AyurezeTheme.remoteRed50),
                                  onPressed: () =>
                                      setState(() => _medicines.removeAt(idx)),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showSearchSheet,
                          icon: HugeIcon(icon: AppIcons.add, size: 18),
                          label: const Text("Add Medicine"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            // Dark-aware: healingGreen10 is light-only, so this
                            // button stayed pale with dark text in dark mode.
                            backgroundColor: AyurezeTheme.surfaceMuted,
                            foregroundColor: AyurezeTheme.textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AyurezeTheme.radiusLg),
                              side: BorderSide(
                                  color: AyurezeTheme.healingGreen50
                                      .withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "Doctor Digital Signature",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AyurezeTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: AyurezeTheme.panelDecoration(),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AyurezeTheme.radius2xl),
                            child: DoctorSignaturePad(
                              onChanged: (bytes) {
                                setState(() {
                                  _signatureBytes = bytes;
                                });
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _signatureBytes = null),
                            icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                size: 16,
                                color: AyurezeTheme.textSecondary),
                            label: Text(
                              "Clear Signature",
                              style: textTheme.bodySmall
                                  ?.copyWith(color: AyurezeTheme.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        OslerButton(
                          text: "Submit & Automate (PDF + WhatsApp)",
                          isLoading: _isLoading,
                          onPressed: _submitPrescription,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class SearchMedicineSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelect;
  const SearchMedicineSheet({super.key, required this.onSelect});

  @override
  _SearchMedicineSheetState createState() => _SearchMedicineSheetState();
}

class _SearchMedicineSheetState extends State<SearchMedicineSheet> {
  final _searchController = TextEditingController();
  final AstraApiService _astraApiService = AstraApiService();
  List _results = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAvailableMedicines();
  }

  Future<void> _loadAvailableMedicines() async {
    setState(() => _isLoading = true);
    try {
      List results = await _astraApiService.getAvailableMedicines();
      if (results.isEmpty) {
        final all = await _astraApiService.getAllShopifyProducts();
        if (all['success'] == true && all['products'] is List) {
          results = List.from(all['products']);
        }
      }
      if (mounted) {
        setState(() => _results = results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load medicines")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncShopify() async {
    setState(() => _isSyncing = true);
    try {
      await _astraApiService.syncShopifyProducts();
      await _loadAvailableMedicines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Shopify Sync Complete")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Sync failed")));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        _loadAvailableMedicines();
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await _astraApiService.searchMedicineProducts(query);
      if (mounted) {
        setState(() => _results = results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Search failed")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(AyurezeTheme.spaceLg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Search Medicines",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AyurezeTheme.textPrimary,
                ),
              ),
              if (_isSyncing)
                SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AyurezeTheme.iconPrimary))
              else
                TextButton.icon(
                  onPressed: _syncShopify,
                  icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedReload,
                      size: 16,
                      color: AyurezeTheme.iconPrimary),
                  label: Text("Sync Shopify",
                      style: textTheme.labelLarge
                          ?.copyWith(color: AyurezeTheme.textPrimary)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Type medicine name",
              prefixIcon: HugeIcon(
                  icon: AppIcons.search, color: AyurezeTheme.iconPrimary),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: AyurezeTheme.iconPrimary))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        title: Text(
                          item['medicine_name'] ?? item['title'] ?? 'Unknown',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AyurezeTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          "₹ ${item['price'] ?? '0'}",
                          style: textTheme.bodySmall
                              ?.copyWith(color: AyurezeTheme.textSecondary),
                        ),
                        trailing: HugeIcon(
                            icon: HugeIcons.strokeRoundedAddCircle,
                            color: AyurezeTheme.healingGreen50),
                        onTap: () => widget.onSelect(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DoctorSignaturePad extends StatefulWidget {
  final Function(Uint8List) onChanged;
  const DoctorSignaturePad({super.key, required this.onChanged});

  @override
  _DoctorSignaturePadState createState() => _DoctorSignaturePadState();
}

class _DoctorSignaturePadState extends State<DoctorSignaturePad> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          _points.add(renderBox.globalToLocal(details.globalPosition));
        });
      },
      onPanEnd: (details) async {
        _points.add(null);
        final bytes = await _captureSignature();
        if (bytes != null) {
          widget.onChanged(bytes);
        }
      },
      child: CustomPaint(
        painter: SignaturePainter(points: List.from(_points)),
        size: Size.infinite,
      ),
    );
  }

  Future<Uint8List?> _captureSignature() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 500, 200));

      final paint = Paint()
        ..color = AyurezeTheme.lightTextPrimary
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(500, 200);
      final ByteData? byteData =
          await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AyurezeTheme.iconPrimary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
