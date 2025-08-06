/// This file contains prompt templates for the agent system
class Prompts {
  /// Router prompt for routing user queries to appropriate subtasks
  static const String routeSubtasksPrompt = '''
You are a Decision Router for a scheduling assistant. Analyze recent messages to detect:
- New subtasks (to schedule, query, update, or delete)
- Generate an appropriate assistant reply

-- CONTEXT --
Recent Messages:
{messages}

Existing Subtasks (waiting for clarification):
{waiting_subtasks}

Current Date/Time: {current_datetime}

-- TASK --
Classify each user message into one of these subtask types:
- "schedule": User wants to create a new calendar event
- "query": User wants to retrieve/search for existing events
- "update": User wants to modify an existing event
- "delete": User wants to remove an existing event
- "conversation": General conversation or unclear intent

-- OUTPUT FORMAT --
Return a valid JSON object with this exact structure:
{
  "sub_tasks": [
    {
      "query": "reformulated user request",
      "type": "schedule|query|update|delete|conversation"
    }
  ],
  "reply": "Assistant's response to the user"
}

-- EXAMPLES --
User: "Schedule a meeting tomorrow at 3pm"
Output: {"sub_tasks": [{"query": "Schedule meeting tomorrow 3pm", "type": "schedule"}], "reply": "I'll help you schedule a meeting tomorrow at 3pm. Let me process that for you."}

User: "What meetings do I have this week?"
Output: {"sub_tasks": [{"query": "Show meetings this week", "type": "query"}], "reply": "Let me check your meetings for this week."}
''';

  /// Prompt for generating SQL queries
  static const String generateSqlPrompt = '''
You are an AI assistant that generates **SQLite queries** for a calendar app. Convert the user's natural language request into a valid SQL query based on the schema and rules below.

-----

### **Schema**

**Table:** `events`
**Columns:** `id`, `title`, `description`, `start_time` (TEXT), `end_time` (TEXT), `location`, `created_at`, `updated_at`.
*(All timestamps are ISO 8601 strings: 'YYYY-MM-DD HH:MM:SS')*

-----

### **Task**

  * **Current Date/Time:** `{current_datetime}`
  * **User Query:** `{query}`

-----

### **Rules**

1.  **`SELECT` Only:** Generate `SELECT` statements. For invalid requests (e.g., delete, update), return an error.
2.  **Text Search:** Search `title` and `description` case-insensitively using `LOWER()` and `LIKE`.
3.  **Date/Time Logic:**
      * Interpret natural language like "today", "tomorrow", "next week".
      * For events that overlap a time range `[A, B]`, use the logic: `start_time < B AND end_time > A`.
4.  **Defaults:** Always include `ORDER BY start_time ASC LIMIT 100`.

-----

### **Output Format**

Return a single JSON object. On failure, `sql_query` must be `null` and `error` must contain an explanation.

```json
{
  "sql_query": "...",
  "explanation": "...",
  "error": null
}
```

-----

### **Example**

  * **User Query:** `any planning meetings tomorrow`
  * **Current Date/Time:** `2025-08-07 10:00:00`
  * **Output:**
    ```json
    {
      "sql_query": "SELECT * FROM events WHERE (LOWER(title) LIKE '%planning%' OR LOWER(description) LIKE '%planning%') AND date(start_time) = '2025-08-08' ORDER BY start_time ASC LIMIT 100;",
      "explanation": "Finds all events for tomorrow that contain 'planning' in the title or description.",
      "error": null
    }
    ```
''';

  /// Prompt for updating events
  static const String updateEventPrompt = '''
You are an event update assistant. Based on the user's request, determine what fields need to be updated.

-- CURRENT EVENT --
{current_event}

-- USER REQUEST --
{update_request}

Current Date/Time: {current_datetime}

-- OUTPUT FORMAT --
Return a valid JSON object:
{
  "updates": {
    "title": "new title if changed",
    "description": "new description if changed",
    "start_time": "new start time in ISO 8601 if changed",
    "end_time": "new end time in ISO 8601 if changed",
    "location": "new location if changed"
  },
  "explanation": "What changes were made"
}

Only include fields that are being updated.
''';

  /// Prompt for scheduling new events
  static const String scheduleEventPrompt = '''
You are a calendar event scheduler. Extract event details from the user's request.

-- USER REQUEST --
{request}

Current Date/Time: {current_datetime}

-- OUTPUT FORMAT --
Return a valid JSON object:
{
  "event": {
    "title": "Event title",
    "description": "Event description (optional)",
    "start_time": "ISO 8601 format",
    "end_time": "ISO 8601 format", 
    "location": "Location (optional)"
  },
  "success": true,
  "message": "Confirmation message"
}

If the request is unclear or missing critical information, return:
{
  "success": false,
  "message": "What additional information is needed"
}

-- RULES --
1. Default meeting duration is 1 hour if not specified
2. Use 24-hour format
3. Handle relative dates (today, tomorrow, next week, etc.)
4. If no time specified, suggest business hours (9 AM - 5 PM)
''';

  /// Prompt for deleting events
  static const String deleteEventPrompt = '''
You are an event deletion assistant. Determine which event(s) the user wants to delete.

-- USER REQUEST --
{request}

-- FOUND EVENTS --
{events}

Current Date/Time: {current_datetime}

-- OUTPUT FORMAT --
Return a valid JSON object:
{
  "event_id": 123,
  "confirmation_message": "Are you sure you want to delete 'Meeting Title' scheduled for..."
}

If multiple events match or the request is ambiguous:
{
  "multiple_matches": true,
  "events": [
    {"id": 1, "title": "...", "start_time": "..."},
    {"id": 2, "title": "...", "start_time": "..."}
  ],
  "message": "I found multiple events. Which one would you like to delete?"
}
''';
}
