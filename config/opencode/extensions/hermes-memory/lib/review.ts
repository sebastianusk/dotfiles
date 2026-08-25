import type { ReviewCandidate } from "./ollama.js";
import { MemoryStore } from "./store.js";

type Turn = {
  sessionID: string;
  messageID: string;
  projectId: string;
  text: string;
};

type ReviewFn = (transcript: string) => Promise<ReviewCandidate[]>;

export class MemoryReviewScheduler {
  private readonly sessions = new Map<string, { turns: Turn[]; reviewCount: number; lastReviewAt: number; inFlight?: Promise<number> }>();

  constructor(private readonly config: { store: MemoryStore; reviewEveryTurns: number; minIntervalMs: number; minConfidence?: number; maxTranscriptChars?: number }) {}

  async recordTurn(turn: Turn): Promise<void> {
    const session = this.session(turn.sessionID);
    session.turns.push(turn);
    session.reviewCount++;
  }

  async reviewIfDue(sessionID: string, review: ReviewFn): Promise<number> {
    const session = this.session(sessionID);
    if (session.reviewCount < this.config.reviewEveryTurns || Date.now() - session.lastReviewAt < this.config.minIntervalMs) return 0;
    return this.reviewSession(sessionID, review);
  }

  async flush(sessionID: string, review: ReviewFn): Promise<number> {
    const history = this.session(sessionID).turns;
    if (history.length === 0) return 0;
    return this.reviewSession(sessionID, review);
  }

  nextReviewDelay(sessionID: string): number | undefined {
    const session = this.session(sessionID);
    if (session.reviewCount < this.config.reviewEveryTurns) return undefined;
    return Math.max(0, this.config.minIntervalMs - (Date.now() - session.lastReviewAt));
  }

  private async reviewSession(sessionID: string, review: ReviewFn): Promise<number> {
    const session = this.session(sessionID);
    if (session.inFlight) return session.inFlight;
    const operation = this.performReview(session, review);
    session.inFlight = operation;
    try {
      return await operation;
    } finally {
      session.inFlight = undefined;
    }
  }

  private async performReview(session: { turns: Turn[]; reviewCount: number; lastReviewAt: number }, review: ReviewFn): Promise<number> {
    const history = this.boundedHistory(session.turns);
    const reviewedCount = history.length;
    const candidates = await review(history.map((item) => `User: ${item.text}`).join("\n\n"));
    let staged = 0;
    for (const candidate of candidates.filter((item) => item.confidence >= (this.config.minConfidence ?? 0))) {
      await this.config.store.stage({
        ...candidate,
        projectId: candidate.target === "project" ? history.at(-1)?.projectId : undefined,
        sourceSessionIds: [...new Set(history.map((item) => item.sessionID))],
        sourceMessageIds: history.map((item) => item.messageID),
      });
      staged++;
    }
    session.turns.splice(session.turns.length - reviewedCount, reviewedCount);
    session.reviewCount = session.turns.length;
    session.lastReviewAt = Date.now();
    return staged;
  }

  private session(sessionID: string): { turns: Turn[]; reviewCount: number; lastReviewAt: number; inFlight?: Promise<number> } {
    let session = this.sessions.get(sessionID);
    if (!session) {
      session = { turns: [], reviewCount: 0, lastReviewAt: 0 };
      this.sessions.set(sessionID, session);
    }
    return session;
  }

  private boundedHistory(turns: Turn[]): Turn[] {
    const limit = this.config.maxTranscriptChars;
    if (!limit) return [...turns];
    const selected: Turn[] = [];
    let length = 0;
    for (const turn of [...turns].reverse()) {
      const turnLength = Buffer.byteLength(`User: ${turn.text}`) + (selected.length ? 2 : 0);
      if (selected.length > 0 && length + turnLength > limit) break;
      selected.push(turn);
      length += turnLength;
    }
    return selected.reverse();
  }
}
