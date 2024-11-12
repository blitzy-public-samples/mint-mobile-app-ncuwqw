<!-- 
HUMAN TASKS:
1. Configure repository branch protection rules to require PR template completion
2. Set up required status checks for CI/CD pipeline
3. Configure code owners for automatic review assignments
4. Set up PR labeling automation for platform-specific changes
5. Configure PR size limits and review thresholds
-->

## PR Type
<!-- Select the type of change that this PR represents -->
- [ ] Feature Implementation
- [ ] Bug Fix
- [ ] Performance Improvement
- [ ] Refactoring
- [ ] Documentation
- [ ] Security Fix
- [ ] Dependencies Update

## Description
<!-- Addresses requirement: System Quality Assurance - Technical Specification/2.1 High-Level Architecture Overview -->

**Summary of changes:**
<!-- Provide a clear and concise description of the changes -->

**Related issue tickets:**
<!-- Reference any related issues using #issue_number -->

**Implementation approach:**
<!-- Describe the approach taken to implement the changes -->

**Breaking changes:**
<!-- List any breaking changes and migration steps if applicable -->

**Bug description and reproduction steps (for bug fixes):**
<!-- For bug fixes, describe the issue and steps to reproduce -->

## Technical Details
<!-- Addresses requirement: Cross-Platform Integration - Technical Specification/2.2 Component Architecture -->

**Architecture changes:**
<!-- Describe any changes to system architecture -->
```
- Component modifications:
- Service interactions:
- Data flow changes:
```

**Database changes:**
<!-- List any database schema or data modifications -->
```sql
-- Include relevant schema changes or migrations
```

**API changes:**
<!-- Document any API modifications -->
```
- Endpoints added/modified:
- Request/response changes:
- Backward compatibility:
```

**Security implications:**
<!-- Addresses requirement: Security Standards Compliance - Technical Specification/6.1 Authentication and Authorization -->
```
- Authentication impact:
- Authorization changes:
- Data protection measures:
- Security best practices implemented:
```

**Performance impact:**
<!-- Describe performance implications -->
```
- Load testing results:
- Resource utilization:
- Optimization measures:
```

## Testing
<!-- Addresses requirement: System Quality Assurance - Technical Specification/2.1 High-Level Architecture Overview -->

**Unit tests added/updated:**
<details>
<summary>Test coverage report</summary>

```
Include test coverage metrics
```
</details>

**Integration tests added/updated:**
<details>
<summary>Integration test results</summary>

```
Include integration test results
```
</details>

**Manual testing steps:**
```
1. Step-by-step test procedures
2. Expected results
3. Actual results
```

**Test coverage report:**
<!-- Include overall test coverage metrics -->

## Platform Impact
<!-- Addresses requirement: Cross-Platform Integration - Technical Specification/2.2 Component Architecture -->

| Platform | Changes | Testing Status | Notes |
|----------|---------|----------------|-------|
| iOS      |         |                |       |
| Android  |         |                |       |
| Web      |         |                |       |
| Backend  |         |                |       |

**Cross-platform considerations:**
<!-- Detail any cross-platform compatibility measures -->

## Deployment Requirements
<!-- Addresses requirement: System Quality Assurance - Technical Specification/2.1 High-Level Architecture Overview -->

**Database migrations:**
```
- Migration scripts:
- Rollback procedures:
- Data backup requirements:
```

**Environment variables:**
```
- New variables:
- Modified variables:
- Deprecated variables:
```

**Infrastructure changes:**
```
- Resource requirements:
- Scaling considerations:
- Configuration updates:
```

**Deployment order:**
```
1. Step-by-step deployment procedure
2. Dependencies and prerequisites
3. Verification steps
```

## Documentation
<!-- Addresses requirement: Cross-Platform Integration - Technical Specification/2.2 Component Architecture -->

**API documentation updates:**
<!-- List any API documentation changes -->

**README updates:**
<!-- List any README modifications -->

**Architecture documentation changes:**
<!-- Describe updates to architecture documentation -->

**Deployment guide updates:**
<!-- Reference any deployment guide changes -->

## Checklist
<!-- Ensure all items are checked before requesting review -->
- [ ] Code follows style guidelines
- [ ] Security best practices followed
- [ ] Tests passing
- [ ] Documentation updated
- [ ] No sensitive data exposed
- [ ] Breaking changes documented
- [ ] Cross-platform testing completed
- [ ] PR size is reasonable
- [ ] Self-review completed
- [ ] CI/CD pipeline passing