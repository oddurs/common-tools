// The family's promise, written once so every page says the same thing in the same words.
export const promise = {
	/// One line, for heroes and the footer.
	short: 'Free forever · Open source · Nothing leaves your Mac',
	/// The sentence under a title.
	line: 'Free forever. Open source. Nothing you do is ever reported.',
	/// Each part, spelled out.
	parts: [
		[
			'Private.',
			'Nothing you do is ever reported. No analytics, no crash reports, no account, and no network access except an update check that stays off until you turn it on and sends nothing about you. What an app learns stays in one file on your Mac, and you can delete it.'
		],
		[
			'Free.',
			'Completely free, forever. No trial, no subscription, no paid tier, no upgrade prompts. Every app is for everyone.'
		],
		[
			'Open.',
			'Every line is public on GitHub under the MIT license. Read it, build it yourself, change it. Every change is checked by its tests before it merges.'
		],
		[
			'Native.',
			'AppKit and SwiftUI, drawn the way macOS draws its own. Real menus, System Settings layouts, VoiceOver, and out of the way.'
		]
	] as const
};
