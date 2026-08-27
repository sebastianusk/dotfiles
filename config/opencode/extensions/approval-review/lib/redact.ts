export function redact(value: string, patterns: RegExp[]): string {
  return patterns.reduce((result, pattern) => {
    const flags = pattern.flags.replace("y", "");
    const globalPattern = new RegExp(pattern.source, flags.includes("g") ? flags : `${flags}g`);
    globalPattern.lastIndex = 0;
    return result.replace(globalPattern, "[REDACTED]");
  }, value);
}
