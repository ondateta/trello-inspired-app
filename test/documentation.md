# Real-time Synchronization Testing Documentation

## Test Scenarios

### Basic Real-time Updates
- **New Task Creation:** Verify that when a task is created, it appears in all clients viewing the board without requiring a refresh.
- **Task Deletion:** Confirm that when a task is deleted, it disappears from all clients viewing the board.
- **Task Updates:** Ensure that when a task's title, description, or other properties are modified, changes propagate to all clients.

### Column/Status Changes
- **Task Movement Between Columns:** Validate that when a task is dragged to a different status column, the change is reflected across all clients.
- **Visual Indicator for Column Movement:** Verify that a visual indicator (e.g., snackbar) appears when a task changes column.
- **Category Assignment Change:** Test that when a task's category is changed, it moves to the appropriate column in all clients.

### Tag Modifications
- **Adding Tags:** Confirm that newly added tags to a task appear on all clients.
- **Removing Tags:** Verify that when tags are removed from a task, they disappear from all clients.
- **Tag Filter Syncing:** Ensure that when filtering by tags, new tasks that match the filter appear automatically.

### Filter and Search Interactions
- **Search Results Updates:** Verify that search results update in real-time as tasks are added or modified.
- **Filter Persistence:** Confirm that applied filters persist and continue to work with real-time updates.

### Edge Cases
- **Multiple Simultaneous Updates:** Test behavior when multiple clients update different tasks simultaneously.
- **Network Disconnection/Reconnection:** Validate that clients properly resync after a network disruption.
- **Large Data Sets:** Ensure performance remains acceptable with a large number of tasks.

## Test Implementation

The implementation consists of two main test files:

1. `realtime_sync_test.dart`: Tests the UI components' ability to respond to real-time updates
2. `multi_client_simulation_test.dart`: Simulates multiple clients interacting with the same board

## Running the Tests

Execute the tests using:


flutter test test/realtime_sync_test.dart
flutter test test/multi_client_simulation_test.dart


## Manual Testing Checklist

For scenarios difficult to automate, follow this manual testing checklist:

- [ ] Open the same board in two different browser windows/devices
- [ ] Create a task in one client and verify it appears in the other
- [ ] Move a task to a different column in one client and verify the change in the other
- [ ] Add and remove tags in one client and verify changes in the other
- [ ] Apply filters in both clients and verify they work independently
- [ ] Test with slow network conditions to ensure eventual consistency