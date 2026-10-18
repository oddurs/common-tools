<script lang="ts">
	import Docs from '#lib/Docs.svelte';
	import Install from '#lib/Install.svelte';
	import { tool } from '#lib/tools.ts';
	import { asset } from '$app/paths';

	const stats = tool('stats');
	const sections: [string, string][] = [
		['install', 'Install'],
		['bar', 'The menu bar item'],
		['menu', 'The menu'],
		['settings', 'Settings'],
		['accuracy', 'Accuracy'],
		['performance', 'Performance'],
		['questions', 'Questions'],
		['source', 'Build from source']
	];
</script>

<Docs tool={stats} {sections}>
	<h2 id="install">Install</h2>
	<Install tool={stats} />
	<p class="callout">
		Upgrading from a copy with the app's earlier name? Common Stats quits it when it first opens and keeps
		your settings; move the old app from Applications to the Trash. If Open at login stops working, turn
		it off and on again.
	</p>

	<h2 id="bar">The menu bar item</h2>
	<p>
		Common Stats draws CPU, GPU, memory, network, disk activity, storage, and battery in one menu bar
		item, in the order you choose. The bar is a template image, so macOS tints it for light and dark menu
		bars, dims it on inactive displays, and adjusts it for Increase Contrast, like the clock.
	</p>
	<img
		src={asset('stats/bar.png')}
		alt="Several bar layouts, in dark and light menu bars: graphs, gauges, and values for CPU, GPU, memory, network, disk, storage, and battery."
		width="930"
		height="336"
	/>
	<p>VoiceOver reads it as a sentence: "CPU 21%, Memory 82%, Network down 6.1 KB/s, up 1.0 KB/s".</p>

	<h2 id="menu">The menu</h2>
	<p>Click the item for a menu of cards:</p>
	<img
		src={asset('stats/bar-menu.png')}
		alt="The menu in light and dark: CPU, Memory, Network, and Disk cards with graphs, and GPU, Storage, and Battery rings."
		width="1424"
		height="1520"
	/>
	<ul>
		<li>
			<b>CPU</b>: user and system time, per-core load grouped into efficiency and performance clusters,
			load average, and uptime.
		</li>
		<li>
			<b>Memory</b>: Activity Monitor's breakdown (App, Wired, Compressed, Cached, Swap) with a pressure
			indicator.
		</li>
		<li><b>Network</b> and <b>Disk</b>: per-interface and per-disk rates.</li>
		<li>
			<b>GPU</b>, <b>Storage</b>, and <b>Battery</b>: rings with utilisation, free space, and time to
			full or empty.
		</li>
	</ul>
	<p>
		Hover any graph to read back a past value. Graphs, gauges, and legends use the colour chosen in
		Settings; only a warning or a critical state shows its own orange or red. <kbd>⌘,</kbd> opens Settings
		and
		<kbd>⌘Q</kbd> quits, as in any menu.
	</p>

	<h2 id="settings">Settings</h2>
	<p>
		Choose <b>Settings…</b> from the menu, press <kbd>⌘,</kbd> while it's open, or open Common Stats again from
		Finder or Spotlight. A live preview of the bar sits at the top.
	</p>
	<h3>Items</h3>
	<p>
		Each metric gets a style: <b>Value</b>, <b>Graph</b>, <b>Graph and Value</b>, <b>Gauge</b>,
		<b>Gauge and Value</b>, or <b>Don't Show</b>. Network and disk offer value and graph styles; storage
		and battery offer value and gauge styles. Drag rows to reorder, or use <b>Move Up</b> and
		<b>Move Down</b> from the context menu or VoiceOver actions.
	</p>
	<h3>Appearance</h3>
	<p>
		<b>Show labels</b> turns the small CPU / MEM captions on or off. <b>Density</b> is Compact, Regular,
		or Spacious. <b>Color</b> is your accent colour, a colour per metric, or one of eight system colours,
		for the menu's graphs, gauges, and legends; beneath the swatches, a bar shows the shades the menu will
		use.
		<b>Color in menu bar</b> carries it into the menu bar, which otherwise stays monochrome.
	</p>
	<h3>General</h3>
	<p><b>Open at login</b>, and <b>Update every</b> 0.5, 1, 2, 3, or 5 seconds.</p>
	<h3>Common Tools</h3>
	<p>The other Common Tools apps, to open or get, and the version of Common Stats you're running.</p>

	<h2 id="accuracy">Accuracy</h2>
	<p>
		Each figure comes from the same kernel source Apple's own tools use, and the tests compare them
		against those tools.
	</p>
	<table>
		<thead><tr><th>Metric</th><th>Source</th></tr></thead>
		<tbody>
			<tr
				><td>CPU</td><td
					><code>host_processor_info</code> tick deltas, wraparound-safe. Clusters from the device
					tree's
					<code>cluster-type</code>.</td
				></tr
			>
			<tr
				><td>Memory</td><td
					><code>host_statistics64</code>. App (anonymous − purgeable) + Wired + Compressed, checked
					against
					<code>vm_stat</code>.</td
				></tr
			>
			<tr
				><td>Network</td><td
					><code>NET_RT_IFLIST2</code> 64-bit counters, primary interface only. Checked against
					<code>netstat</code>.</td
				></tr
			>
			<tr><td>Disk activity</td><td><code>IOBlockStorageDriver</code> statistics, per disk.</td></tr>
			<tr><td>GPU</td><td><code>IOAccelerator</code> performance statistics.</td></tr>
			<tr
				><td>Storage</td><td
					><code>volumeAvailableCapacityForImportantUsage</code>, the figure Finder shows.</td
				></tr
			>
			<tr
				><td>Battery</td><td>IOKit power sources. Time remaining only once macOS has an estimate.</td
				></tr
			>
		</tbody>
	</table>
	<p>
		Rates divide by the time that actually passed, on a clock that keeps counting through sleep. A gap
		longer than 10 seconds restarts the baseline, so a burst isn't averaged over time nobody saw. A value
		Common Stats can't read shows as a dash, never as a made-up zero.
	</p>

	<h2 id="performance">Performance</h2>
	<p>
		On an M4 Pro, sampling all seven metrics takes about 0.1 ms and drawing the bar about 0.3 ms. The
		process uses about 0.5% of one core and 12 MB of memory.
	</p>
	<ul>
		<li>
			Drawing stops while the item can't be seen: behind the notch, collapsed, or under a full-screen
			app. Sampling continues, so graphs have no gaps.
		</li>
		<li>In Low Power Mode it samples half as often, and sampling stops while the displays sleep.</li>
	</ul>

	<h2 id="questions">Questions</h2>
	<h3>The item doesn't appear.</h3>
	<p>
		It may be behind the camera housing or hidden by a menu bar manager such as Common Bar. Open Common
		Stats again from Finder or Spotlight: that opens Settings, which says so while the item is hidden.
		Show fewer items, choose Compact density, or hold <kbd>⌘</kbd> and drag other items out of the way.
	</p>
	<h3>Why no temperatures or fans?</h3>
	<p>
		Apple silicon has no public API for them. The private sensor interfaces change between releases, and a
		figure that is silently wrong is worse than none.
	</p>
	<h3>Why no list of top processes?</h3>
	<p>
		Without root, macOS hides usage for about a fifth of processes, often the busiest ones. Use <b
			>Open Activity Monitor</b
		> in the menu.
	</p>
	<h3>Does it use the network?</h3>
	<p>No. No network access, no analytics, no helper tools, no root.</p>

	<h2 id="source">Build from source</h2>
	<p>The Command Line Tools are enough; Xcode is not required.</p>
	<pre><code
			>git clone https://github.com/oddurs/common-tools
cd common-tools
scripts/task build stats      # universal build → build/stats/Common Stats.app
		></code
		></pre>
</Docs>
