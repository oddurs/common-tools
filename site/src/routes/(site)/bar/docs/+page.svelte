<script lang="ts">
	import Docs from '#lib/Docs.svelte';
	import Install from '#lib/Install.svelte';
	import { tool } from '#lib/tools.ts';

	const bar = tool('bar');
	const sections: [string, string][] = [
		['install', 'Install'],
		['folder', 'Folders'],
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

	<h2 id="folder">Folders</h2>
	<p>
		Your folders are the boundary. Icons to their right, and the system's own, stay in the menu bar. Every
		icon to their left is kept off-screen all the time, past the screen's left edge, rather than under the
		notch or behind the app's menus, where macOS would shuffle the bar around it.
	</p>
	<p>
		<b>More</b> is always there and holds every icon no other folder does. Add your own in
		<a href="#settings">Settings</a>, give each a name and a symbol, and choose which icons go in it. Each
		folder is its own item in the menu bar, with its name beside its symbol unless you turn names off.
	</p>
	<p>
		Icons you had showing when you first opened this version stay in the menu bar; icons you had hidden
		are in More. macOS's own <kbd>⌘</kbd>-drag still moves the icons in the menu bar among themselves.
	</p>

	<h2 id="open">Open an icon</h2>
	<ol>
		<li>
			Click a folder. It lists its icons, each with its app's icon and name: other apps first, then
			Common Tools, then macOS's own, with a line between them and each app's icons together.
		</li>
		<li>
			Choose one. Its menu opens where the folder's was, one of three ways, depending on how far down
			the folder the icon is.
		</li>
	</ol>
	<ul>
		<li>
			<b>Near the divider:</b> Common Bar brings the icon on screen, moves it in beside the folder with
			the same <kbd>⌘</kbd>-drag you would use (the pointer is hidden for a moment and put back where it
			was), and opens it as clicking it would. Once its menu or panel closes, the icon is dragged back
			to its place, off-screen.
		</li>
		<li>
			<b>Further along:</b> there the icon would land behind the app's menus, where a drag can't start, so
			Common Bar reads the icon's menu through Accessibility without showing it and opens a copy from the
			folder, headed by the icon's name. The item you choose is pressed in the real menu.
		</li>
		<li>
			<b>A panel or popover, not a menu</b> (Wi‑Fi, Battery): it can't be copied, so it opens wherever the
			icon comes on screen, which on a crowded notched display is under the notch or behind the app's menus.
		</li>
	</ul>
	<p>
		If a drag doesn't land, Common Bar opens the icon where it is instead, and if it can't drag it back
		into its place, it puts it left of the divider, off-screen. With <b>Open icons beside their folder</b>
		off in <a href="#settings">Settings</a>, every icon opens wherever it comes on screen.
	</p>

	<h2 id="accessibility">Accessibility</h2>
	<p>
		Tidying the menu bar needs no permission. Listing and opening the icons in a folder needs
		Accessibility: on macOS 26 every menu bar icon belongs to Control Center as far as the window list is
		concerned, so only Accessibility says which app made each one, and only Accessibility can open it or
		move it.
	</p>
	<p>
		Common Bar asks the first time you click a folder, never at launch. Until it's allowed, the folder
		says why and how many icons wait in your folders, with <b>Allow Accessibility…</b>. If the switch in
		System Settings is already on but the folder still asks, the switch belongs to an earlier copy of
		Common Bar;
		<b>Reset and Ask Again</b> in the folder clears it.
	</p>

	<h2 id="menu">The menu</h2>
	<p>
		Right-click a folder, or <kbd>⌃</kbd>-click it, for <b>Settings…</b> (<kbd>⌘,</kbd>) and
		<b>Quit Common Bar</b>.
	</p>

	<h2 id="settings">Settings</h2>
	<p>
		Open <b>Settings…</b> from the menu, or open Common Bar again from Finder or Spotlight while it's running.
	</p>
	<h3>Folders</h3>
	<ul>
		<li>
			Each folder in menu bar order, left to right: its symbol, its name, buttons to move it left or
			right, and one to delete it. More can't be deleted; a deleted folder's icons go back to it.
		</li>
		<li><b>Add Folder</b> adds one at the left.</li>
		<li>
			<b>Show folder names in the menu bar</b> puts each folder's name beside its symbol. It's on to start
			with.
		</li>
	</ul>
	<h3>Icons in Folders</h3>
	<p>
		Every icon left of your folders, with the folder it's in. An icon is remembered by its app and its
		label, or its place among that app's icons when it has none, so it stays in its folder across
		launches.
	</p>
	<h3>Opening Icons</h3>
	<ul>
		<li>
			<b>Open icons beside their folder</b>, described <a href="#open">above</a>. It's on to start with.
		</li>
		<li>Whether Accessibility is allowed, with a button to System Settings when it isn't.</li>
	</ul>
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
	<h3>An icon's menu opened somewhere else, or not at all.</h3>
	<p>
		Common Bar opens an icon only once all of it is on screen: a menu opened off-screen can't be seen and
		would still take the keyboard. An app places its icon's menu from where it last knew the icon to be,
		which can lag behind the move; when a menu opens away from its icon, Common Bar closes it and opens it
		again. Every step is logged:
		<code
			>log show --last 5m --predicate 'subsystem == "com.oddurs.commonbar" AND category == "open"'</code
		>.
	</p>

	<h2 id="source">Build from source</h2>
	<p>The Command Line Tools are enough; Xcode is not required.</p>
	<pre><code
			>git clone https://github.com/oddurs/common-tools
cd common-tools
scripts/task build bar      # build for this Mac → build/bar/Common Bar.app
		></code
		></pre>
</Docs>
