/**
 * INSECURE API DEMO - FOR EDUCATIONAL PURPOSES ONLY
 *
 * This code intentionally contains security vulnerabilities to demonstrate
 * common API security pitfalls. DO NOT use in production.
 *
 * Vulnerabilities demonstrated:
 * 1. SQL Injection
 * 2. Missing authentication/authorization
 * 3. Sensitive data exposure
 * 4. Mass assignment
 * 5. Broken access control
 * 6. Insecure direct object references (IDOR)
 */

// Mock database - in reality, this would be a real database
const mockDatabase = {
  users: [
    {
      id: '1',
      username: 'admin',
      password: 'admin123', // VULNERABILITY: Plain text password
      email: 'admin@example.com',
      isAdmin: true,
      ssn: '123-45-6789', // VULNERABILITY: Sensitive data
      creditCard: '4532-1111-2222-3333', // VULNERABILITY: PII exposure
      createdAt: new Date().toISOString()
    },
    {
      id: '2',
      username: 'john_doe',
      password: 'password123', // VULNERABILITY: Plain text password
      email: 'john@example.com',
      isAdmin: false,
      ssn: '987-65-4321',
      creditCard: '5425-2333-4444-5555',
      createdAt: new Date().toISOString()
    },
    {
      id: '3',
      username: 'jane_smith',
      password: 'qwerty', // VULNERABILITY: Plain text password
      email: 'jane@example.com',
      isAdmin: false,
      ssn: '555-12-3456',
      creditCard: '3782-8224-6310-0005',
      createdAt: new Date().toISOString()
    }
  ],
  config: {
    databaseUrl: 'postgresql://admin:secret123@db.example.com:5432/proddb',
    apiKeys: {
      stripeKey: 'sk_live_51HxXXXXXXXXXXXXXXXXXXXX',
      awsAccessKey: 'AKIAIOSFODNN7EXAMPLE',
      awsSecretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    },
    secrets: {
      jwtSecret: 'super-secret-key-12345',
      encryptionKey: 'AES256-SECRET-KEY'
    }
  }
};

// CORS headers - overly permissive (VULNERABILITY)
const corsHeaders = {
  'Access-Control-Allow-Origin': '*', // VULNERABILITY: Allows any origin
  'Access-Control-Allow-Headers': '*',
  'Access-Control-Allow-Methods': '*'
};

/**
 * Main Lambda handler
 * Supports both API Gateway v1 (REST API) and v2 (HTTP API) payload formats
 */
exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  // Detect payload format version and normalize event
  const isV2 = event.version === '2.0' || event.requestContext?.http;

  // Normalize event structure for v2 format
  let path = isV2 ? event.rawPath : event.path;
  const method = isV2 ? event.requestContext.http.method : event.httpMethod;
  const queryStringParameters = isV2 ? event.queryStringParameters : event.queryStringParameters;
  const body = event.body;

  // Strip stage name from path if present (e.g., /dev/users -> /users)
  if (isV2 && event.requestContext?.stage) {
    const stage = event.requestContext.stage;
    if (path.startsWith(`/${stage}/`)) {
      path = path.substring(stage.length + 1);
    }
  }

  // Handle CORS preflight
  if (method === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: ''
    };
  }

  try {
    // Create normalized event object for handlers
    const normalizedEvent = {
      path,
      httpMethod: method,
      queryStringParameters,
      body
    };

    // Route to appropriate handler
    if (path === '/users' && method === 'GET') {
      return await listUsers(normalizedEvent);
    } else if (path === '/users' && method === 'POST') {
      return await createUser(normalizedEvent);
    } else if (path.match(/^\/users\/[^/]+$/) && method === 'GET') {
      return await getUserById(normalizedEvent);
    } else if (path.match(/^\/users\/[^/]+$/) && method === 'PUT') {
      return await updateUser(normalizedEvent);
    } else if (path === '/search' && method === 'GET') {
      return await searchUsers(normalizedEvent);
    } else if (path === '/admin/config' && method === 'GET') {
      return await getConfig(normalizedEvent);
    } else if (path === '/data/export' && method === 'POST') {
      return await exportData(normalizedEvent);
    } else {
      return response(404, { error: 'Not found' });
    }
  } catch (error) {
    console.error('Error:', error);
    // VULNERABILITY: Exposing stack traces and internal errors
    return response(500, {
      error: error.message,
      stack: error.stack,
      details: 'Internal server error'
    });
  }
};

/**
 * VULNERABILITY: No authentication required
 * VULNERABILITY: Returns sensitive data including passwords
 */
async function listUsers(event) {
  // VULNERABILITY: Returns all users with all sensitive fields
  return response(200, mockDatabase.users);
}

/**
 * VULNERABILITY: Mass assignment - allows setting any field including isAdmin
 * VULNERABILITY: No input validation
 */
