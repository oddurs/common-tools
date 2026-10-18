<script lang="ts">
	import Docs from '#lib/Docs.svelte';
	import Install from '#lib/Install.svelte';
	import { tool } from '#lib/tools.ts';

	const bar = tool('bar');
	const sections: [string, string][] = [
		['install', 'Install'],
		['folder', 'The More folder'],
		['open', 'Open an icon'],
		['accessibility', 'Accessibility'],
		['menu', 'The menu'],
		['settings', 'Settings'],
		['questions', 'Questions'],
		['source', 'Build from source']
	];
</script>

<Docs tool={bar} {sections}>
	<h2 id="install">Install</h2>
	<Install tool={bar} />
	<p class="callout">
		On first launch the More folder appears beside the system icons, and every icon left of it moves off
		the menu bar. Right-click More, choose <b>Settings…</b>, and turn on <b>Open at login</b>.
	</p>

	<h2 id="folder">The More folder</h2>
	<p>
		More is the boundary. Icons to its right, and the system's own, stay in the menu bar. Every icon to
		its left is kept off-screen all the time, past the screen's left edge, rather than under the notch or
		behind the app's menus, where macOS would shuffle the bar around it.
	</p>
	<p>
		Each icon is where Common Bar found it: icons you had showing stay, icons you had hidden are in More.
		macOS's own <kbd>⌘</kbd>-drag still moves the icons in the menu bar among themselves.
	</p>

	<h2 id="open">Open an icon</h2>
	<ol>
		<li>Click More. It lists the icons in it, in menu bar order, each with its app's icon and name.</li>
		<li>
			Choose one. Common Bar brings that icon on screen and opens it, as clicking it would: its menu or
			panel drops from the menu bar.
		</li>
		<li>Close the menu, and the icon goes back off-screen.</li>
	</ol>
	<p>
		The icon nearest More opens right beside it. One further along opens where it lands, under the notch
		or behind the app's menus, and the icons between it and More stay out of sight meanwhile.
	</p>

	<h2 id="accessibility">Accessibility</h2>
	<p>
		Tidying the menu bar needs no permission. Listing and opening the icons in More needs Accessibility:
		on macOS 26 every menu bar icon belongs to Control Center as far as the window list is concerned, so
		only Accessibility says which app made each one, and only Accessibility can open it.
	</p>
	<p>
		Common Bar asks the first time you click More, never at launch. Until it's allowed, More says why and
		how many icons it holds, with <b>Allow Accessibility…</b>. If the switch in System Settings is already
		on but More still asks, the switch belongs to an earlier copy of Common Bar;
		<b>Reset and Ask Again</b>
		in More clears it.
	</p>

	<h2 id="menu">The menu</h2>
	<p>
		Right-click More, or <kbd>⌃</kbd>-click it, for <b>Settings…</b> (<kbd>⌘,</kbd>) and
		<b>Quit Common Bar</b>.
	</p>

	<h2 id="settings">Settings</h2>
	<p>
		Open <b>Settings…</b> from the menu, or open Common Bar again from Finder or Spotlight while it's running.
	</p>
	<h3>Folders</h3>
	<p>Whether Accessibility is allowed, with a button to System Settings when it isn't.</p>
	<h3>General</h3>
	<ul>
		<li><b>Open at login</b> starts Common Bar when you log in.</li>
		<li>
			<b>Check for updates daily</b> asks GitHub for the latest release once a day. It's off by default and
			sends nothing about you or your Mac.
		</li>
	</ul>
	<h3>Common Tools</h3>
	<p>The other Common Tools apps, to open or get, and the version of Common Bar you're running.</p>

	<h2 id="questions">Questions</h2>
	<h3>I can't see More.</h3>
	<p>
		On a crowded notched display it can end up behind the camera housing if many icons sit right of it.
		Quit apps you don't need in the menu bar. Common Bar places itself beside the system icons on first
		launch to avoid this.
	</p>
	<h3>Where did my hidden icons go?</h3>
	<p>
		Into More, always-hidden ones included. Earlier versions showed them in the menu bar on a click or a
		hover; on a crowded notched display most landed under the notch, out of sight.
	</p>
	<h3>An icon in More won't open.</h3>
	<p>
		Common Bar opens an icon only once all of it is on screen: a menu opened off-screen can't be seen and
		would still take the keyboard. If an icon can't reach the screen in time, More leaves it be.
	</p>

	<h2 id="source">Build from source</h2>
	<p>The Command Line Tools are enough; Xcode is not required.</p>
	<pre><code
			>git clone https://github.com/oddurs/common-tools
cd common-tools
scripts/task build bar      # universal build → build/bar/Common Bar.app
		></code
		></pre>
</Docs>
