# Test Quality Patterns

Comprehensive patterns for frontend, backend, and E2E testing.

## Frontend Unit Tests

### Test Structure

```typescript
describe('ModuleName', () => {
  describe('functionName', () => {
    it('should do X when Y', () => {
      // Arrange
      const input = 'test';
      
      // Act
      const result = functionName(input);
      
      // Assert
      expect(result).toBe(expected);
    });
  });
});
```

### Mock Hierarchy

From most to least preferred:

1. **Real service with test data** (integration)
2. **vi.mock at module level** (unit)
3. **vi.fn for individual functions** (unit)
4. **vi.spyOn for method tracking** (unit)

```typescript
// Level 1: Integration (preferred for E2E)
const service = new UserService(testFetcher);

// Level 2: Module mock (most common)
vi.mock('../service', () => ({
  fetchUsers: vi.fn(),
  createUser: vi.fn()
}));

// Level 3: Function mock
const mockFetch = vi.fn();
vi.mock('../api', () => ({ fetch: mockFetch }));

// Level 4: Spy
vi.spyOn(service, 'fetchUsers').mockResolvedValue([mockUser]);
```

### React Testing Library

#### Query Priority

Use queries in order of accessibility:

1. `getByRole` - Most accessible
2. `getByLabelText` - Form elements
3. `getByPlaceholderText` - Inputs
4. `getByText` - Text content
5. `getByDisplayValue` - Form values
6. `getByTestId` - Last resort

```typescript
// ❌ Wrong - Using test-id
fireEvent.click(screen.getByTestId('submit-button'));

// ✅ Correct - Use accessible queries
fireEvent.click(screen.getByRole('button', { name: /submit/i }));
```

#### userEvent vs fireEvent

Prefer `userEvent` for realistic interactions:

```typescript
// ❌ Wrong - fireEvent doesn't simulate real behavior
fireEvent.change(input, { target: { value: 'test' } });

// ✅ Correct - userEvent simulates real events
import userEvent from '@testing-library/user-event';

await userEvent.type(input, 'test');
await userEvent.click(button);
```

#### Async Queries

```typescript
// Use findBy for async elements
await screen.findByText('Loaded');

// Or waitFor for assertions
await waitFor(() => {
  expect(screen.getByText('Loaded')).toBeInTheDocument();
});
```

### Testing React Hooks

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from 'react-query';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } }
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useUsers', () => {
  it('returns users after fetch', async () => {
    const { result } = renderHook(() => useUsers(), {
      wrapper: createWrapper()
    });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data).toEqual([mockUser]);
  });
});
```

## Playwright E2E Patterns

### Page Object Model

```typescript
// pages/billboard.page.ts
export class BillboardPage {
  readonly page: Page;
  readonly createButton: Locator;
  readonly nameInput: Locator;

  constructor(page: Page) {
    this.page = page;
    this.createButton = page.getByRole('button', { name: /create/i });
    this.nameInput = page.getByLabel(/billboard name/i);
  }

  async goto() {
    await this.page.goto('/billboard');
  }

  async create(name: string) {
    await this.createButton.click();
    await this.nameInput.fill(name);
    await this.page.getByRole('button', { name: /save/i }).click();
  }
}

// tests/billboard.spec.ts
test('creates billboard', async ({ page }) => {
  const billboardPage = new BillboardPage(page);
  await billboardPage.goto();
  await billboardPage.create('Test Billboard');
  
  await expect(page.getByText('Created successfully')).toBeVisible();
});
```

### Auth Setup

```typescript
// auth.setup.ts
test('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name="email"]', process.env.E2E_EMAIL!);
  await page.fill('[name="password"]', process.env.E2E_PASSWORD!);
  await page.click('button[type="submit"]');
  
  await page.context().storageState({ path: 'auth.json' });
});

// playwright.config.ts
export default defineConfig({
  projects: [
    { name: 'setup', testMatch: /auth\.setup\.ts/ },
    {
      name: 'chromium',
      use: { storageState: 'auth.json' },
      dependencies: ['setup']
    }
  ]
});
```

### API Testing

```typescript
test('GET /api/users returns list', async ({ request }) => {
  const response = await request.get('/api/users');
  expect(response.status()).toBe(200);
  
  const body = await response.json();
  expect(body.data).toBeInstanceOf(Array);
  expect(body.data.length).toBeGreaterThan(0);
});

