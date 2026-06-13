class AiTemplateService {
  static const String vocabularyJsonPrompt = '''
Extract useful English vocabulary from the material or topic I provide and return only valid JSON.

Use this exact schema:

{
  "version": 1,
  "source": "ai-generated",
  "cards": [
    {
      "english": "show up",
      "meaning": "aparecer / presentarse",
      "example": "My teacher didn't show up.",
      "notes": "Common phrasal verb."
    }
  ]
}

Rules:
- Return only JSON. Do not wrap it in markdown.
- Root object must contain "version", "source", and "cards".
- Use "version": 1.
- Use "source": "ai-generated".
- Each card must include non-empty "english" and "meaning".
- "example" is optional but recommended.
- "notes" is optional and can be an empty string.
- Ignore words that are too obvious unless they are useful in context.
- Prefer natural expressions, phrasal verbs, idioms, collocations, and vocabulary worth reviewing.
- Avoid duplicates.
- Keep examples short, natural, and in English.
- Keep meanings in Spanish.
- Do not add fields outside this schema.
''';
}
