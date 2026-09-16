import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/network.dart';
import '../models/machine.dart';
import '../utils/validators.dart';

class CreateNetworkScreen extends StatefulWidget {
  const CreateNetworkScreen({super.key});

  @override
  State<CreateNetworkScreen> createState() => _CreateNetworkScreenState();
}

class _CreateNetworkScreenState extends State<CreateNetworkScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _routerIpController = TextEditingController();
  final _routerPortController = TextEditingController();
  
  final List<Machine> _machines = [];

  @override
  void initState() {
    super.initState();
    // Add listeners to rebuild UI and enable/disable button
    _nameController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
    _routerIpController.addListener(() => setState(() {}));
    _routerPortController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _routerIpController.dispose();
    _routerPortController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (Validators.validateRequired(_nameController.text, 'name') != null) return false;
    if (Validators.validateRequired(_descController.text, 'description') != null) return false;
    if (Validators.validateIp(_routerIpController.text) != null) return false;
    if (Validators.validatePort(_routerPortController.text) != null) return false;
    return true;
  }

  void _addMachine() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddMachineDialog(
          onAdd: (machine) {
            setState(() {
              _machines.add(machine);
            });
          },
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newNetwork = Network(
        name: _nameController.text,
        description: _descController.text,
        machines: _machines,
        routerIp: _routerIpController.text,
        routerPort: int.parse(_routerPortController.text),
        runningMachines: 0,
        isRouterRunning: false,
      );
      
      Navigator.of(context).pop(newNetwork);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Network'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Network Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validators.validateRequired(value, 'network name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => Validators.validateRequired(value, 'description'),
            ),
            const SizedBox(height: 24),
            Text(
              'Router Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _routerIpController,
                    decoration: const InputDecoration(
                      labelText: 'Router IP Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateIp,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _routerPortController,
                    decoration: const InputDecoration(
                      labelText: 'WOL Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.validatePort,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Machines (${_machines.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMachine,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Machine'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_machines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No machines added yet.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _machines.length,
                itemBuilder: (context, index) {
                  final machine = _machines[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.computer),
                      title: Text(machine.name),
                      subtitle: Text('${machine.tailscaleIp} • ${machine.macAddress}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _machines.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isFormValid ? _submitForm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.surface,
                disabledBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add the network'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMachineDialog extends StatefulWidget {
  final Function(Machine) onAdd;

  const _AddMachineDialog({required this.onAdd});

  @override
  State<_AddMachineDialog> createState() => _AddMachineDialogState();
}

class _AddMachineDialogState extends State<_AddMachineDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _tailscaleIpController = TextEditingController();
  final _macAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _tailscaleIpController.addListener(() => setState(() {}));
    _macAddressController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tailscaleIpController.dispose();
    _macAddressController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (Validators.validateRequired(_nameController.text, 'machine name') != null) return false;
    if (Validators.validateIp(_tailscaleIpController.text) != null) return false;
    if (Validators.validateMac(_macAddressController.text) != null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Machine'),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Machine Name'),
                validator: (value) => Validators.validateRequired(value, 'machine name'),
              ),
              TextFormField(
                controller: _tailscaleIpController,
                decoration: const InputDecoration(labelText: 'Tailscale IP'),
                validator: Validators.validateIp,
              ),
              TextFormField(
                controller: _macAddressController,
                decoration: const InputDecoration(labelText: 'MAC Address'),
                validator: Validators.validateMac,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isFormValid ? () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(Machine(
                name: _nameController.text,
                tailscaleIp: _tailscaleIpController.text,
                macAddress: _macAddressController.text,
                status: MachineStatus.offline,
              ));
              Navigator.of(context).pop();
            }
          } : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
