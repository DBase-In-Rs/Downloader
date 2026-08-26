# Security Policy

## Supported Versions

The project is pre-1.0 and does not yet provide supported production releases.
Security fixes will target the latest development branch until versioned
releases exist.

## Reporting A Vulnerability

Do not open a public issue for vulnerabilities involving:

- cookie leakage;
- account/session handling;
- path traversal or unsafe file writes;
- exposed logs containing private URLs, tokens, or cookies;
- exported Android components that can be abused by other apps.

Use GitHub private vulnerability reporting once it is enabled for the
repository. Until then, contact the maintainer privately.

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
