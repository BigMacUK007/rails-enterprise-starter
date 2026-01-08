# CLAUDE.md

Project guidance for Claude Code when working with this Rails 8 enterprise application.

## Overview

[Brief description of what this application does]

## Tech Stack

- **Framework**: Rails 8
- **Database**: PostgreSQL
- **Authentication**: Devise
- **Authorization**: Pundit
- **CSS**: Custom design tokens (OKLCH-based) in `app/assets/stylesheets/design-tokens.css`
- **JavaScript**: Hotwire (Turbo + Stimulus)
- **Soft Deletes**: Paranoia gem (`acts_as_paranoid`)
- **Pagination**: Kaminari
- **Charts**: Chartkick + Groupdate
- **Testing**: RSpec with FactoryBot

## Development Commands

```bash
# Setup
bin/rails db:setup              # Creates DB, runs migrations, seeds data

# Server
bin/rails server                # Start at http://localhost:3000

# Testing
bin/rspec                       # Run all tests
bin/rspec spec/models/          # Run model tests
bin/rspec spec/models/unit_spec.rb:25  # Run specific test line

# Linting & Security
bin/rubocop                     # Ruby style linting
bin/rubocop -a                  # Auto-fix style issues
bin/brakeman                    # Security vulnerability scan
```

## Test Credentials (Development)

- **Email**: admin@example.com
- **Password**: password123

## Architecture

### User Roles (Three-Tier)

- `user` (0): View-only access
- `manager` (1): Can edit records
- `admin` (2): Full access including user management

### Key Patterns

**Auditable Concern** (`app/models/concerns/auditable.rb`)
- Include in models for automatic audit logging
- Uses `Current` attributes for user/IP tracking
- Creates `AuditLog` records on create/update/destroy

**Pundit Authorization** (`app/policies/`)
- All controllers include `Pundit::Authorization`
- Each model has corresponding policy

**Soft Deletes**
- Models use `acts_as_paranoid` for soft deletion
- Records have `deleted_at` column
- Use `.with_deleted` or `.only_deleted` scopes when needed

## Design System

### Status Colors (OKLCH)
- **Positive (Green)**: Valid, success, compliant
- **Warning (Amber)**: Expiring soon, needs attention
- **Negative (Red)**: Expired, error, critical

### UI Components
- Metric cards with status coloring
- Sortable data tables with status row highlighting
- Status badges (positive/warning/negative)
- Progress bars with threshold colors
- Filter bars with date range and dropdowns

## Git Workflow

- Use feature branches: `feature/xxx`, `fix/xxx`
- Run `bin/rubocop` and `bin/brakeman` before PR
- Commit with meaningful messages

## Deployment

[Add deployment details for your specific setup]
