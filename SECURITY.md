# Security Policy

## Supported Versions

Pre-releases (1.0.0 betas) are published on GitHub Releases. Security fixes
target the latest release line and the `main` branch; older pre-releases are
not patched — update to the newest release.

## Reporting A Vulnerability

Do not open a public issue for vulnerabilities involving:

- cookie leakage;
- account/session handling;
- path traversal or unsafe file writes;
- exposed logs containing private URLs, tokens, or cookies;
- exported Android components that can be abused by other apps.

Use GitHub private vulnerability reporting (enabled for this repository:
Security tab > Report a vulnerability). The repository also runs Dependabot
alerts and security updates, secret scanning with push protection, and
CodeQL code scanning.

## Sensitive Data Rules

- Never attach real cookies, tokens, or private URLs to public issues.
- Redact logs before sharing them.
- Prefer test URLs that do not require login.
- Delete imported cookies from test devices after testing.

## Expected Handling

Security reports should receive:

- confirmation when the report is received;
- a severity assessment;
- a fix plan or explanation;
- credit if requested and appropriate.
