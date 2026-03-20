// ~/.finicky.ts
import type { FinickyConfig } from "/Applications/Finicky.app/Contents/Resources/finicky.d.ts";

function mapper(url: string): string[] {
  return [
    `${url}*`,
    `*.${url}*`
  ]
}

const workUrls = [
  "gitlab.com",
  "atlassian.com",
  "atlassian.net",
  "console.google.com"
].flatMap(mapper)

const personalUrls = [
  "gemini.google.com",
  "x.com",
  "instagram.com",
  "linkedin.com",
  "github.com"
].flatMap(mapper)

export default {
  defaultBrowser: "Google Chrome",
  handlers: [
    {
      match: personalUrls,
      browser: {
        name: "Google Chrome",
        profile: "personal"
      }
    },
    {
      match: (_url, { opener }) => opener?.name === "Slack",
      browser: {
        name: "Google Chrome",
        profile: "dkatalis"
      }
    },
    {
      match: workUrls,
      browser: {
        name: "Google Chrome",
        profile: "dkatalis"
      },
    },
  ],
} satisfies FinickyConfig;
