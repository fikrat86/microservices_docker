# Testing and Quality Assurance Guide

## Overview
This guide covers all testing, linting, and security practices implemented in the Forum Microservices project.

## Testing Framework

### Technology Stack
- **Test Framework**: Jest 29.7.0
- **HTTP Testing**: Supertest 6.3.3
- **Linting**: ESLint 8.56.0
- **Security**: npm audit + Trivy

## Running Tests

### Local Testing

#### Run All Tests
```powershell
# In each service directory (users, posts, threads)
npm test
```

#### Run Tests with Coverage
```powershell
npm test -- --coverage
```

#### Watch Mode (for development)
```powershell
npm run test:watch
```

### Test Structure

Each service has comprehensive tests covering:

1. **Health Endpoints**
   - Service health check
   - Response format validation
   - Timestamp verification

2. **API Endpoints**
   - All GET routes
   - Response data validation
   - Error handling

3. **CORS Configuration**
   - Cross-origin headers
   - Access control validation

4. **Error Handling**
   - 404 responses
   - Malformed requests
   - Service errors

### Coverage Thresholds

Minimum coverage requirements (enforced):
- **Branches**: 70%
- **Functions**: 80%
- **Lines**: 80%
- **Statements**: 80%

### Example Test Output
```
PASS  server.test.js
  Users Service API
    GET /health
      ✓ should return healthy status (25ms)
    GET /api/users
      ✓ should return all users (12ms)
    GET /api/users/:userId
      ✓ should return a specific user (8ms)
      ✓ should return undefined for non-existent user (6ms)

Test Suites: 1 passed, 1 total
Tests:       10 passed, 10 total
Coverage:    92.5% Statements | 85.7% Branches | 100% Functions | 92.3% Lines
```

## Linting

### ESLint Configuration

All services use StandardJS style guide with customizations:

```javascript
// .eslintrc.js
module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true
  },
  extends: ['standard'],
  rules: {
    'no-console': 'off',  // Allow console in Node.js
    'space-before-function-paren': ['error', 'never']
  }
}
```

### Running Linting

#### Check for Issues
```powershell
npm run lint
```

#### Auto-Fix Issues
```powershell
npm run lint:fix
```

### Common Linting Rules

- Consistent indentation (2 spaces)
- No unused variables
- Semicolons required
- Proper spacing around operators
- Consistent quote style (single quotes)

## Security Scanning

### npm Audit

Scans dependencies for known vulnerabilities:

```powershell
npm audit
```

#### Fix Vulnerabilities
```powershell
npm audit fix
```

#### Force Fix (use with caution)
```powershell
npm audit fix --force
```

### Trivy Container Scanning

Scans Docker images for vulnerabilities:

```powershell
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock `
  aquasec/trivy:latest image --severity HIGH,CRITICAL `
  your-image-name:latest
```

## CI/CD Integration

### Build Pipeline Stages

The CI pipeline (`buildspec.yml`) includes:

1. **Pre-Build**
   - Install dependencies (`npm ci`)
   - Login to ECR

2. **Build**
   - **Linting**: Run ESLint
   - **Testing**: Execute Jest tests with coverage
   - **Security Audit**: Run npm audit
   - **Build Image**: Create Docker image
   - **Image Scan**: Scan with Trivy

3. **Post-Build**
   - Push images to ECR
   - Generate deployment artifacts

### Pipeline Configuration

```yaml
build:
  commands:
    # Linting
    - echo Running ESLint...
    - npm run lint
    
    # Testing
    - echo Running tests with coverage...
    - npm test
    
    # Security
    - echo Running security audit...
    - npm audit --audit-level=moderate || true
    
    # Build
    - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
    
    # Image Scanning
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        aquasec/trivy:latest image --severity HIGH,CRITICAL \
        --exit-code 0 $IMAGE_REPO_NAME:$IMAGE_TAG || true
```

### Test Reports

CodeBuild generates test reports:

```yaml
reports:
  test_report:
    files:
      - 'users/coverage/lcov.info'
    file-format: 'CLOVERXML'
  coverage_report:
    files:
      - 'users/coverage/clover.xml'
    file-format: 'CLOVERXML'
```

## Best Practices

### Writing Tests

1. **Descriptive Test Names**
```javascript
it('should return a specific user when valid ID provided', async () => {
  // Test code
});
```

2. **Arrange-Act-Assert Pattern**
```javascript
it('should filter posts by user ID', async () => {
  // Arrange
  const userId = 1;
  
  // Act
  const response = await request(app).get(`/api/posts/by-user/${userId}`);
  
  // Assert
  expect(response.status).toBe(200);
  expect(response.body[0]).toHaveProperty('user', userId);
});
```

3. **Mock External Dependencies**
```javascript
jest.mock('./db.json', () => ({
  users: [/* test data */]
}), { virtual: true });
```

### Code Quality

1. **Keep Functions Small**: Single responsibility
2. **Use Descriptive Names**: Clear variable and function names
3. **Comment Complex Logic**: Explain why, not what
4. **Follow DRY**: Don't Repeat Yourself

### Security Best Practices

1. **Regular Dependency Updates**
```powershell
npm outdated
npm update
```

2. **Review Audit Results**
- Don't ignore security warnings
- Assess severity before ignoring
- Document exceptions

3. **Container Security**
- Use official base images
- Minimize image layers
- Don't run as root
- Regular image rebuilds

## Continuous Improvement

### Metrics to Track

- **Test Coverage**: Aim for > 80%
- **Build Success Rate**: Target > 95%
- **Security Vulnerabilities**: Zero high/critical
- **Linting Warnings**: Zero warnings in production

### Code Review Checklist

- [ ] All tests passing
- [ ] Coverage meets thresholds
- [ ] No linting errors
- [ ] No security vulnerabilities
- [ ] Code follows style guide
- [ ] Documentation updated

## Troubleshooting

### Tests Failing

1. **Check Node Version**
```powershell
node --version  # Should be >= 20.0.0
```

2. **Clear Cache**
```powershell
npm run test -- --clearCache
```

3. **Reinstall Dependencies**
```powershell
Remove-Item -Recurse -Force node_modules
npm install
```

### Linting Errors

1. **Auto-fix What You Can**
```powershell
npm run lint:fix
```

2. **Check ESLint Config**
- Verify `.eslintrc.js` exists
- Check rule configuration

3. **Editor Integration**
- Use ESLint plugin in VS Code
- Enable auto-fix on save

### Security Scan Issues

1. **False Positives**
- Review CVE details
- Check if vulnerability applies to your usage
- Document exceptions in `package.json`

2. **Update Dependencies**
```powershell
npm update
npm audit fix
```

3. **Breaking Changes**
- Check changelog before major updates
- Test thoroughly after updates
- Use lock files (`package-lock.json`)

## Resources

- [Jest Documentation](https://jestjs.io/)
- [Supertest Documentation](https://github.com/visionmedia/supertest)
- [ESLint Rules](https://eslint.org/docs/rules/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
