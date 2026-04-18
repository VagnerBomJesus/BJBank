# Firebase Best Practices for BJBank

**Reference**: [Firebase General Best Practices](https://firebase.google.com/docs/projects/dev-workflows/general-best-practices)

---

## 1. Project Hierarchy Strategy

### 1.1 Separate Projects by Environment

BJBank uses **separate Firebase projects** for each development environment:

```
Development Environment:     bjbank-dev
Staging Environment:         bjbank-staging
Production Environment:      bjbank-prod
```

**Rationale**:
- Isolate development data from production
- Prevent test data from contaminating real user data
- Enable different security rules per environment
- Allow independent scaling and configuration

### 1.2 Platform Variants in Same Project

Register platform variants of the same application in one project:

```
bjbank-prod/
├── Android App (com.bjbank.app)
├── iOS App (com.bjbank.app)
└── Web App (bjbank.web.app)
```

**Reason**: These represent the same end-user product and should share:
- Firestore database
- Authentication users
- Cloud Messaging infrastructure
- Storage buckets

### 1.3 Build Variants in Separate Projects

Debug and production builds use separate projects:

```
bjbank-dev/
├── Debug APK (development testing)
├── Debug IPA (development testing)
└── Development Web (localhost testing)

bjbank-prod/
├── Release APK (production deployment)
├── Release IPA (production deployment)
└── Web App (production deployment)
```

**Benefit**: Prevents development testing data from affecting production database

---

## 2. Project Configuration

### 2.1 Development Project (bjbank-dev)

**Purpose**: Local development and testing

**Configuration**:
```
Authentication:
  - Email/Password: Enabled
  - Anonymous: Enabled (for testing)
  - Phone Auth: Disabled (expensive)

Firestore:
  - Security Rules: Development mode (allow all)
  - Backups: Daily
  - Data retention: 30 days

Cloud Messaging:
  - Testing keys allowed
  - No production restrictions

Storage:
  - Public access for development
  - Automatic cleanup enabled
```

**Key Settings**:
```
flutterfire configure --platforms=android,ios --project=bjbank-dev
```

### 2.2 Staging Project (bjbank-staging)

**Purpose**: Pre-production testing and validation

**Configuration**:
```
Authentication:
  - Email/Password: Enabled
  - Anonymous: Disabled (production-like)
  - Phone Auth: Enabled (test at scale)

Firestore:
  - Security Rules: Staging rules (similar to production)
  - Backups: Daily
  - Data retention: 7 days

Cloud Messaging:
  - Production credentials
  - Real APNs certificates

Storage:
  - Restricted access (production-like)
  - Automatic cleanup enabled
```

**Key Settings**:
```
flutterfire configure --platforms=android,ios --project=bjbank-staging
```

### 2.3 Production Project (bjbank-prod)

**Purpose**: Real user production environment

**Configuration**:
```
Authentication:
  - Email/Password: Enabled
  - Anonymous: Disabled
  - Phone Auth: Enabled
  - 2FA: Enabled

Firestore:
  - Security Rules: Strict production rules
  - Backups: Hourly + daily
  - Data retention: Unlimited
  - Monitoring: Enabled

Cloud Messaging:
  - Production APNs certificates
  - Android release credentials
  - No testing/development keys

Storage:
  - Restricted access
  - Encrypted at rest
  - Audit logging enabled
```

**Key Settings**:
```
flutterfire configure --platforms=android,ios --project=bjbank-prod
```

---

## 3. Firestore Database Structure

### 3.1 Database Design Principles

**Separate Databases by Environment**:
- `default` database in dev/staging (testing)
- `default` database in prod (production data)

**Collections Organization**:
```
bjbank-prod/Firestore/
├── users/                  # User profiles
├── accounts/              # Bank accounts
├── transactions/          # Transaction history
├── cards/                 # Card management
├── transfers/             # Transfer records
├── bills/                 # Bill management
├── loans/                 # Loan data
├── investments/           # Investment portfolio
├── savings_goals/         # Savings goals
├── budgets/              # Budget tracking
├── notifications/         # Push notification history
└── audit_logs/           # Security audit trail
```

### 3.2 Security Rules Structure

**Development Rules** (bjbank-dev):
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all for development
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Production Rules** (bjbank-prod):
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User authentication required
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    match /accounts/{accountId} {
      allow read: if resource.data.userId == request.auth.uid;
      allow write: if resource.data.userId == request.auth.uid;
    }

    // Additional security rules...
  }
}
```

---

## 4. Authentication Strategy

### 4.1 Multi-Factor Authentication

**Production Requirement**:
```
User Authentication Flow:
1. Email/Password (primary)
2. PIN verification (mobile)
3. Biometric (optional but recommended)
4. 2FA for sensitive operations
```

**Firebase Configuration**:
```dart
// Enable multi-factor authentication
final session = await auth.verifyPhoneNumber(
  phoneNumber: '+351912345678',
  verificationCompleted: (PhoneAuthCredential credential) {
    auth.signInWithCredential(credential);
  },
);
```

### 4.2 Session Management

**Development**: 24-hour session timeout

**Staging**: 2-hour session timeout

**Production**: 15-minute idle timeout + re-authentication

```dart
// Configure session timeout
const sessionTimeout = Duration(minutes: 15);
const idleTimeout = Duration(minutes: 10);
```

### 4.3 Credential Storage

**Secure Storage Requirements**:
- Never store raw passwords
- Use Firebase Authentication tokens
- Store sensitive data encrypted
- Implement PIN hashing

---

## 5. Cloud Messaging Configuration

### 5.1 FCM Setup by Environment

**Development**:
- Test device registration
- Development APNs certificates
- Unlimited message quota

**Staging**:
- Production APNs certificates
- Test message delivery
- Monitor message rates

**Production**:
- Production credentials only
- Real user device registration
- Rate limiting enabled
- Error tracking enabled

### 5.2 Topic-Based Messaging

**Topics Structure**:
```
topic: users_{userId}              # User-specific notifications
topic: transactions               # Transaction alerts
topic: security                   # Security alerts
topic: promotions                 # Marketing messages
```

**Production Rules**:
- Subscriptions require authentication
- Validate user ownership
- Log all message delivery
- Implement unsubscribe mechanism

---

## 6. Storage Configuration

### 6.1 Security Rules

**Development**:
```firebase
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

