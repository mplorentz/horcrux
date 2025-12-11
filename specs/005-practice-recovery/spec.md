# Feature Specification: Practice Recovery

**Feature Branch**: `005-practice-recovery`  
**Created**: 2025-01-09  
**Status**: Draft  
**Parent Plan**: Owner-Initiated Vault Recovery (Phases 1-3)

---

## Summary

Allow vault owners to test their recovery setup by sending practice recovery requests to stewards. This validates that stewards are responsive and the recovery flow works, without exposing actual vault data. Practice recovery is the highest-priority feature for user confidence.

---

## User Scenarios & Testing

### Primary User Story
As a vault owner, I want to send a practice recovery request to my stewards, so that I can verify they will respond when I actually need to recover my vault, and build confidence that my backup is working.

### Acceptance Scenarios

1. **Given** a vault owner has distributed shards to stewards, **When** they tap "Practice Recovery" in vault settings, **Then** a practice recovery request is sent to all stewards with clear "PRACTICE" labeling

2. **Given** a steward receives a practice recovery request, **When** they view the notification, **Then** they see it is clearly marked as a practice request (not a real recovery)

3. **Given** a steward views a practice recovery request, **When** they tap approve or deny, **Then** their response is sent back to the vault owner (no shard data included)

4. **Given** a vault owner has sent a practice request, **When** stewards respond, **Then** the owner sees which stewards responded and how (approved/denied)

5. **Given** a practice recovery is complete, **When** the owner views the results, **Then** they see a summary like "3 of 4 stewards responded. Your backup is ready for real recovery."

6. **Given** a practice recovery is complete, **When** the owner taps "End Practice", **Then** the practice request is archived and they return to the vault detail screen

### Edge Cases

- **What if owner initiates practice while a real recovery is in progress?** Block practice initiation; show message "Cannot practice during active recovery"
- **What if owner has no stewards yet?** Hide or disable the Practice Recovery button until shards are distributed
- **What if steward hasn't received their shard yet?** They can still respond to practice (tests notification flow), but show warning that they don't have a shard yet
- **What if owner cancels practice mid-way?** Allow cancellation, archive the practice request as cancelled
- **What if all stewards deny the practice request?** Show result: "0 of N stewards approved. Consider following up with your stewards."

---

## Requirements

### Functional Requirements

- **FR-001**: System MUST add `isPractice` boolean field to `RecoveryRequest` model
- **FR-002**: System MUST show "Practice Recovery" button in vault detail screen only after shard distribution is complete
- **FR-003**: System MUST prevent practice recovery when a real recovery is in progress
- **FR-004**: System MUST send practice recovery requests to all stewards with clear "PRACTICE" labeling
- **FR-005**: System MUST display practice requests differently in steward notification overlay (badge/styling)
- **FR-006**: System MUST allow stewards to approve or deny practice requests without sending shard data
- **FR-007**: System MUST track and display steward responses for practice requests
- **FR-008**: System MUST show owner a summary of practice results (X of Y responded, X approved)
- **FR-009**: System MUST allow owner to "End Practice" to archive the practice request
- **FR-010**: System MUST allow owner to cancel practice mid-way
- **FR-011**: System MUST NOT include or expose actual vault content during practice recovery

### Non-Functional Requirements

- Practice requests should use the same Nostr event structure as real recovery requests (with `isPractice: true`)
- Practice responses should be fast (<2s to send/receive)
- UI should clearly differentiate practice from real recovery at every step

---

## User Interface Flow

### Owner Initiates Practice

1. **Vault Detail Screen**: Show "Practice Recovery" button (only if shards distributed, no active recovery)
2. **Confirmation Dialog**: "Send a practice recovery request to your stewards? This tests that they can respond but won't share any vault data."
3. **Practice Status Screen**: Show progress (same as recovery status screen but with "Practice" banner)

### Steward Receives Practice Request

1. **Notification Overlay**: Practice request appears with "PRACTICE" badge
2. **Practice Request Detail**: 
   - Clear "PRACTICE REQUEST" header
   - Message: "This is a practice request. No vault data will be shared."
   - Approve/Deny buttons
3. **Post-Response**: "Practice response sent. The vault owner will see your response."

### Owner Views Practice Results

1. **Practice Status Screen**: 
   - "Practice Recovery" header with distinct styling
   - Progress indicator showing responses received
   - List of stewards with their response status
   - Summary: "X of Y stewards responded"
2. **End Practice Button**: Archives the practice request

---

## Key Entities

- **RecoveryRequest.isPractice**: Boolean flag indicating this is a practice request
- No new entities required - reuses existing `RecoveryRequest` and `RecoveryResponse` models

---

## Dependencies

- Requires existing recovery request/response infrastructure
- Requires steward notification overlay to be functional
- Requires shard distribution to be complete (to know who stewards are)

---

## Out of Scope

- Full reconstruction with test data (deferred to future "advanced practice" feature)
- Practice with individual stewards (always sends to all)
- Automated/scheduled practice reminders

---

## Review Checklist

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All scenarios testable and unambiguous
- [x] Edge cases documented
- [x] UI flow described
