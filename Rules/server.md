# Server Debugging Rules

## 1. Server Management
- **Never start or create the server yourself** — The user will start the server manually. Wait for the user to provide the server IP and port, then use them directly.
- **Ask for the server URL** — Before testing APIs, always ask the user for the current server address (e.g., `http://127.0.0.1:5001`).
- **Do not hardcode ports** — Never assume a port number. Confirm with the user each debugging session.

## 2. Frontend Inspection
- **Do not inspect the frontend yourself** — Using browser tools to screenshot or check the frontend is slow and inefficient. Rely on the user to describe or screenshot frontend issues.
- **User feedback first** — Once the user describes a frontend problem, locate the code issue based on their description.

## 3. API Testing Principles
- **Truncate responses** — When testing API responses, only extract the beginning and end (e.g., using `head`, `tail`, `jq`). Never output the full response.
- **Validation focus:**
  - Data exists (non-empty, no errors)
  - Data structure/format is correct (field names, types, nesting)
  - If calculated values are wrong, report to the user — do not try to verify every single value
- **Limit output length** — Keep API response output under 20 lines. Use `| tail -20` or similar to truncate.

## 4. Debugging Workflow
- **Confirm server is running** — Have the user confirm the server is up before starting.
- **Test APIs with curl** — Use concise curl commands and truncate output.
- **Locate issues** — Based on API responses and logs, pinpoint the problem.
- **Modify code** — After changes, have the user restart or hot-reload the server.

## 5. Error Handling
- **500 errors** — Check server logs to locate the issue.
- **404 errors** — Check route registration.
- **Frontend errors** — Ask the user for console error messages.