async function createUser(event) {
  const body = JSON.parse(event.body || '{}');

  // VULNERABILITY: Accepts all fields from request without filtering
  const newUser = {
    id: String(mockDatabase.users.length + 1),
    username: body.username,
    password: body.password, // VULNERABILITY: Stores plain text password
    email: body.email,
    isAdmin: body.isAdmin || false, // VULNERABILITY: User can set their own admin status
    ssn: body.ssn || '',
    creditCard: body.creditCard || '',
    createdAt: new Date().toISOString(),
    // VULNERABILITY: Mass assignment - any field from request is added
    ...body
  };

  mockDatabase.users.push(newUser);

  // VULNERABILITY: Returns sensitive data in response
  return response(201, newUser);
}

/**
 * VULNERABILITY: IDOR - No authorization check
 * Any user can view any other user's data
 */
async function getUserById(event) {
  const userId = event.path.split('/').pop();

  // VULNERABILITY: No authentication or authorization check
  const user = mockDatabase.users.find(u => u.id === userId);

  if (!user) {
    return response(404, { error: 'User not found' });
  }

  // VULNERABILITY: Returns all sensitive fields including password
  return response(200, user);
}

/**
 * VULNERABILITY: Broken access control
 * Any user can update any other user's data
 */
async function updateUser(event) {
  const userId = event.path.split('/').pop();
  const body = JSON.parse(event.body || '{}');

  // VULNERABILITY: No authentication or authorization check
  const userIndex = mockDatabase.users.findIndex(u => u.id === userId);

  if (userIndex === -1) {
    return response(404, { error: 'User not found' });
  }

  // VULNERABILITY: Mass assignment - allows updating any field including isAdmin
  mockDatabase.users[userIndex] = {
    ...mockDatabase.users[userIndex],
    ...body // VULNERABILITY: Directly merges all request data
  };

  return response(200, mockDatabase.users[userIndex]);
}

/**
 * VULNERABILITY: SQL Injection
 * Simulates vulnerable SQL query construction
 */
async function searchUsers(event) {
  const query = event.queryStringParameters?.query || '';

  // VULNERABILITY: Simulated SQL injection
  // In reality, this would construct: SELECT * FROM users WHERE username LIKE '%${query}%'
  console.log(`VULNERABLE SQL: SELECT * FROM users WHERE username LIKE '%${query}%'`);

  // Simulated injection detection for demo purposes
  if (query.includes("'") || query.includes('--') || query.includes(';')) {
    console.log('POTENTIAL SQL INJECTION DETECTED IN DEMO');
    // VULNERABILITY: Still executes the query even with injection characters
    return response(200, {
      message: 'SQL Injection vulnerability demonstrated',
      injectedQuery: `SELECT * FROM users WHERE username LIKE '%${query}%'`,
      note: 'In a real scenario, this could expose or modify database data',
      results: mockDatabase.users // Returns all data
    });
  }

  // Normal search (still vulnerable)
  const results = mockDatabase.users.filter(u =>
    u.username.toLowerCase().includes(query.toLowerCase())
  );

  return response(200, results);
}

/**
 * VULNERABILITY: Information disclosure
 * Exposes sensitive configuration without authentication
 */
async function getConfig(event) {
  // VULNERABILITY: No authentication check
  // VULNERABILITY: Returns sensitive credentials and secrets
  return response(200, mockDatabase.config);
}

/**
 * VULNERABILITY: No rate limiting or authorization
 * Allows mass data export
 */
async function exportData(event) {
  const body = JSON.parse(event.body || '{}');
  const format = body.format || 'json';

  // VULNERABILITY: No authentication or rate limiting
  // VULNERABILITY: Exports all sensitive data

  let exportedData;

  switch (format) {
    case 'csv':
      exportedData = convertToCSV(mockDatabase.users);
      break;
    case 'xml':
      exportedData = convertToXML(mockDatabase.users);
      break;
    default:
      exportedData = mockDatabase.users;
  }

  return response(200, {
    format: format,
    recordCount: mockDatabase.users.length,
    data: exportedData,
    timestamp: new Date().toISOString()
  });
}

/**
 * Helper functions
 */
function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders
    },
    body: JSON.stringify(body)
  };
}

function convertToCSV(data) {
  if (!data || data.length === 0) return '';

  const headers = Object.keys(data[0]).join(',');
  const rows = data.map(obj =>
    Object.values(obj).map(val => `"${val}"`).join(',')
  );

  return headers + '\n' + rows.join('\n');
}

function convertToXML(data) {
  let xml = '<?xml version="1.0" encoding="UTF-8"?>\n<users>\n';

  data.forEach(user => {
    xml += '  <user>\n';
    Object.entries(user).forEach(([key, value]) => {
      xml += `    <${key}>${value}</${key}>\n`;
    });
    xml += '  </user>\n';
  });

  xml += '</users>';
  return xml;
}
