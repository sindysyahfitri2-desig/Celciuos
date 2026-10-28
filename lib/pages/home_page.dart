import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.selectedOrderType,
    required this.onOrderTypeSelected,
    required this.onContinue,
  });

  final String? selectedOrderType;
  final ValueChanged<String> onOrderTypeSelected;
  final VoidCallback onContinue;

  static const Color _navy = Color(0xff082640);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: width < 600 ? (width - 40).clamp(0.0, 455.0) : 455,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (width < 500)
                        Column(
                          children: [
                            _orderTypeCard(
                              title: 'Take\nAway',
                              value: 'Take Away',
                            ),
                            const SizedBox(height: 15),
                            _orderTypeCard(title: 'Dine In', value: 'Dine In'),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _orderTypeCard(
                                title: 'Take\nAway',
                                value: 'Take Away',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _orderTypeCard(
                                title: 'Dine In',
                                value: 'Dine In',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 160,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: selectedOrderType == null ? null : onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Lanjut',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orderTypeCard({required String title, required String value}) {
    final isSelected = selectedOrderType == value;

    return GestureDetector(
      onTap: () => onOrderTypeSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffa8cbe9) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _navy : const Color(0xffc8d2da),
              width: 3.2,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 7,
                left: 7,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _navy, width: 1.2),
                    color: isSelected ? _navy : Colors.white,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
