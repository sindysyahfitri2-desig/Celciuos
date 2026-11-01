import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kasir_celcious_coffe/features/owner/application/staff_directory_controller.dart';

class KontrolStafPage extends StatefulWidget {
  const KontrolStafPage({super.key});

  @override
  State<KontrolStafPage> createState() => _KontrolStafPageState();
}

class _KontrolStafPageState extends State<KontrolStafPage> {
  final StaffDirectoryController _directory = StaffDirectoryController();

  List<Staff> get staffList => _directory.staff;

  Future<void> editStaff(int index) async {
    final controller =
        TextEditingController(text: staffList[index].name);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Staf"),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                controller.text.trim(),
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      _directory.rename(index, result);
    }
  }

  @override
  void initState() {
    super.initState();
    _directory.addListener(_onDirectoryChanged);
  }

  @override
  void dispose() {
    _directory
      ..removeListener(_onDirectoryChanged)
      ..dispose();
    super.dispose();
  }

  void _onDirectoryChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _directory.filteredStaff;

    return Scaffold(
      backgroundColor: const Color(0xffdce7f2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            int columns = 2;

            if (constraints.maxWidth > 1200) {
              columns = 5;
            } else if (constraints.maxWidth > 800) {
              columns = 4;
            } else if (constraints.maxWidth > 600) {
              columns = 3;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  constraints.maxWidth < 600
                      ? Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Kontrol Staf",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight:
                                      FontWeight.w900,
                                  color:
                                      Color(0xff0E2F56),
                                ),
                              ),
                            ),
                            const SizedBox(
                                height: 12),
                            TextField(
                              onChanged: (v) {
                                _directory.setSearchQuery(v);
                              },
                              decoration:
                                  InputDecoration(
                                hintText: "Cari",
                                filled: true,
                                fillColor:
                                    Colors.white,
                                prefixIcon:
                                    const Icon(
                                  Icons.search,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              25),
                                  borderSide:
                                      BorderSide
                                          .none,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Text(
                              "Kontrol Staf",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight:
                                    FontWeight.w900,
                                color:
                                    Color(0xff0E2F56),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 280,
                              child: TextField(
                                onChanged: (v) {
                                  _directory.setSearchQuery(v);
                                },
                                decoration:
                                    InputDecoration(
                                  hintText: "Cari",
                                  filled: true,
                                  fillColor:
                                      Colors.white,
                                  prefixIcon:
                                      const Icon(
                                    Icons.search,
                                  ),
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                25),
                                    borderSide:
                                        BorderSide
                                            .none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: 25),

                  AddStaffCard(
                    onSave: _directory.add,
                  ),

                  const SizedBox(height: 25),

                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final staff = filtered[index];

                      return Container(
                        padding:
                            const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                                  16),
                          boxShadow: const [
                            BoxShadow(
                              color:
                                  Colors.black12,
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width:
                                    double.infinity,
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .grey.shade300,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              14),
                                ),
                                child: staff
                                            .photoPath ==
                                        null
                                    ? const Icon(
                                        Icons
                                            .person,
                                        size: 60,
                                      )
                                    : ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(
                                                14),
                                        child:
                                            Image.file(
                                          File(staff
                                              .photoPath!),
                                          fit: BoxFit
                                              .cover,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(
                                height: 10),
                            Text(
                              staff.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                            const SizedBox(
                                height: 8),
                            SizedBox(
                              width: 80,
                              height: 30,
                              child:
                                  ElevatedButton(
                                onPressed: () =>
                                    editStaff(
                                        index),
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      const Color(
                                          0xff0E2F56),
                                  foregroundColor:
                                      Colors.white,
                                ),
                                child: const Text(
                                  "Edit",
                                  style:
                                      TextStyle(
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddStaffCard extends StatefulWidget {
  final ValueChanged<Staff> onSave;

  const AddStaffCard({
    super.key,
    required this.onSave,
  });

  @override
  State<AddStaffCard> createState() =>
      _AddStaffCardState();
}

class _AddStaffCardState
    extends State<AddStaffCard> {
  final controller = TextEditingController();

  String? photoPath;

  Future<void> pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        photoPath = image.path;
      });
    }
  }

  void save() {
    if (controller.text.trim().isEmpty) {
      return;
    }

    widget.onSave(
      Staff(
        name: controller.text.trim(),
        photoPath: photoPath,
      ),
    );

    controller.clear();

    setState(() {
      photoPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color:
                    const Color(0xffD3CFE6),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: photoPath == null
                  ? const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 35,
                    )
                  : ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                              12),
                      child: Image.file(
                        File(photoPath!),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              decoration:
                  const InputDecoration(
                hintText: "Nama Staf",
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: save,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xff0E2F56),
              foregroundColor:
                  Colors.white,
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}
