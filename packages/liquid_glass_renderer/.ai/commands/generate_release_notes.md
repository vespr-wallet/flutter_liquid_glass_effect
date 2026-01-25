# Generate Play Store Release Notes

1. A version will be given as argument. If no version is provided when running this task, ask for a version.
2. Look at `CHANGELOG.md` to see what's been changed in this release.
3. Generate the release notes in the following XML format for all supported languages.

## Supported Languages

The app supports the following locales (all must be included):

| Locale Code | Language |
|-------------|----------|
| `en-US` | English |
| `de-DE` | German |
| `es-ES` | Spanish |
| `fr-FR` | French |
| `hi-IN` | Hindi |
| `ja-JP` | Japanese |
| `ko-KR` | Korean |
| `pt-PT` | Portuguese |
| `pt-BR` | Portuguese (Brazil) |
| `ro` | Romanian |
| `ru-RU` | Russian |
| `zh-CN` | Chinese (Simplified) |
| `zh-TW` | Chinese (Traditional) |

## Output Format

```md
<en-US>
This update includes general improvements for security, speed and reliability to keep everything running smoothly.

Also new:
- An important change

Enjoying VESPR? Please leave a rating! Your feedback helps us improve.
</en-US>
<de-DE>
...
</de-DE>
<es-ES>
...
</es-ES>
<fr-FR>
...
</fr-FR>
<hi-IN>
...
</hi-IN>
<ja-JP>
...
</ja-JP>
<ko-KR>
...
</ko-KR>
<pt-PT>
...
</pt-PT>
<pt-BR>
...
</pt-BR>
<ro>
...
</ro>
<ru-RU>
...
</ru-RU>
<zh-CN>
...
</zh-CN>
<zh-TW>
...
</zh-TW>
```

## Guidelines

- Write the output to `docs/release_notes/release_notes_{version}.md`
- Include **all 13 languages** listed above
- For "Also new" section, pick **max 3** user-facing changes
- If there are no relevant user-facing changes, **skip the "Also new" section entirely**
- Keep translations natural and idiomatic for each language