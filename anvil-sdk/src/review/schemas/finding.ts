import { z } from 'zod'

export const FindingSchema = z.object({
  severity: z.enum(['critical', 'warning', 'info']),
  rule: z.string(),
  file: z.string(),
  line: z.number().int().nullable(),
  confidence: z.number().int().min(0).max(100),
  issue: z.string(),
  fix: z.string(),
  isHardRule: z.boolean(),
  crossDomain: z.string().optional(),
})

export const FindingArraySchema = z.array(FindingSchema)

// Export as JSON Schema for SDK outputFormat
export const findingArrayJsonSchema = z.toJSONSchema(FindingArraySchema)
