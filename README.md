# dash

Mobile clients for Dash.

- `app-android/`: Android app
- `app-ios/`: iOS app
- `specs/`: API and design references

## Local setup

Create an ignored `.secrets.properties` file at the repository root:

```properties
DATA_GO_KR_SERVICE_KEY=...
GOOGLE_MAPS_API_KEY=...
```

Then generate the platform files:

```sh
./scripts/generate-secrets.sh all
```

The input file and generated platform secret files are excluded from Git. Environment variables with the same names take precedence in CI.

GitHub Actions expects repository secrets named `DATA_GO_KR_SERVICE_KEY` and `GOOGLE_MAPS_API_KEY`.
