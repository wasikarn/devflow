import { z } from 'zod'

export const VerdictSchema = z.object({
  findingIndex: z.number().int().min(0),
  originalSummary: z.string(),
  verdict: z.enum(['SUSTAINED', 'DOWNGRADED', 'REJECTED']),
  newSeverity: z.enum(['critical', 'warning', 'info']).optional(),
  rationale: z.string(),
})

export const VerdictArraySchema = z.array(VerdictSchema)
export const verdictArrayJsonSchema = z.toJSONSchema(VerdictArraySchema)
