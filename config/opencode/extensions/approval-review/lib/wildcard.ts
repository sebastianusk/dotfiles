const SPECIAL = /[|\\{}()[\]^$+*?.-]/g;

export function matches(value: string, pattern: string): boolean {
  const normalizedValue = value.replaceAll("\\", "/");
  const normalizedPattern = pattern.replaceAll("\\", "/");
  const optionalArguments = normalizedPattern.endsWith(" *");
  const source = optionalArguments ? normalizedPattern.slice(0, -2) : normalizedPattern;
  let expression = "";
  for (const character of source) {
    if (character === "*") expression += ".*";
    else if (character === "?") expression += ".";
    else expression += character.replace(SPECIAL, "\\$&");
  }
  if (optionalArguments) expression += "(?: .*)?";
  return new RegExp(`^${expression}$`, process.platform === "win32" ? "is" : "s").test(normalizedValue);
}
