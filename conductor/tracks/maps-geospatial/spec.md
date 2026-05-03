# Maps Geospatial Spec

## Goal

Let users discover gyms and workout partners near their current location.

## Technical Requirements

- Backend geospatial queries use MongoDB indexes and environment-driven database configuration.
- Flutter requests location permission with clear denied and disabled-location states.
- Map UI supports separate marker types for gyms and buddies.
- API requests should be bounded by radius and pagination or result limits.

## Blockers

- Google Maps API key provisioning.
- Final radius defaults for buddy discovery.
- Data model for gym source and verification status.
