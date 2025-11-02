# License Management System

A modern Ruby on Rails application for managing software licenses across multiple accounts, users, and products. This system enables administrators to create accounts, manage subscriptions, and assign product licenses to users with proper validation and tracking.

## Overview

This is my solution to building the vLex License Management System. The application provides a complete license management solution that accommodates multiple users with different permissions, subscriptions, and comprehensive state management and validation. See [TASK.md](TASK.md) for full project requirements.

### Key Features

- **Account Management**: Create and manage multiple accounts with associated users and subscriptions
- **User Management**: Add users to accounts with email uniqueness validation
- **Product Catalog**: Maintain a catalog of products available for licensing
- **Subscription Tracking**: Manage subscriptions with license counts and expiration dates
- **License Assignment**: Assign and unassign licenses to users with availability validation
- **Bulk Operations**: Assign multiple licenses to multiple users in a single operation
- **Validation Rules**: Prevent duplicate license assignments and over-allocation of licenses

## Tech Stack

- **Framework**: Rails 8.0.3
- **Language**: Ruby 3.3.4
- **Database**: MySQL 9.0.1
- **Frontend**: Hotwire (Turbo & Stimulus) + Tailwind CSS
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache

### Architecture

- Skinny controllers with business logic in models
- Concerns for shared behavior when needed
- Direct JSON rendering without serializers
- Tailwind CSS for rapid UI development

## Prerequisites

- Ruby 3.3.4 or higher
- Rails 8.0.3 or higher
- MySQL 9.0.1 or higher

## Getting Started

```bash
# Clone and setup
git clone <repository-url>
cd license_management_system
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start the server
bin/dev
```

The application will be available at `http://localhost:3000`

## Testing

This application emphasizes testing where it provides the most value:

**Model Tests**: Comprehensive coverage of validations, associations, business logic, and edge cases  
**Controller Tests**: HTTP behavior, CRUD operations, and error handling  
**Smoke Test**: Single system test to verify the application loads and navigation works  
**Manual Verification**: UI/UX testing with seed data for the best confidence in user experience

System tests are intentionally minimal (one smoke test), as they tend to be brittle and provide less value than targeted unit tests combined with human verification.

```bash
# Run all tests (22 unit/integration tests + 1 smoke test)
bin/rails test
bin/rails test:system

# Seed data for manual testing
bin/rails db:seed
```

### Test Coverage

- ✅ Account model: validations, associations, dependent destroy
- ✅ User model: validations (name, email uniqueness, format), associations
- ✅ Product model: validations, associations
- ✅ Subscription model: validations, business logic (expired?, available_licenses), scopes
- ✅ LicenseAssignment model: complex validations, bulk operations
- ✅ All controllers: CRUD operations, error handling, redirects

## Code Quality

```bash
# Run RuboCop for style checks
bin/rubocop
```

## User Stories

The application implements the following user stories:

1. **Adding an Account**: Administrators can create accounts to manage users and subscriptions
2. **Adding a Product**: Administrators can add products to the system catalog
3. **Adding a User**: Administrators can add users to accounts with email validation
4. **Creating Subscriptions**: Administrators can subscribe accounts to products with license limits
5. **Assigning Licenses**: Administrators can assign product licenses to users with availability checks
