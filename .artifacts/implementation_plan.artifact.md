# Network Details & Machine List

The user wants to add a "Network Details" screen that opens when a network card is tapped. This screen will display information about the network, the router's status, and a list of all machines within the network. Each machine will have a dedicated card showing its details and current status. A pull-to-refresh action will simulate fetching updated statuses for all machines.

## Open Questions
- Is the dummy data going to remain mutable for this pull-to-refresh simulation, or should we recreate the machine models? *I will make the machine status mutable for simplicity in this dummy implementation.*

## Proposed Changes

### [Models]
Update the machine model to include a status.
#### [MODIFY] `lib/models/machine.dart`
- Create a `MachineStatus` enum with `online`, `offline`, and `wakingUp` values.
- Add a mutable `status` field to the `Machine` class, defaulting to `offline`.

### [Theme]
Update the status colors to support the new "waking up" state.
#### [MODIFY] `lib/theme/app_theme.dart`
- Add a `wakingUp` color (e.g., Amber/Yellow) to `AppStatusColors`.

### [UI Components - Updates]
Make the network card tappable and extract the status badge so it can be reused.
#### [MODIFY] `lib/widgets/network_card.dart`
- Extract `_RouterStatusBadge` into a public `RouterStatusBadge` widget (either in this file or a new one, perhaps a new `status_badges.dart` file).
- Add an `onTap` callback to `NetworkCard`.
- Wrap the card's contents in an `InkWell` to show a ripple effect on tap.

### [UI Components - New]
Create the new machine card and details screen.
#### [NEW] `lib/widgets/machine_card.dart`
- Create a stateless widget to represent a machine.
- Display the name, MAC address, and Tailscale IP.
- Display a visual status indicator (Circle or Badge with `🟢 Online`, `🔴 Offline`, `🟡 Waking up`).

#### [NEW] `lib/screens/network_details_screen.dart`
- Create a stateful widget that takes a `Network` object.
- **AppBar**: Display the network name.
- **Body**: Use a `RefreshIndicator` wrapping a `ListView`.
- **Top Section**: Show the network description and `RouterStatusBadge`.
- **Machine List**: Render a `MachineCard` for each machine in the network.
- **Pull-to-refresh**: Implement a `_refresh` method that delays for a second (simulating a network request) and updates the machine statuses (e.g., changes offline to waking up, or waking up to online) inside a `setState`.

#### [MODIFY] `lib/screens/network_list_view.dart`
- Pass an `onTap` callback to the `NetworkCard`.
- The callback should use `Navigator.push` to navigate to `NetworkDetailsScreen`, passing the selected `Network`.

## Verification Plan
### Automated Tests
- Run `flutter analyze` to ensure no syntax errors.

### Manual Verification
- Tap a network card and verify it navigates to the new screen.
- Verify the network name and router status are displayed at the top.
- Check the machine cards for correct data (Name, IP, MAC, Status).
- Pull down to refresh and ensure the visual status indicators update properly.