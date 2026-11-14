import 'package:flutter/material.dart';

class EmergencyReferencePage extends StatelessWidget {
  const EmergencyReferencePage({super.key});

  static const Color _cyan = Color(0xFF55DFFF);
  static const Color _red = Color(0xFFFF626D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06111D),
      appBar: AppBar(
        title: const Text('EMERGENCY REFERENCE'),
        backgroundColor: const Color(0xFF091A2A),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(.12),
                          border: Border.all(color: _red.withOpacity(.6)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: _red, size: 28),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'FOLLOW THE APPROVED MISSION EMERGENCY CHECKLIST',
                                    style: TextStyle(color: _red, fontWeight: FontWeight.w900, letterSpacing: .7),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              'This screen is a navigation aid only. It is not a diagnostic tool, treatment protocol, or substitute for the spacecraft medical kit, onboard procedures, commander, or flight surgeon.',
                              style: TextStyle(height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('WHEN TO ESCALATE IMMEDIATELY',
                        style: TextStyle(color: _cyan, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      _item('Severe or rapidly worsening breathing difficulty, chest discomfort, fainting, seizure, sudden confusion, or new weakness, speech, or vision problems.'),
                      _item('Major injury, uncontrolled bleeding, severe burn, suspected fracture with loss of function, or serious allergic reaction.'),
                      _item('Any symptom or measurement that meets the mission-specific emergency threshold, or any situation where the crew member feels unsafe.'),
                      const SizedBox(height: 16),
                      const Text('CREW RESPONSE FLOW',
                        style: TextStyle(color: _cyan, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      _step('01', 'Stop the current task if safe to do so and alert the commander or designated medical officer.'),
                      _step('02', 'Use the mission-approved emergency checklist and medical equipment instructions. Do not improvise treatment from this app.'),
                      _step('03', 'Record the time, symptoms, relevant measurements, device or source, and actions already taken.'),
                      _step('04', 'Contact the flight surgeon or ground medical team using the mission communication procedure. Follow their direction.'),
                      _step('05', 'Keep monitoring and document changes according to the approved procedure.'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFF102638), borderRadius: BorderRadius.circular(12)),
                        child: const Text(
                          'DESIGN NOTE: Emergency thresholds, medication instructions, and treatment algorithms must be supplied and validated by the responsible aerospace medical authority for the specific mission. They are intentionally not invented in this prototype.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _item(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.priority_high, color: _red, size: 18),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    ),
  );

  static Widget _step(String number, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: _cyan.withOpacity(.16),
          child: Text(number, style: const TextStyle(color: _cyan, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    ),
  );
}
