# Release and Promote Module

## Goal

Promote Fabric changes through controlled DEV → UAT → PROD stages.

## Inputs

- Deployment pipeline ID
- Source and target stage
- Item selection (optional)

## Preferred Route

- Primary: `fabric-api`
- Secondary: `fabric-cli`
- Guidance fallback: `context7-guidance`

## Procedure

1. Run pre-promotion validation.
2. Promote selected items through deployment pipeline.
3. Run post-promotion validation in target stage.
4. Publish release summary with rollback guidance.

## Outputs

- Promotion operation status
- Validation outcome
- Post-release checks and rollback notes
