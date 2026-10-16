<script lang="ts">
	import Docs from '#lib/Docs.svelte';
	import Install from '#lib/Install.svelte';
	import { tool } from '#lib/tools.ts';

	const bar = tool('bar');
	const sections: [string, string][] = [
		['install', 'Install'],
		['hide', 'Hide icons'],
		['show', 'Show them again'],
		['always', 'Always-hidden icons'],
		['menu', 'The menu'],
		['options', 'Options'],
		['questions', 'Questions'],
		['source', 'Build from source']
	];
</script>

<Docs tool={bar} {sections}>
	<h2 id="install">Install</h2>
	<Install tool={bar}>
		<li>
			A chevron appears beside the system icons, with a short <b>Tidy Your Menu Bar</b> guide. Right-click the
			chevron and turn on <b>Open at Login</b>.
		</li>
	</Install>

	<h2 id="hide">Hide icons</h2>
	<p>
		Common Bar puts two things in the menu bar: a chevron, and a thin divider to its left. When the bar is
		collapsed, the divider stretches and pushes every icon left of it off-screen.
	</p>
	<ol>
		<li>Hold <kbd>⌘</kbd> with the pointer over the menu bar. After a moment the divider appears.</li>
		<li>Keep holding <kbd>⌘</kbd> and drag icons to the left of the divider. This is macOS's own ⌘-drag.</li>
		<li>Let go of <kbd>⌘</kbd>. Everything left of the divider disappears.</li>
	</ol>
	<p>To bring an icon back for good, hold <kbd>⌘</kbd> and drag it to the right of the divider.</p>

	<h2 id="show">Show them again</h2>
	<ul>
		<li><b>Click the chevron.</b> Click it again to hide.</li>
		<li><b>Hover</b> over empty menu bar space for a moment.</li>
		<li><b>Scroll down</b> on the menu bar, or <b>click its empty space</b>. Scroll up to hide.</li>
	</ul>
	<p>
		Revealed icons hide again by themselves: after eight seconds for a click, or half a second after the
		pointer leaves the bar for a hover. They stay while you're still working in the menu bar or a menu from it
		is open.
	</p>

	<h2 id="always">Always-hidden icons</h2>
	<p>
		A second divider, drawn dotted, marks icons you almost never need. They stay hidden even when the others
		are shown, which matters on a notched display where there's little room.
	</p>
	<ul>
		<li>
			<kbd>⌥</kbd>-click the chevron to show both sections. <kbd>⌥</kbd>-click again to hide everything.
		</li>
		<li>Holding <kbd>⌘</kbd> shows both dividers, so you can drag icons into either section.</li>
	</ul>

	<h2 id="menu">The menu</h2>
	<p>
		Right-click the chevron, or <kbd>⌃</kbd>-click it, for <b>How to Arrange…</b> (the guide again),
		<b>Open at Login</b>, and <b>Quit Common Bar</b>.
	</p>

	<h2 id="options">Options</h2>
	<p>Hover, scroll, and click-to-show are on by default. To turn one off, run any of:</p>
	<pre><code
			>defaults write com.oddurs.reasonal showOnHover -bool false
defaults write com.oddurs.reasonal showOnScroll -bool false
defaults write com.oddurs.reasonal showOnClick -bool false</code
		></pre>
	<p>Then quit and reopen Common Bar. <code>-bool true</code> turns it back on.</p>

	<h2 id="questions">Questions</h2>
	<h3>I can't see the chevron.</h3>
	<p>
		On a crowded notched display it can end up behind the camera housing. Hold <kbd>⌘</kbd> and drag other icons
		out of the way, or quit apps you don't need in the menu bar. Common Bar places itself beside the system icons
		on first launch to avoid this.
	</p>
	<h3>The chevron disappeared with the hidden icons.</h3>
	<p>
		The divider has to be left of the chevron. If it's dragged to the right, Common Bar notices from the
		positions macOS saves and won't stretch it, so the chevron stays visible. Hold <kbd>⌘</kbd> and move the divider
		back.
	</p>
	<h3>Does it need any permissions?</h3>
	<p>No. It watches pointer position and modifier keys, which macOS allows without Accessibility access.</p>

	<h2 id="source">Build from source</h2>
	<p>The Command Line Tools are enough; Xcode is not required.</p>
	<pre><code
			>git clone {bar.repo}
cd common-bar
scripts/task build      # universal build → build/Common Bar.app</code
		></pre>
</Docs>
