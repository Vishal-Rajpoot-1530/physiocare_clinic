# PhysioCare Clinic Management

This project is converted from the RTS Gym application while preserving the existing working architecture and flows.

## UI baseline
- White + medical blue visual system
- Patient-centric terminology
- Existing authentication, local DB/API structure, payments, profiles, plans and reporting flows retained

## Domain mapping
Member → Patient; Membership → Treatment Plan; Trainer → Physiotherapist; Check-in → Visit Check-in; Workout → Treatment/Rehabilitation.

## Important
Backend endpoint/model names are intentionally preserved where changing them could break compatibility. User-facing labels are converted first. A future backend migration can rename legacy member/gym identifiers safely with database migrations.