test('POST /api/users creates user', async ({ request }) => {
  const response = await request.post('/api/users', {
    data: { name: 'John', email: 'john@example.com' }
  });
  expect(response.status()).toBe(201);
  
  const body = await response.json();
  expect(body.data.name).toBe('John');
});
```

## Backend Testing Patterns

### Database Testing

#### Setup/Teardown

```typescript
beforeAll(async () => {
  await db.connect();
});

afterAll(async () => {
  await db.disconnect();
});

beforeEach(async () => {
  await db.clear();
});
```

#### Transaction Rollback

```typescript
describe('UserService', () => {
  let transaction;

  beforeEach(async () => {
    transaction = await db.beginTransaction();
  });

  afterEach(async () => {
    await transaction.rollback();
  });

  it('creates user within transaction', async () => {
    const user = await UserService.create({ name: 'John' }, transaction);
    expect(user.id).toBeDefined();
  });
});
```

#### Test Factories

```typescript
// factories/user.factory.ts
export function createUser(overrides?: Partial<User>): User {
  return {
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
    status: 'active',
    createdAt: new Date(),
    ...overrides
  };
}

// Usage
const mockUser = createUser({ status: 'inactive' });
const mockAdmin = createUser({ role: 'admin' });
```

### Service Layer Testing

```typescript
describe('UserService', () => {
  let userService: UserService;
  let mockRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockRepository = {
      findById: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      delete: vi.fn()
    };
    userService = new UserService(mockRepository);
  });

  describe('create', () => {
    it('creates user with valid data', async () => {
      mockRepository.create.mockResolvedValue(createUser());
      
      const result = await userService.create({ name: 'John' });
      
      expect(result.isOk).toBe(true);
      expect(result.data?.name).toBe('John');
    });

    it('returns error when email exists', async () => {
      mockRepository.findByEmail.mockResolvedValue(createUser());
      
      const result = await userService.create({ 
        name: 'John', 
        email: 'existing@example.com' 
      });
      
      expect(result.isOk).toBe(false);
      expect(result.error?.message).toContain('already exists');
    });
  });
});
```

### Mocking External Services

```typescript
// Mock HTTP client
vi.mock('../http-client', () => ({
  httpClient: {
    get: vi.fn(),
    post: vi.fn()
  }
}));

// Mock email service
vi.mock('../email-service', () => ({
  EmailService: vi.fn().mockImplementation(() => ({
    send: vi.fn().mockResolvedValue({ success: true })
  }))
}));

// Use in test
it('sends welcome email after registration', async () => {
  const mockSend = vi.fn().mockResolvedValue({ success: true });
  vi.mocked(EmailService).mockImplementation(() => ({
    send: mockSend
  } as any));

  await userService.register({ email: 'test@example.com' });
  
  expect(mockSend).toHaveBeenCalledWith(
    expect.objectContaining({ to: 'test@example.com' })
  );
});
```

### Controller Testing

```typescript
describe('UserController', () => {
  describe('index', () => {
    it('returns paginated users', async () => {
      const req = mockRequest({ query: { page: '1', limit: '10' } });
      const res = mockResponse();

      await controller.index(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.any(Array),
          meta: expect.objectContaining({ page: 1, limit: 10 })
        })
      );
    });
  });
});

// Mock helpers
function mockRequest(overrides?: Partial<Request>): Request {
  return { ...overrides } as Request;
}

function mockResponse(): Response {
  const res: any = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  return res;
}
```

### Integration Testing

```typescript
describe('UserController (integration)', () => {
  let app: Application;
  let db: Database;

  beforeAll(async () => {
    db = await setupTestDatabase();
    app = createApp(db);
  });

  afterAll(async () => {
    await db.close();
  });

  beforeEach(async () => {
    await db.seed(testData);
  });

  it('GET /users/:id returns user', async () => {
    const response = await request(app).get('/users/1');
    
    expect(response.status).toBe(200);
    expect(response.body.data.id).toBe('1');
  });
});
```

## Test Isolation

### Reset Between Tests

```typescript
beforeEach(() => {
  vi.clearAllMocks();
  vi.resetModules();
});

afterEach(() => {
  vi.restoreAllMocks();
});
```

### Avoid Shared State

```typescript
// ❌ Wrong - Shared mutable state
let user: User;
beforeEach(() => { user = createMockUser(); });

// ✅ Correct - Fresh state per test
beforeEach(() => {
  vi.clearAllMocks();
});

it('test A', () => {
  const user = createMockUser();  // Local scope
});
```

### Database Cleanup

```typescript
afterAll(async () => {
  await db.cleanup();
  await server.close();
});
```
