import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/network.dart';
import '../models/machine.dart';

class CreateNetworkScreen extends StatefulWidget {
  const CreateNetworkScreen({super.key});

  @override
  State<CreateNetworkScreen> createState() => _CreateNetworkScreenState();
}

class _CreateNetworkScreenState extends State<CreateNetworkScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _networkName = '';
  String _description = '';
  String _routerIp = '';
  int _routerPort = 0;
  
  final List<Machine> _machines = [];

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
      _formKey.currentState!.save();
      
      final newNetwork = Network(
        name: _networkName,
        description: _description,
        machines: _machines,
        routerIp: _routerIp,
        routerPort: _routerPort,
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Network Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a network name';
                }
                return null;
              },
              onSaved: (value) => _networkName = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onSaved: (value) => _description = value!,
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
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Router IP Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    onSaved: (value) => _routerIp = value!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'WOL Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                    onSaved: (value) => _routerPort = int.parse(value!),
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
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.surface,
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
  String _name = '';
  String _tailscaleIp = '';
  String _macAddress = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Machine'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Machine Name'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tailscale IP'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => _tailscaleIp = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'MAC Address'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => _macAddress = value!,
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onAdd(Machine(
                name: _name,
                tailscaleIp: _tailscaleIp,
                macAddress: _macAddress,
              ));
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
