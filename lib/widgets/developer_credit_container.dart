import 'package:cbtapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

Widget buildCreditCard({required BuildContext context}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
    decoration: BoxDecoration(
      // gradient: LinearGradient(
      //   begin: Alignment.topLeft,
      //   end: Alignment.bottomRight,
      //   colors: [
      //     AppColors.darkPrimary,
      //     AppColors.darkPrimary.withAlpha(204), // 0.8 opacity
      //     const Color(0xFF8B5CF6), // Purple accent
      //   ],
      // ),
      borderRadius: BorderRadius.circular(12),
      // boxShadow: [
      //   BoxShadow(
      //     color: AppColors.darkPrimary.withAlpha(76), // 0.3 opacity
      //     blurRadius: 20,
      //     offset: const Offset(0, 8),
      //     spreadRadius: 0,
      //   ),
      //   BoxShadow(
      //     color: Colors.black.withAlpha(51), // 0.2 opacity
      //     blurRadius: 30,
      //     offset: const Offset(0, 10),
      //     spreadRadius: -5,
      //   ),
      // ],
      border: Border.all(
        color: AppColors.darkPrimary.withAlpha(77), // 0.3 opacity
        width: 0.2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const SizedBox(height: 16),

        // Developer name with highlight
        Row(
          children: [
            const Icon(Icons.code, color: AppColors.darkPrimary, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Developed with ❤️ by TOE Tech",
                style: TextStyle(color: AppColors.darkPrimary, fontSize: 10),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Main developer info
        Column(
          children: [
            // Name with badge
            // Row(
            //   children: [
            //     Container(
            //       padding: const EdgeInsets.all(6),
            //       decoration: BoxDecoration(
            //         color: AppColors.darkPrimary.withAlpha(26), // 0.1 opacity
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       child: Icon(
            //         Icons.person,
            //         color: AppColors.darkPrimary,
            //         size: 16,
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     const Expanded(
            //       child: Text(
            //         "TOE Tech",
            //         style: TextStyle(
            //           fontSize: 8,
            //           fontWeight: FontWeight.bold,
            //           color: AppColors.surface,
            //         ),
            //       ),
            //     ),
            //     Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 8,
            //         vertical: 4,
            //       ),
            //       decoration: BoxDecoration(
            //         color: AppColors.success.withAlpha(26), // 0.1 opacity
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Icon(
            //             Icons.verified,
            //             color: AppColors.success,
            //             size: 12,
            //           ),
            //           const SizedBox(width: 4),
            //           Text(
            //             "Developer",
            //             style: TextStyle(
            //               color: AppColors.success,
            //               fontSize: 10,
            //               fontWeight: FontWeight.w600,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 16),

            // Contact info with copy buttons
            _buildContactItem(
              context: context,
              icon: Icons.phone,
              label: "+234 810 7722 690",
              value: "08107722690",
            ),

            const SizedBox(height: 12),

            _buildContactItem(
              context: context,
              icon: Icons.email,
              label: "contact.toetech@gmail.com",
              value: "contact.toetech@gmail.com",
            ),

            const SizedBox(height: 16),

            // Hire me button
            // Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(12),
            //     gradient: LinearGradient(
            //       colors: [AppColors.darkPrimary, const Color(0xFF8B5CF6)],
            //     ),
            //   ),
            //   child: ElevatedButton(
            //     onPressed: () {
            //       // You can add functionality here
            //       // For example, open email client or copy all info
            //       _showDeveloperContactDialog(context);
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.transparent,
            //       foregroundColor: Colors.white,
            //       elevation: 0,
            //       padding: const EdgeInsets.symmetric(vertical: 12),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //     child: const Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         Icon(Icons.star, size: 16),
            //         SizedBox(width: 8),
            //         Text(
            //           "Hire Me",
            //           style: TextStyle(fontWeight: FontWeight.bold),
            //         ),
            //         SizedBox(width: 8),
            //         Icon(Icons.arrow_forward, size: 16),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),

        // const SizedBox(height: 8),

        // // Footer note
        // Center(
        //   child: Text(
        //     "Let's build something amazing together! 🚀",
        //     style: TextStyle(
        //       color: AppColors.darkPrimary.withAlpha(204), // 0.8 opacity
        //       fontSize: 10,
        //       fontStyle: FontStyle.italic,
        //     ),
        //   ),
        // ),
      ],
    ),
  );
}

Widget _buildContactItem({
  required IconData icon,
  required String label,
  required String value,
  required BuildContext context,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.darkPrimary.withAlpha(26), // 0.1 opacity
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.darkPrimary, size: 12),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          // overflow: TextOverflow.ellipsis,
        ),
      ),
      // IconButton(
      //   icon: Icon(Icons.copy, color: AppColors.darkPrimary, size: 18),
      //   onPressed: () {
      //     Clipboard.setData(ClipboardData(text: value));
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         content: Text("Copied to clipboard!"),
      //         backgroundColor: AppColors.success,
      //         duration: const Duration(seconds: 1),
      //         behavior: SnackBarBehavior.floating,
      //       ),
      //     );
      //   },
      //   padding: EdgeInsets.zero,
      //   constraints: const BoxConstraints(),
      // ),
    ],
  );
}

void _showDeveloperContactDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(Icons.contact_mail, color: AppColors.darkPrimary),
          const SizedBox(width: 8),
          const Text(
            "Contact Developer",
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkPrimary.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  "TOE Tech",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Full Stack Developer",
                  style: TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDialogContactItem(
            icon: Icons.phone,
            label: "Phone",
            value: "08107722690",
          ),
          const SizedBox(height: 8),
          _buildDialogContactItem(
            icon: Icons.email,
            label: "Email",
            value: "contact.toetech@gmail.com",
          ),
          const SizedBox(height: 8),
          _buildDialogContactItem(
            icon: Icons.code,
            label: "Services",
            value: "Flutter • UI/UX • Desktop Apps",
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text("CLOSE", style: TextStyle(color: AppColors.darkPrimary)),
        ),
      ],
    ),
  );
}

Widget _buildDialogContactItem({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.darkPrimary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
