# Rails 8 Enterprise Starter

A production-ready Rails 8 boilerplate with enterprise-grade design patterns, extracted from Ben's SSP Compliance Tracker.

## Features

- **OKLCH Design System** - Perceptually uniform, WCAG accessible colors
- **Three-Tier Authorization** - User → Manager → Admin role system
- **Audit Logging** - Automatic tracking of data changes
- **Activity Tracking** - User behavior monitoring
- **Dark-First Theme** - Professional dark mode with light mode support
- **Responsive Dashboard** - Data tables, metrics, status badges

## Stack

| Category | Technology |
|----------|------------|
| Framework | Rails 8 |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus) |
| Authentication | Devise |
| Authorization | Pundit |
| Soft Deletes | Paranoia |
| Pagination | Kaminari |
| Charts | Chartkick + Groupdate |
| Testing | RSpec + FactoryBot + Shoulda Matchers |
| Linting | RuboCop Omakase |
| Security | Brakeman |

## Quick Start

### Option 1: Use as Template

```bash
# Clone the template
gh repo clone benmacdonald/rails-enterprise-starter my-app
cd my-app

# Remove template git history and start fresh
rm -rf .git
git init

# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start server
bin/rails server
```

### Option 2: Create Fresh Rails App with This Structure

```bash
# Create new Rails app
rails new my-app -d postgresql --css=propshaft

cd my-app

# Copy design system files
cp -r path/to/rails-enterprise-starter/app/assets/stylesheets/* app/assets/stylesheets/
cp -r path/to/rails-enterprise-starter/app/models/concerns/* app/models/concerns/
cp -r path/to/rails-enterprise-starter/app/controllers/concerns/* app/controllers/concerns/

# Install gems
bundle add devise pundit paranoia kaminari chartkick groupdate
bundle add rspec-rails factory_bot_rails shoulda-matchers --group development,test
bundle add rubocop-rails-omakase brakeman --group development

# Setup
rails generate devise:install
rails generate pundit:install
rails generate rspec:install
```

## Project Structure

```
app/
├── assets/stylesheets/
│   ├── design-tokens.css      # OKLCH colors, typography, spacing
│   └── application.css        # Component styles
├── controllers/
│   ├── application_controller.rb
│   └── concerns/
│       └── activity_tracking.rb
├── models/
│   ├── concerns/
│   │   └── auditable.rb
│   └── current.rb
├── policies/
│   └── application_policy.rb
├── helpers/
│   └── application_helper.rb  # sortable_header, status_badge helpers
└── javascript/controllers/
    ├── mobile_nav_controller.js
    └── theme_switcher_controller.js
```

## Design System

### Color Palette (OKLCH)

```css
/* Status Colors */
--color-positive: oklch(55% 0.18 145);   /* Green - Valid/Success */
--color-warning: oklch(70% 0.2 75);      /* Amber - Attention */
--color-negative: oklch(58% 0.24 25);    /* Red - Error/Critical */
--color-info: oklch(60% 0.17 250);       /* Blue - Informational */

/* Canvas (Dark Theme) */
--color-canvas: oklch(15% 0.02 250);     /* Background */
--color-ink: oklch(95% 0.005 250);       /* Primary text */
```

### Typography Scale

```css
--text-sm: clamp(0.8125rem, 0.775rem + 0.2vw, 0.875rem);
--text-base: clamp(0.9375rem, 0.9rem + 0.2vw, 1rem);
--text-lg: clamp(1.25rem, 1.15rem + 0.5vw, 1.375rem);
--text-2xl: clamp(1.875rem, 1.65rem + 1.1vw, 2.25rem);
```

### Components Included

- **Metric Cards** - KPI displays with status coloring
- **Data Tables** - Sortable, filterable, status-highlighted rows
- **Status Badges** - Positive/Warning/Negative indicators
- **Progress Bars** - Compliance percentages with thresholds
- **Filter Bars** - Date range, dropdown filters
- **Alert Banners** - Notifications with status variants
- **Buttons** - Primary, ghost, positive, negative variants
- **Cards** - Elevated, status-colored containers
- **Inputs** - Text, select, textarea with error states
- **Navigation** - Responsive header with mobile menu

## Authorization Pattern

Three-tier role system:

```ruby
# User model
enum :role, { user: 0, manager: 1, admin: 2 }

def manager_or_above?
  manager? || admin?
end
```

Policy example:
```ruby
class RecordPolicy < ApplicationPolicy
  def index?; true; end                    # All users
  def show?; true; end                     # All users
  def create?; user.admin?; end            # Admin only
  def update?; user.manager_or_above?; end # Manager+
  def destroy?; user.admin?; end           # Admin only
end
```

## Audit Logging

Include in any model:

```ruby
class MyModel < ApplicationRecord
  include Auditable
end
```

This automatically logs:
- Create events
- Update events (with changed attributes)
- Destroy events
- User who made the change
- IP address

## Commands

```bash
# Development
bin/rails server                # Start at localhost:3000
bin/rails console               # Rails console

# Testing
bin/rspec                       # Run all tests
bin/rspec spec/models/          # Model tests only

# Linting & Security
bin/rubocop                     # Style check
bin/rubocop -a                  # Auto-fix
bin/brakeman                    # Security scan

# Database
bin/rails db:migrate            # Run migrations
bin/rails db:seed               # Seed data
```

## Test Credentials (Development)

- **Email**: admin@example.com
- **Password**: password123

## Deployment

Designed for Google Cloud Run:

```bash
gcloud run deploy my-app \
  --region=europe-west2 \
  --source=. \
  --allow-unauthenticated
```

See `DEPLOYMENT.md` for full deployment guide.

## Related Skills

- `enterprise-dashboard` - Claude Code skill for dashboard styling
- `ruby-on-rails-expert` - Rails patterns and best practices
- `37signals-design` - Form components and inputs

## License

MIT License - Use freely for your projects.
