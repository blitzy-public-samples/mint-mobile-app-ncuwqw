# Mint Replica Lite Web Application

<!-- REQ: Cross-platform Development (1.1 System Overview/Client Applications) -->
A cross-platform financial management application built with React Native Web, enabling seamless user experience across web and mobile platforms.

## Prerequisites

<!-- REQ: Development Environment Setup (A.1 Development Environment Setup) -->
Before you begin, ensure you have the following installed:
- Node.js >= 16.0.0
- npm >= 8.0.0 or yarn >= 1.22.0
- TypeScript >= 5.0.4

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd src/web
```

2. Install dependencies:
```bash
npm install
# or
yarn install
```

3. Create a `.env` file in the project root and configure environment variables (see `.env.example` for reference).

## Development

<!-- REQ: Cross-platform Development (1.1 System Overview/Client Applications) -->
This project uses React Native Web v0.19.0 for cross-platform development.

### Available Scripts

```bash
# Start development server
npm start
# or
yarn start

# Create production build
npm run build
# or
yarn build

# Run tests
npm test
# or
yarn test

# Lint code
npm run lint
# or
yarn lint

# Format code
npm run format
# or
yarn format

# Type checking
npm run typecheck
# or
yarn typecheck

# Analyze bundle
npm run analyze
# or
yarn analyze
```

## Project Structure

<!-- REQ: Development Environment Setup (A.1 Development Environment Setup) -->
The project follows a modular architecture with TypeScript path aliases:

```
src/
├── assets/         # Static assets (images, fonts)
├── components/     # Reusable UI components
├── constants/      # Application constants
├── hooks/          # Custom React hooks
├── navigation/     # Navigation configuration
├── screens/        # Screen components
├── services/       # API and external services
├── store/          # Redux state management
├── styles/         # Global styles
└── utils/          # Utility functions
```

## Technology Stack

<!-- REQ: Cross-platform Development (1.1 System Overview/Client Applications) -->
- React Native Web ^0.19.0
- TypeScript ^5.0.4
- Redux Toolkit ^1.9.5
- React Router DOM ^6.11.0
- Axios ^1.4.0
- Chart.js ^4.3.0

## Testing

<!-- REQ: Code Quality Standards (A.2 Code Quality Standards) -->
The project uses Jest v29.5.0 with React Testing Library v14.0.0 for testing:

- Unit tests for components and utilities
- Integration tests for complex features
- Coverage threshold set to 80% for:
  - Branches
  - Functions
  - Lines
  - Statements

Run tests with coverage report:
```bash
npm test
# or
yarn test
```

## Code Quality

<!-- REQ: Code Quality Standards (A.2 Code Quality Standards) -->
The project maintains high code quality standards using:

### ESLint
- Extends recommended TypeScript and React configurations
- Enforces strict function return types
- Ensures proper React hooks usage

### Prettier
- Consistent code formatting
- Configured via `.prettierrc`
- Integrated with ESLint

## Architecture

The application follows a robust architecture:

### State Management
- Redux Toolkit for global state
- Redux Persist for state persistence
- Async Storage for local data

### Routing
- React Router DOM for navigation
- Protected routes for authenticated sections
- Deep linking support

### API Integration
- Axios for HTTP requests
- Interceptors for authentication
- Error handling middleware

## Deployment

### Production Build
1. Create production build:
```bash
npm run build
# or
yarn build
```

2. The build artifacts will be stored in the `dist/` directory.

### Deployment Configuration
- Optimized bundle size
- Tree-shaking enabled
- Modern browser support (see browserslist in package.json)

## Browser Support

### Production
- Browser market share > 0.2%
- No dead browsers
- No Opera Mini

### Development
- Latest Chrome version
- Latest Firefox version
- Latest Safari version

## Contributing

1. Follow TypeScript strict mode guidelines
2. Ensure all tests pass
3. Maintain code coverage thresholds
4. Follow ESLint and Prettier configurations
5. Use conventional commits

## Performance Optimization

- Code splitting with dynamic imports
- Asset optimization
- Bundle size monitoring
- Performance budgets

## Security

- Secure HTTP headers
- XSS protection
- CSRF prevention
- Secure cookie handling

## License

This project is private and confidential. See LICENSE file for details.