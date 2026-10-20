import { describe, expect, it } from 'vitest';
import { render } from 'svelte/server';
import Keys from './Keys.svelte';

const html = (text: string) => render(Keys, { props: { text } }).body.replace(/<!--.*?-->/g, '');

describe('Keys', () => {
	it('sets each shortcut as a key cap and leaves the rest as text', () => {
		expect(html('Press ⌥Space, type, press Return.')).toBe(
			'Press <kbd>⌥Space</kbd>, type, press Return.'
		);
		expect(html('Press ⇧⌘2 or ⌃⇧⌘C.')).toBe('Press <kbd>⇧⌘2</kbd> or <kbd>⌃⇧⌘C</kbd>.');
		expect(html('Scopes on ⌘1–⌘3, actions on ⌘K.')).toBe(
			'Scopes on <kbd>⌘1</kbd>–<kbd>⌘3</kbd>, actions on <kbd>⌘K</kbd>.'
		);
	});
	it('leaves text without a shortcut alone', () => {
		expect(html('Hold ⌥ to copy the text.')).toBe('Hold ⌥ to copy the text.');
	});
});
