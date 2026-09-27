import assert from 'node:assert/strict';
import { trustedClientIp } from './feedback_guard.js';

function test(name: string, fn: () => void): void {
  try {
    fn();
    console.log(`ok - ${name}`);
  } catch (err) {
    console.error(`fail - ${name}`);
    throw err;
  }
}

test('prefers x-real-ip over spoofed x-forwarded-for values in other headers', () => {
  const ip = trustedClientIp(
    {
      'x-real-ip': '203.0.113.9',
      'x-vercel-forwarded-for': '198.51.100.1',
    },
    '127.0.0.1',
  );
  assert.equal(ip, '203.0.113.9');
});

test('uses x-vercel-forwarded-for when x-real-ip missing', () => {
  const ip = trustedClientIp(
    {
      'x-vercel-forwarded-for': '198.51.100.2, 10.0.0.1',
    },
    '127.0.0.1',
  );
  assert.equal(ip, '198.51.100.2');
});

test('falls back to socket address, never invents from absent headers', () => {
  const ip = trustedClientIp({}, '::ffff:192.0.2.10');
  assert.equal(ip, '::ffff:192.0.2.10');
});

test('returns unknown when nothing trusted is available', () => {
  assert.equal(trustedClientIp({}), 'unknown');
});

console.log('all trustedClientIp tests passed');
