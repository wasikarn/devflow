import { describe, it, expect } from 'bun:test'
import { createEntry, validateEntry, formatEntry, parseEntry } from './metrics.js'

describe('createEntry', () => {
  it('should create entry with schema_version 1.1', () => {
    const entry = createEntry({
      skill: 'build',
      phase: 'research',
      mode: 'full',
      tokens: { input: 10000, output: 2000 }
    })

    expect(entry.schema_version).toBe('1.1')
    expect(entry.skill).toBe('build')
    expect(entry.phase).toBe('research')
    expect(entry.tokens!.input).toBe(10000)
    expect(entry.tokens!.output).toBe(2000)
    expect(entry.timestamp).toBeDefined()
  })

  it('should include cumulative_session in token tracking', () => {
    const entry = createEntry({
      skill: 'build',
      phase: 'research',
      mode: 'full',
      tokens: { input: 10000, output: 2000 }
    })

    expect(entry.tokens!.cumulative_session).toBeDefined()
    expect(typeof entry.tokens!.cumulative_session).toBe('number')
    expect(entry.tokens!.cumulative_session).toBe(12000)
  })

  it('should use custom cumulative_session if provided', () => {
    const entry = createEntry({
      skill: 'build',
      phase: 'research',
      mode: 'full',
      tokens: { input: 10000, output: 2000 },
      cumulative_session: 15000
    })

    expect(entry.tokens!.cumulative_session).toBe(15000)
  })
})

describe('validateEntry', () => {
  it('should validate entry without tokens field (backward compatibility)', () => {
    const legacyEntry = {
      timestamp: '2026-04-03T15:00:00Z',
      skill: 'build',
      phase: 'research',
      mode: 'full'
    }

    expect(() => validateEntry(legacyEntry)).not.toThrow()
    const validated = validateEntry(legacyEntry)
    expect(validated.schema_version).toBe('1.0')
    expect(validated.tokens).toBeUndefined()
  })

  it('should validate entry with tokens field', () => {
    const entry = {
      schema_version: '1.1' as const,
      timestamp: '2026-04-03T15:00:00Z',
      skill: 'build',
      phase: 'research',
      mode: 'full',
      tokens: { input: 10000, output: 2000, cumulative_session: 12000 }
    }

    expect(() => validateEntry(entry)).not.toThrow()
    const validated = validateEntry(entry)
    expect(validated.tokens!.input).toBe(10000)
  })

  it('should throw for null input', () => {
    expect(() => validateEntry(null)).toThrow('Invalid entry: must be an object')
  })

  it('should throw for non-object input', () => {
    expect(() => validateEntry('not an object')).toThrow('Invalid entry: must be an object')
  })

  it('should throw for missing timestamp', () => {
    expect(() => validateEntry({ skill: 'build', phase: 'research', mode: 'full' }))
      .toThrow('Invalid entry: missing timestamp')
  })

  it('should throw for missing skill', () => {
    expect(() => validateEntry({ timestamp: '2026-04-03T15:00:00Z', phase: 'research', mode: 'full' }))
      .toThrow('Invalid entry: missing skill')
  })

  it('should throw for missing phase', () => {
    expect(() => validateEntry({ timestamp: '2026-04-03T15:00:00Z', skill: 'build', mode: 'full' }))
      .toThrow('Invalid entry: missing phase')
  })

  it('should throw for missing mode', () => {
    expect(() => validateEntry({ timestamp: '2026-04-03T15:00:00Z', skill: 'build', phase: 'research' }))
      .toThrow('Invalid entry: missing mode')
  })

  it('should throw for invalid token input type', () => {
    expect(() => validateEntry({
      timestamp: '2026-04-03T15:00:00Z',
      skill: 'build',
      phase: 'research',
      mode: 'full',
      tokens: { input: 'not-a-number', output: 2000 }
    })).toThrow('Invalid entry: tokens.input and tokens.output must be numbers')
  })

  it('should throw for invalid token output type', () => {
    expect(() => validateEntry({
      timestamp: '2026-04-03T15:00:00Z',
      skill: 'build',
      phase: 'research',
      mode: 'full',
      tokens: { input: 10000, output: null }
    })).toThrow('Invalid entry: tokens.input and tokens.output must be numbers')
  })

  it('should default cumulative_session if missing in tokens', () => {
    const entry = {
      timestamp: '2026-04-03T15:00:00Z',
      skill: 'build',
      phase: 'research',
      mode: 'full',
      tokens: { input: 10000, output: 2000 }
    }

    const validated = validateEntry(entry)
    expect(validated.tokens!.cumulative_session).toBe(12000)
  })
})

describe('formatEntry', () => {
  it('should format entry as JSONL line', () => {
    const entry = createEntry({
      skill: 'build',
      phase: 'research',
      mode: 'full',
      tokens: { input: 10000, output: 2000 }
    })

    const line = formatEntry(entry)
    const parsed = JSON.parse(line)

    expect(parsed.schema_version).toBe('1.1')
    expect(parsed.skill).toBe('build')
    expect(parsed.tokens.input).toBe(10000)
  })

  it('should format legacy entry without tokens', () => {
    const legacyEntry = {
      schema_version: '1.0' as const,
      timestamp: '2026-04-03T15:00:00Z',
      skill: 'build',
      phase: 'research',
      mode: 'full'
    }

    const line = formatEntry(legacyEntry)
    const parsed = JSON.parse(line)

    expect(parsed.schema_version).toBe('1.0')
    expect(parsed.tokens).toBeUndefined()
  })
})

describe('parseEntry', () => {
  it('should parse JSONL line to MetricsEntry', () => {
    const line = '{"schema_version":"1.1","timestamp":"2026-04-03T15:00:00Z","skill":"build","phase":"research","mode":"full","tokens":{"input":10000,"output":2000,"cumulative_session":12000}}'

    const entry = parseEntry(line)

    expect(entry.schema_version).toBe('1.1')
    expect(entry.skill).toBe('build')
    expect(entry.tokens!.input).toBe(10000)
  })

  it('should parse legacy entry without tokens', () => {
    const line = '{"schema_version":"1.0","timestamp":"2026-04-03T15:00:00Z","skill":"build","phase":"research","mode":"full"}'

    const entry = parseEntry(line)

    expect(entry.schema_version).toBe('1.0')
    expect(entry.tokens).toBeUndefined()
  })

  it('should throw for invalid JSON', () => {
    expect(() => parseEntry('not valid json')).toThrow()
  })

  it('should validate parsed entry', () => {
    const line = '{"timestamp":"2026-04-03T15:00:00Z","skill":"build","phase":"research","mode":"full"}'

    const entry = parseEntry(line)

    expect(entry.schema_version).toBe('1.0')
    expect(entry.skill).toBe('build')
  })
})