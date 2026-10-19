# Speculative recovery updates

Repository-only branch: `speculative/hopan-recovery-two-pass`, based on `b36f338`.
No publication, merge, new campaign, difficulty change or RiverSim edit is part
of these two passes. The current public Site remains version 26.

## Pass one — explicit death recovery

The death screen distinguishes **Retry checkpoint · R** from **Retry from start
· R**. Its summary explains that hazards restart and describes the restored
long-hop resource: saved fragments/reserve, seed requirement, or a ready free/
charged hop. It reads the saved snapshot, not inventory acquired after the flag.
The status line confirms checkpoint restoration. Retry mechanics are unchanged.

Focused native check: 17 recovery checks pass, including normal hop/flag claiming,
actual result presentation, emitted button actions, saved fragment versus later
inventory, seed restoration and charged refill. Existing set-menu assertions now
use the displayed retry action, retaining their progression checks.

Human wording preference and actual device layout remain speculative. Pass two
will add complementary pause/restart controls and verify the combined flow.
