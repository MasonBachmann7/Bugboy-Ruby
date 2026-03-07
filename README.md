# Bugboy Ruby

A test web app with **15 intentional runtime errors** built in Ruby (Sinatra). Used to test the functionality of [BugStack](https://github.com/MasonBachmann7), an autonomous error-fixing tool.

## Quick Start

```bash
bundle install
ruby app.rb
```

Then open [http://localhost:4567](http://localhost:4567) to access the dashboard.

## Bugs

| # | Route | Method | Error Type | Description |
|---|-------|--------|------------|-------------|
| 1 | `/trigger/type-error` | GET | `TypeError` | String concatenation with nil `last_name` |
| 2 | `/trigger/key-error` | GET | `KeyError` | Missing `notifications` key in preferences hash |
| 3 | `/trigger/no-method-error` | GET | `NoMethodError` | Calling `.email` on nil assignee |
| 4 | `/trigger/zero-division` | GET | `ZeroDivisionError` | Dividing by zero `sprint_length_days` |
| 5 | `/trigger/index-error` | GET | `IndexError` | Fetching from empty comments array |
| 6 | `/trigger/file-not-found` | GET | `Errno::ENOENT` | Loading config from nonexistent path |
| 7 | `/trigger/json-parse-error` | GET | `JSON::ParserError` | Parsing malformed JSON |
| 8 | `/trigger/encoding-error` | POST | `Encoding::UndefinedConversionError` | Invalid UTF-8 bytes in payload |
| 9 | `/trigger/recursion-error` | GET | `SystemStackError` | Circular category tree reference |
| 10 | `/trigger/connection-error` | GET | `Errno::ECONNREFUSED` | Unreachable database host |
| 11 | `/trigger/argument-error` | POST | `ArgumentError` | Parsing `"high"` as integer |
| 12 | `/trigger/permission-error` | GET | `Errno::EACCES` | Writing to read-only file |
| 13 | `/trigger/timeout-error` | GET | `Timeout::Error` | Slow query exceeds 2s timeout |
| 14 | `/trigger/thread-error` | GET | `NoMethodError` | Background thread crashes on nil template |
| 15 | `/trigger/memory-error` | POST | `NoMemoryError` | O(n²) cross-reference exhausts memory |

## API Endpoints

- `GET /` — Dashboard UI with trigger buttons
- `GET /api/bugs` — JSON list of all registered bugs
- `GET /health` — Health check
