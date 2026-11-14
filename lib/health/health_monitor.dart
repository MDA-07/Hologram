import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bg = Color(0xFF06111D);
const _panelColor = Color(0xFF102638);
const _cyan = Color(0xFF55DFFF);

class _HealthRecord {
  final String id, metric, unit, source, timestamp, note;
  final double value;
  const _HealthRecord({required this.id, required this.metric, required this.unit,
    required this.source, required this.timestamp, required this.note, required this.value});
  Map<String, Object?> toJson() => {'id':id,'metric':metric,'unit':unit,'source':source,
    'timestamp':timestamp,'note':note,'value':value};
  factory _HealthRecord.fromJson(Map<String, dynamic> j) => _HealthRecord(
    id: j['id'] as String, metric: j['metric'] as String, unit: j['unit'] as String,
    source: j['source'] as String, timestamp: j['timestamp'] as String,
    note: (j['note'] ?? '') as String, value: (j['value'] as num).toDouble());
}

/// Offline-first, crew-entered log. Values are stored locally and are not diagnoses.
class HealthMonitorPage extends StatefulWidget {
  const HealthMonitorPage({super.key});
  @override State<HealthMonitorPage> createState() => _HealthMonitorPageState();
}
class _HealthMonitorPageState extends State<HealthMonitorPage> {
  static const _storageKey = 'holo_anatomy_health_records_v1';
  static const _metrics = <String, String>{
    'Heart rate':'bpm', 'Blood pressure (systolic)':'mmHg',
    'Blood pressure (diastolic)':'mmHg', 'Blood glucose':'mg/dL',
    'Body temperature':'°C', 'Oxygen saturation':'%', 'Breathing rate':'/min',
    'Sleep duration':'hours', 'Mood':'1–5 self-rating',
    'Pain':'0–10 self-rating', 'Hydration note':'mL (self-reported)',
    'Exercise duration':'minutes', 'Food intake note':'kcal (if measured)',
    'Body mass':'kg', 'Cabin CO₂':'ppm', 'Radiation dose (dosimeter)':'mSv',
  };
  final _value = TextEditingController();
  final _note = TextEditingController();
  String _metric = 'Heart rate';
  String _source = 'Manual entry';
  List<_HealthRecord> _records = [];
  bool _loading = true;
  String? _saveMessage;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _value.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _records = list.map(_HealthRecord.fromJson).toList()
          ..sort((a,b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (_) {
      _saveMessage = 'Stored records could not be read. Existing data was not overwritten.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_value.text.trim().replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite) {
      setState(() => _saveMessage = 'Enter a valid numeric value.');
      return;
    }
    final record = _HealthRecord(id: DateTime.now().microsecondsSinceEpoch.toString(),
      metric: _metric, unit: _metrics[_metric]!, source: _source,
      timestamp: DateTime.now().toUtc().toIso8601String(), note: _note.text.trim(), value: parsed);
    final updated = [record, ..._records];
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = await prefs.setString(_storageKey, jsonEncode(updated.map((r)=>r.toJson()).toList()));
      if (!ok) throw StateError('Local save failed');
      if (!mounted) return;
      setState(() { _records = updated; _saveMessage = 'Saved on this tablet. No network connection required.'; });
      _value.clear(); _note.clear();
    } catch (_) {
      if (mounted) setState(() => _saveMessage = 'Could not save locally. Check available device storage.');
    }
  }

  Future<void> _delete(_HealthRecord record) async {
    final updated = _records.where((r)=>r.id != record.id).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(updated.map((r)=>r.toJson()).toList()));
      if (mounted) setState(()=>_records=updated);
    } catch (_) {
      if (mounted) setState(()=>_saveMessage='Could not update local storage.');
    }
  }

  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color:_panelColor,
    borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF25465B))), child: child);

  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor:_bg, appBar:AppBar(title:const Text('CREW HEALTH LOG'),
      backgroundColor:const Color(0xFF091A2A), actions:[Padding(padding:const EdgeInsets.only(right:16),
      child:Center(child:Text('OFFLINE • LOCAL STORAGE',style:TextStyle(color:_cyan,fontSize:11,fontWeight:FontWeight.bold))))]),
      body:SafeArea(child:_loading ? const Center(child:CircularProgressIndicator()) :
      LayoutBuilder(builder:(context,c) {
        final wide=c.maxWidth>=850;
        final form= _panel(Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          const Text('RECORD A MEASUREMENT',style:TextStyle(color:_cyan,fontWeight:FontWeight.bold,letterSpacing:1.1)),
          const SizedBox(height:14),
          DropdownButtonFormField<String>(value:_metric, isExpanded:true, decoration:const InputDecoration(labelText:'Health indicator'),
            items:_metrics.keys.map((k)=>DropdownMenuItem(value:k,child:Text(k))).toList(),
            onChanged:(v)=>setState(()=>_metric=v??_metric)),
          const SizedBox(height:10),
          TextField(controller:_value, keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),
            decoration:InputDecoration(labelText:'Measured value',suffixText:_metrics[_metric],helperText:'Enter a value from an actual measurement; do not guess.')),
          const SizedBox(height:10),
          DropdownButtonFormField<String>(value:_source, decoration:const InputDecoration(labelText:'Data source'),
            items:const ['Manual entry','External device (manual transcription)','Training / simulation'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
            onChanged:(v)=>setState(()=>_source=v??_source)),
          const SizedBox(height:10),
          TextField(controller:_note,maxLines:2,decoration:const InputDecoration(labelText:'Context / notes (optional)',hintText:'Device, posture, time after exercise, symptoms…')),
          const SizedBox(height:14),
          SizedBox(width:double.infinity,height:52,child:FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('SAVE MEASUREMENT'))),
          if (_saveMessage!=null) Padding(padding:const EdgeInsets.only(top:10),child:Text(_saveMessage!,style:const TextStyle(color:_cyan,fontSize:12))),
          const SizedBox(height:12),
          const Text('Data is stored locally on this tablet. This prototype does not encrypt records, connect to sensors, synchronize with a flight surgeon, validate devices, or determine medical status. Use approved mission procedures for interpretation.',style:TextStyle(color:Colors.white60,fontSize:11,height:1.4)),
        ]));
        final history=_panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[const Expanded(child:Text('MEASUREMENT HISTORY',style:TextStyle(color:_cyan,fontWeight:FontWeight.bold,letterSpacing:1.1))),
            Text('${_records.length} records',style:const TextStyle(color:Colors.white54,fontSize:11))]),
          const SizedBox(height:10),
          if (_records.isEmpty) const Padding(padding:EdgeInsets.all(22),child:Center(child:Text('No measurements recorded yet.',style:TextStyle(color:Colors.white54)))),
          ..._records.take(100).map((r)=>ListTile(contentPadding:EdgeInsets.zero,
            title:Text('${r.metric}: ${r.value} ${r.unit}',style:const TextStyle(fontWeight:FontWeight.w600)),
            subtitle:Text('${r.source} • ${DateTime.tryParse(r.timestamp)?.toLocal().toString().substring(0,16) ?? r.timestamp}${r.note.isEmpty?'':'\n${r.note}'}',
              style:const TextStyle(color:Colors.white60,fontSize:11)),
            trailing:IconButton(tooltip:'Delete record',icon:const Icon(Icons.delete_outline,size:19),onPressed:()=>_delete(r)))),
        ]));
        return SingleChildScrollView(padding:const EdgeInsets.all(16),child:wide
          ? Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:form),const SizedBox(width:16),Expanded(child:history)])
          : Column(children:[form,const SizedBox(height:14),history]));
      })),
    );
  }
}
