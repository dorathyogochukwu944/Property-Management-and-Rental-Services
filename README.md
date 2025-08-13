# Property Management and Rental Services

A comprehensive blockchain-based property management system built with Clarity smart contracts for the Stacks blockchain. This system automates rent collection, lease management, security deposits, maintenance requests, and provides transparent tenant screening.

## System Overview

The property management system consists of five interconnected smart contracts:

1. **Property Registry** - Manages property listings, ownership, and basic information
2. **Lease Management** - Handles rental agreements, lease terms, and contract lifecycle
3. **Rent Collection** - Automates rent payments, late fees, and payment tracking
4. **Maintenance Requests** - Manages property maintenance requests and work orders
5. **Tenant Screening** - Handles tenant applications, references, and approval process

## Key Features

### 🏠 Property Management
- Register and manage multiple properties
- Track property details, ownership, and availability
- Set rental rates and property specifications
- Property portfolio management for investors

### 📋 Lease Management
- Create and manage rental agreements
- Define lease terms, duration, and conditions
- Automatic lease renewal and termination
- Digital lease signing and storage

### 💰 Rent Collection
- Automated monthly rent collection
- Late fee calculation and enforcement
- Payment history tracking
- Security deposit management

### 🔧 Maintenance Requests
- Tenant maintenance request submission
- Work order creation and tracking
- Contractor assignment and payment
- Maintenance history and costs

### 👥 Tenant Screening
- Digital tenant application process
- Reference verification system
- Credit and background check integration
- Transparent approval/rejection process

## Contract Architecture

### Data Structures

**Property**
- Property ID (unique identifier)
- Owner principal
- Address and description
- Rental rate and deposit amount
- Availability status
- Property specifications

**Lease**
- Lease ID (unique identifier)
- Property ID reference
- Tenant principal
- Lease terms (start date, duration, rent amount)
- Security deposit amount
- Lease status (active, terminated, expired)

**Rent Payment**
- Payment ID
- Lease ID reference
- Amount and due date
- Payment status and late fees
- Payment history

**Maintenance Request**
- Request ID
- Property ID reference
- Tenant principal
- Description and priority level
- Status and assigned contractor
- Cost and completion date

**Tenant Application**
- Application ID
- Applicant principal
- Property ID reference
- Application details and references
- Screening status and results

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

3. Run tests:
   \`\`\`bash
   npm test
   \`\`\`

4. Deploy contracts:
   \`\`\`bash
   clarinet deploy
   \`\`\`

### Usage Examples

#### Register a Property
\`\`\`clarity
(contract-call? .property-registry register-property
"123 Main St, City, State"
"2-bedroom apartment"
u1200
u2400)
\`\`\`

#### Create a Lease
\`\`\`clarity
(contract-call? .lease-management create-lease
u1
'ST1TENANT...
u12
u1200
u2400)
\`\`\`

#### Submit Maintenance Request
\`\`\`clarity
(contract-call? .maintenance-requests submit-request
u1
"Leaky faucet in kitchen"
u2)
\`\`\`

## Security Features

- Multi-signature support for high-value transactions
- Role-based access control (property owners, tenants, managers)
- Automated escrow for security deposits
- Transparent payment and maintenance history
- Immutable lease agreements and payment records

## Testing

The system includes comprehensive tests covering:
- Property registration and management
- Lease creation and lifecycle
- Rent payment processing
- Maintenance request workflow
- Tenant screening process
- Error handling and edge cases

Run the test suite:
\`\`\`bash
npm test
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

MIT License - see LICENSE file for details
