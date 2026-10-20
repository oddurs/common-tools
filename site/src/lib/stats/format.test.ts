import { expect, it } from 'vitest';
import { ago, memory, percent, rate, storage, uptime } from './format';

it('writes numbers the way StatKit.Format does', () => {
	expect(rate(2.44e6)).toBe('2.4 MB/s');
	expect(rate(424e3)).toBe('424 KB/s');
	expect(rate(5.2e3)).toBe('5.2 KB/s');
	expect(rate(953)).toBe('953 B/s');
	expect(rate(999.7e3)).toBe('1.0 MB/s');
	expect(storage(90e9)).toBe('90 GB');
	expect(memory(24 * 1024 ** 3)).toBe('24 GB');
	expect(percent(0.374)).toBe('37%');
	expect(percent(1.2)).toBe('100%');
	expect(uptime(6 * 86_400 + 4 * 3600 + 17 * 60)).toBe('6d 4h');
	expect(ago(0.2)).toBe('now');
	expect(ago(4)).toBe('4s ago');
	expect(ago(74)).toBe('1m 14s ago');
});
