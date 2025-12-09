# Feature 005: Practice Recovery

## Overview

Allow vault owners to practice the recovery process without actually initiating a real recovery request. This helps users understand the recovery workflow and verify their setup is working correctly.

## Problem Statement

Users who set up vault recovery may not fully understand the recovery process until they actually need it. By that time, it may be too late to fix issues in their configuration. Users need a way to:

1. Test the recovery process without creating actual recovery requests that alert stewards
2. Verify their recovery plan is working correctly
3. Understand what stewards will see during a real recovery
4. Build confidence in the recovery system

## Scope

**In Scope:**
- Add a "Practice Recovery" button for vault owners on the vault detail screen
- Show a dialog explaining what practice recovery does
- Display a preview of what the recovery request would look like
- Show which stewards would be contacted
- Explain the threshold requirements
- Provide educational content about the recovery process

**Out of Scope:**
- Actually sending recovery requests to stewards (this is practice only)
- Performing actual shard reconstruction (would require steward participation)
- Testing the Nostr message delivery (no actual messages sent)

## User Stories

**As a vault owner**, I want to practice the recovery process so that I understand what will happen when I need to recover my vault.

**As a vault owner**, I want to verify my recovery plan is correct before I actually need it, so that I can fix any issues ahead of time.

**As a vault owner**, I want to see what information my stewards will receive during recovery, so I can ensure they have the context they need.

## Success Criteria

1. Vault owners can access a "Practice Recovery" feature from the vault detail screen
2. The practice flow explains the recovery process clearly
3. Users see which stewards would be contacted and what the threshold requirements are
4. The practice flow does not send actual recovery requests or alert stewards
5. Users understand the difference between practice and real recovery

## Technical Requirements

1. Add UI flow for practice recovery accessible from vault detail screen
2. Display recovery plan details (stewards, threshold, etc.)
3. Show educational content about the recovery process
4. Validate recovery plan is ready before allowing practice
5. Make it clear this is practice and not a real recovery

## Non-Goals

- Simulating the full recovery process with fake shard collection
- Testing actual Nostr message delivery
- Allowing stewards to participate in practice recovery
- Storing practice recovery requests in the database
