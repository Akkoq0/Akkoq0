/**
 * @file cleanCodeUtils.ts
 * @description Core Clean Code utility patterns: Functional Result types, Guard Clauses,
 * and immutable state helpers for high-assurance domain operations.
 */

export type Result<T, E = Error> =
  | { readonly ok: true; readonly value: T }
  | { readonly ok: false; readonly error: E };

/**
 * Creates a successful Result monad.
 */
export function success<T>(value: T): Result<T, never> {
  return { ok: true, value };
}

/**
 * Creates a failed Result monad.
 */
export function failure<E = Error>(error: E): Result<never, E> {
  return { ok: false, error };
}

/**
 * Clean Code Guard Clause: validates an invariant and throws with an actionable message if false.
 */
export function assertInvariant(
  condition: boolean,
  errorMessage: string,
): asserts condition {
  if (!condition) {
    throw new Error(`[CleanCode:InvariantViolation] ${errorMessage}`);
  }
}

/**
 * Safe JSON parser with strict fallback, preventing unhandled exceptions.
 */
export function safeJsonParse<T>(jsonString: string | null | undefined, fallback: T): T {
  if (!jsonString || typeof jsonString !== 'string') {
    return fallback;
  }
  try {
    return JSON.parse(jsonString) as T;
  } catch {
    return fallback;
  }
}

/**
 * Fast deep clone for plain JSON-compatible objects without mutation leaks.
 */
export function deepClone<T>(value: T): T {
  if (value === null || typeof value !== 'object') {
    return value;
  }
  if (typeof structuredClone === 'function') {
    return structuredClone(value);
  }
  return JSON.parse(JSON.stringify(value)) as T;
}

/**
 * Generates an ergonomically short, timestamp-prefixed alphanumeric ID.
 */
export function generatePrefixedId(prefix: string): string {
  const timestamp = Date.now().toString(36);
  const randomPart = Math.random().toString(36).substring(2, 7);
  return `${prefix}-${timestamp}-${randomPart}`;
}
