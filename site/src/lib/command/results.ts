// What Common Command shows for each query the film types, from CommandKit's own `Results.compose`
// (apps/command/Sources/CommandKit/Results.swift) run over a stock Mac: Apple's apps, the System
// Settings panes and topics of macOS 26, the well-known folders, Notes and Finder running, no usage
// history and no Spotlight files. `bold` is the matched letters; `icon` is a file in ./icons/, or for
// a badge, its SF Symbol.

export type Row = { title: string; subtitle?: string; icon: string; badge?: boolean; bold?: number[] };
export type Section = { title: string; rows: Row[] };

export const results: Record<string, Section[]> = {
	c: [
		{ title: 'Top Hit', rows: [{ title: 'Chess', icon: 'chess', bold: [0] }] },
		{
			title: 'Applications',
			rows: [
				{ title: 'Clock', icon: 'clock', bold: [0] },
				{ title: 'Console', icon: 'console', bold: [0] },
				{ title: 'Calendar', icon: 'calendar', bold: [0] },
				{ title: 'Contacts', icon: 'contacts', bold: [0] },
				{ title: 'Calculator', icon: 'calculator', bold: [0] },
				{ title: 'ColorSync Utility', icon: 'colorsync-utility', bold: [0] }
			]
		},
		{
			title: 'Files',
			rows: [
				{
					title: 'iCloud Drive',
					subtitle: '~/Library/Mobile Documents',
					icon: 'icloud-drive',
					bold: [1]
				},
				{ title: 'Pictures', subtitle: '~', icon: 'pictures', bold: [2] },
				{ title: 'Documents', subtitle: '~', icon: 'documents', bold: [2] },
				{ title: 'Public', subtitle: '~', icon: 'public', bold: [5] },
				{ title: 'Applications', subtitle: '/', icon: 'applications', bold: [5] }
			]
		},
		{ title: 'System Settings', rows: [{ title: 'Classroom', icon: 'system-settings', bold: [0] }] },
		{
			title: 'Search the Web',
			rows: [{ title: 'c', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	ca: [
		{ title: 'Top Hit', rows: [{ title: 'Calendar', icon: 'calendar', bold: [0, 1] }] },
		{
			title: 'Applications',
			rows: [
				{ title: 'Calculator', icon: 'calculator', bold: [0, 1] },
				{ title: 'Contacts', icon: 'contacts', bold: [0, 4] },
				{ title: 'Image Capture', icon: 'image-capture', bold: [6, 7] },
				{ title: 'Boot Camp Assistant', icon: 'boot-camp-assistant', bold: [5, 6] },
				{ title: 'Podcasts', icon: 'podcasts', bold: [3, 4] }
			]
		},
		{
			title: 'System Settings',
			rows: [
				{ title: 'Classroom', icon: 'system-settings', bold: [0, 2] },
				{ title: 'Class Progress', icon: 'system-settings', bold: [0, 2] }
			]
		},
		{
			title: 'Files',
			rows: [
				{ title: 'Applications', subtitle: '/', icon: 'applications', bold: [5, 6] },
				{ title: 'Applications', subtitle: '/System', icon: 'system-applications', bold: [5, 6] }
			]
		},
		{
			title: 'Search the Web',
			rows: [{ title: 'ca', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	cal: [
		{ title: 'Top Hit', rows: [{ title: 'Calendar', icon: 'calendar', bold: [0, 1, 2] }] },
		{ title: 'Applications', rows: [{ title: 'Calculator', icon: 'calculator', bold: [0, 1, 2] }] },
		{
			title: 'System Settings',
			rows: [
				{
					title: 'Display colors and calibration',
					subtitle: 'Displays',
					icon: 'displaysext',
					bold: [19, 20, 21]
				},
				{
					title: 'Allow applications to access Calendar',
					subtitle: 'Privacy & Security',
					icon: 'securityprivacyextension',
					bold: [29, 30, 31]
				}
			]
		},
		{
			title: 'Search the Web',
			rows: [{ title: 'cal', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	d: [
		{ title: 'Top Hit', rows: [{ title: 'Desktop', subtitle: '~', icon: 'desktop', bold: [0] }] },
		{
			title: 'Files',
			rows: [
				{ title: 'Documents', subtitle: '~', icon: 'documents', bold: [0] },
				{ title: 'Downloads', subtitle: '~', icon: 'downloads', bold: [0] },
				{
					title: 'iCloud Drive',
					subtitle: '~/Library/Mobile Documents',
					icon: 'icloud-drive',
					bold: [7]
				}
			]
		},
		{
			title: 'Applications',
			rows: [
				{ title: 'Desk View', icon: 'desk-view', bold: [0] },
				{ title: 'Dictionary', icon: 'dictionary', bold: [0] },
				{ title: 'DVD Player', icon: 'dvd-player', bold: [0] },
				{ title: 'Disk Utility', icon: 'disk-utility', bold: [0] },
				{ title: 'Directory Utility', icon: 'directory-utility', bold: [0] },
				{ title: 'Digital Color Meter', icon: 'digital-color-meter', bold: [0] }
			]
		},
		{
			title: 'System Settings',
			rows: [
				{ title: 'Displays', icon: 'displaysext', bold: [0] },
				{ title: 'Date & Time', icon: 'dateandtime-extension', bold: [0] }
			]
		},
		{
			title: 'Search the Web',
			rows: [{ title: 'd', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	da: [
		{ title: 'Top Hit', rows: [{ title: 'Date & Time', icon: 'dateandtime-extension', bold: [0, 1] }] },
		{ title: 'Files', rows: [{ title: 'Downloads', subtitle: '~', icon: 'downloads', bold: [0, 6] }] },
		{
			title: 'Applications',
			rows: [
				{ title: 'DVD Player', icon: 'dvd-player', bold: [0, 6] },
				{ title: 'Dictionary', icon: 'dictionary', bold: [0, 7] },
				{ title: 'Digital Color Meter', icon: 'digital-color-meter', bold: [0, 5] },
				{ title: 'Calendar', icon: 'calendar', bold: [5, 6] }
			]
		},
		{
			title: 'System Settings',
			rows: [
				{ title: 'Displays', icon: 'displaysext', bold: [0, 5] },
				{ title: 'Device Management', icon: 'profilessettingsext', bold: [0, 8] },
				{ title: 'Show date', subtitle: 'Menu Bar', icon: 'controlcentersettings', bold: [5, 6] }
			]
		},
		{
			title: 'Search the Web',
			rows: [{ title: 'da', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	dar: [
		{ title: 'Top Hit', rows: [{ title: 'Dictionary', icon: 'dictionary', bold: [0, 7, 8] }] },
		{
			title: 'Applications',
			rows: [
				{ title: 'Calendar', icon: 'calendar', bold: [5, 6, 7] },
				{ title: 'DVD Player', icon: 'dvd-player', bold: [0, 6, 9] },
				{ title: 'Digital Color Meter', icon: 'digital-color-meter', bold: [0, 5, 12] }
			]
		},
		{
			title: 'System Settings',
			rows: [
				{
					title: 'Dark Noise',
					subtitle: 'Accessibility',
					icon: 'accessibilitysettingsextension',
					bold: [0, 1, 2]
				},
				{ title: 'Touch ID & Password', icon: 'touch-id-password', bold: [7, 12, 17] }
			]
		},
		{
			title: 'Search the Web',
			rows: [{ title: 'dar', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	dark: [
		{ title: 'Top Hit', rows: [{ title: 'Appearance', icon: 'appearance' }] },
		{
			title: 'System Settings',
			rows: [
				{
					title: 'Dark Noise',
					subtitle: 'Accessibility',
					icon: 'accessibilitysettingsextension',
					bold: [0, 1, 2, 3]
				},
				{ title: 'Illuminate keyboard', subtitle: 'Keyboard', icon: 'keyboardsettings' },
				{
					title: 'Appearance (Keyboard)',
					subtitle: 'Accessibility',
					icon: 'accessibilitysettingsextension'
				},
				{
					title: 'Appearance (Switch Control)',
					subtitle: 'Accessibility',
					icon: 'accessibilitysettingsextension'
				},
				{ title: 'True Tone', subtitle: 'Displays', icon: 'displaysext' },
				{ title: 'Display Brightness', subtitle: 'Displays', icon: 'displaysext' },
				{ title: 'Turn off display when inactive', subtitle: 'Lock Screen', icon: 'lockscreen' }
			]
		},
		{
			title: 'Search the Web',
			rows: [{ title: 'dark', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'dark ': [
		{ title: 'Top Hit', rows: [{ title: 'Appearance', icon: 'appearance' }] },
		{
			title: 'System Settings',
			rows: [
				{
					title: 'Dark Noise',
					subtitle: 'Accessibility',
					icon: 'accessibilitysettingsextension',
					bold: [0, 1, 2, 3]
				},
				{ title: 'Illuminate keyboard', subtitle: 'Keyboard', icon: 'keyboardsettings' },
				{
					title: 'Appearance (Keyboard)',
					subtitle: 'Accessibility',
					icon: 'accessibilitysettingsextension'
				},
				{
					title: 'Appearance (Switch Control)',
					subtitle: 'Accessibility',
					icon: 'accessibilitysettingsextension'
				},
				{ title: 'True Tone', subtitle: 'Displays', icon: 'displaysext' },
				{ title: 'Display Brightness', subtitle: 'Displays', icon: 'displaysext' },
				{ title: 'Turn off display when inactive', subtitle: 'Lock Screen', icon: 'lockscreen' }
			]
		},
		{
			title: 'Search the Web',
			rows: [{ title: 'dark', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'dark m': [
		{ title: 'Top Hit', rows: [{ title: 'Appearance', icon: 'appearance' }] },
		{
			title: 'Search the Web',
			rows: [{ title: 'dark m', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'dark mo': [
		{ title: 'Top Hit', rows: [{ title: 'Appearance', icon: 'appearance' }] },
		{
			title: 'Search the Web',
			rows: [{ title: 'dark mo', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'dark mod': [
		{ title: 'Top Hit', rows: [{ title: 'Appearance', icon: 'appearance' }] },
		{
			title: 'Search the Web',
			rows: [{ title: 'dark mod', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'dark mode': [
		{ title: 'Top Hit', rows: [{ title: 'Appearance', icon: 'appearance' }] },
		{
			title: 'Search the Web',
			rows: [{ title: 'dark mode', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'1': [
		{ title: 'Top Hit', rows: [{ title: '802.1X', subtitle: 'Network', icon: 'network', bold: [4] }] },
		{
			title: 'System Settings',
			rows: [
				{ title: '802.1X certificate', subtitle: 'Network', icon: 'network', bold: [4] },
				{ title: '802.1X authentication', subtitle: 'Network', icon: 'network', bold: [4] },
				{
					title: 'Set up a 126.com account',
					subtitle: 'Internet Accounts',
					icon: 'internetaccountssettingsextension',
					bold: [9]
				},
				{
					title: 'Set up a 163.com account',
					subtitle: 'Internet Accounts',
					icon: 'internetaccountssettingsextension',
					bold: [9]
				}
			]
		},
		{
			title: 'Search the Web',
			rows: [{ title: '1', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10': [
		{
			title: 'Search the Web',
			rows: [{ title: '10', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10 ': [
		{
			title: 'Search the Web',
			rows: [{ title: '10', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10 k': [
		{
			title: 'Search the Web',
			rows: [{ title: '10 k', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10 km': [
		{
			title: 'Search the Web',
			rows: [{ title: '10 km', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10 km ': [
		{
			title: 'Search the Web',
			rows: [{ title: '10 km', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10 km t': [
		{
			title: 'Search the Web',
			rows: [{ title: '10 km t', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10 km to': [
		{
			title: 'Search the Web',
			rows: [{ title: '10 km to', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10 km to ': [
		{
			title: 'Search the Web',
			rows: [{ title: '10 km to', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10 km to m': [
		{ title: 'Conversion', rows: [{ title: '10,000 m', subtitle: 'Copy', icon: 'equal', badge: true }] },
		{
			title: 'Search the Web',
			rows: [{ title: '10 km to m', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	],
	'10 km to mi': [
		{
			title: 'Conversion',
			rows: [{ title: '6.21371 mi', subtitle: 'Copy', icon: 'equal', badge: true }]
		},
		{
			title: 'Search the Web',
			rows: [{ title: '10 km to mi', subtitle: 'Google', icon: 'magnifyingglass', badge: true }]
		}
	]
};