**Production**:
```firebase
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth.uid == userId;
    }
    match /public/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

### 6.2 File Organization

```
Storage Buckets/
├── bjbank-dev.appspot.com/
│   └── development files
├── bjbank-staging.appspot.com/
│   └── staging files
└── bjbank-prod.appspot.com/
    ├── users/{userId}/documents
    ├── users/{userId}/receipts
    ├── users/{userId}/statements
    └── public/static
```

---

## 7. Monitoring & Analytics

### 7.1 Environment-Specific Metrics

**Development**:
- Track feature usage
- Monitor crash reports
- Debug event logging

**Staging**:
- Performance testing
- Load testing metrics
- Error tracking

**Production**:
- User engagement metrics
- Performance monitoring
- Real-time alerts
- Custom events:
  - Login/logout events
  - Transaction completed
  - Error occurrences
  - Security events

### 7.2 Data Collection

```dart
// Custom event tracking
analytics.logEvent(
  name: 'transaction_completed',
  parameters: {
    'amount': amount,
    'type': 'transfer',
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

---

## 8. Cost Optimization

### 8.1 Development Environment

**Cost Control**:
- Limit daily API calls
- Use Firestore emulator locally
- Batch database reads/writes
- Disable unused services

**Configuration**:
```
Cloud Firestore:
  - One GB free storage
  - 50,000 reads/day free
  - Monitoring: Disabled

Cloud Messaging:
  - Unlimited for testing
```

### 8.2 Production Environment

**Optimization Strategies**:
- Use collection groups efficiently
- Batch write operations
- Implement caching
- Monitor quota usage
- Set budget alerts

**Billing Alerts**:
```
Firebase Console:
- Budget: $1000/month
- Alert threshold: 80% of budget
- Notifications: Email alerts
```

---

## 9. Security Checklist

### 9.1 Pre-Deployment

- [ ] Separate projects configured (dev/staging/prod)
- [ ] Security rules reviewed and tested
- [ ] Authentication multi-factor enabled
- [ ] Storage rules restrictive
- [ ] Firestore backups enabled
- [ ] Monitoring alerts configured
- [ ] API keys restricted
- [ ] Service accounts with minimal permissions

### 9.2 Post-Deployment

- [ ] Monitor error rates daily
- [ ] Review security rules quarterly
- [ ] Audit access logs weekly
- [ ] Update APNs certificates (annually)
- [ ] Review active sessions
- [ ] Monitor unusual activity
- [ ] Update authentication methods
- [ ] Backup verification

---

## 10. Migration Between Environments

### 10.1 Dev → Staging

**Process**:
```bash
# Export dev data
gsutil -m cp -r gs://bjbank-dev.appspot.com/backups/ ./

# Import to staging
gsutil -m cp -r ./ gs://bjbank-staging.appspot.com/backups/

# Verify data integrity
# Test in staging environment
```

**Validation**:
- [ ] User count matches
- [ ] Account balance totals match
- [ ] No data corruption
- [ ] All collections present

### 10.2 Staging → Production

**Deployment Checklist**:
- [ ] Final testing completed
- [ ] Performance validated
- [ ] Security audit passed
- [ ] Backup created
- [ ] Rollback plan ready
- [ ] Monitoring alerts active
- [ ] Team notified
- [ ] Gradual rollout configured

---

## 11. Maintenance & Updates

### 11.1 Regular Tasks

**Daily**:
- Monitor error logs
- Check security alerts
- Review transaction volume

**Weekly**:
- Audit access logs
- Review user feedback
- Check quota usage

**Monthly**:
- Security rules review
- Performance analysis
- Cost optimization
- Backup verification

**Quarterly**:
- Full security audit
- Dependency updates
- APNs certificate check
- Firebase SDK updates

### 11.2 Emergency Procedures

**Database Issues**:
- Restore from hourly backup
- Verify data integrity
- Notify affected users
- Post-mortem analysis

**Security Breach**:
- Disable compromised accounts
- Force password reset
- Review audit logs
- Notify security team

**Performance Degradation**:
- Scale resources
- Optimize queries
- Clear caches
- Implement rate limiting

---

## 12. Reference Links

- [Firebase General Best Practices](https://firebase.google.com/docs/projects/dev-workflows/general-best-practices)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Cloud Messaging Setup](https://firebase.google.com/docs/cloud-messaging)
- [Storage Security Rules](https://firebase.google.com/docs/storage/security)
- [Firebase Pricing Calculator](https://firebase.google.com/pricing/calculator)

---

**Last Updated**: 18 April 2026
**Status**: Production Ready
**Version**: 1.0

This guide implements Firebase best practices specific to BJBank's banking application architecture and security requirements.
