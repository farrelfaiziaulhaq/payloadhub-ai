# payloadhub_ai

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
## Threat intelligence setup

The dashboard's VirusTotal panel supports URL scans, file uploads, analysis
refreshes, and MD5/SHA-1/SHA-256 lookups. Enter the VirusTotal API key under
Settings, or set `VIRUSTOTAL_API_KEY` in the backend `.env`. Keys are no longer
bundled as Flutter assets. For a remote backend use HTTPS. VirusTotal Community
API uploads are public; do not submit confidential files.

For this local setup, the backend also accepts a root-level `api-virustotal`
or `key-virustotal` file as the default key. Keep that file private.

The ExploitDB search field reads the official CSV catalogue through the backend
and caches it for one hour. Start the backend before using either feature.
