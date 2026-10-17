<script lang="ts">
	import DemoVideo from '#lib/DemoVideo.svelte';
	import ToolHero from '#lib/ToolHero.svelte';
	import GetStarted from '#lib/GetStarted.svelte';
	import Meta from '#lib/Meta.svelte';
	import MoreTools from '#lib/MoreTools.svelte';
	import WhatsNew from '#lib/WhatsNew.svelte';
	import { tool } from '#lib/tools.ts';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const stats = tool('stats');
	const release = $derived(data.releases.stats);

	const sources = [
		[
			'CPU',
			'host_processor_info',
			'User and system time, per core, grouped into efficiency and performance clusters'
		],
		['Memory', 'host_statistics64', 'The same split as Activity Monitor, checked against vm_stat'],
		[
			'Network',
			'NET_RT_IFLIST2, 64-bit',
			'Primary interface only, so VPN traffic isn’t counted twice; checked against netstat'
		],
		['Disk activity', 'IOBlockStorageDriver', 'Per disk, so plugging one in can’t show up as a burst'],
		['GPU', 'IOAccelerator', 'The driver’s own utilisation figure'],
		['Storage', 'volumeAvailableCapacityForImportantUsage', 'The figure Finder shows'],
		['Battery', 'IOKit power sources', 'Time remaining only once macOS has an estimate']
	];
</script>

<Meta
	title="Common Stats — system stats for the macOS menu bar"
	description="Native, minimal system stats for the macOS menu bar: CPU, GPU, memory, network, disk, storage, and battery. Free and open source."
	path="stats/"
	image="stats/poster.jpg"
/>

<main>
	<ToolHero tool={stats} {release} />
	<DemoVideo tool={stats} />

	<section class="features ruled">
		<div>
			<h2>Native.</h2>
			<p>
				The menu bar tints it like the clock. The dropdown is a real menu. Settings looks like System
				Settings. VoiceOver reads every value.
			</p>
		</div>
		<div>
			<h2>Accurate.</h2>
			<p>
				The same kernel counters Activity Monitor reads, with tests that compare them against <code
					>vm_stat</code
				>
				and <code>netstat</code>. A value it can't read shows as a dash, never as zero.
			</p>
		</div>
		<div>
			<h2>Light.</h2>
			<p>
				About 0.1 ms to sample everything and 12 MB of memory. It stops drawing when you can't see it
				and samples less in Low Power Mode.
			</p>
		</div>
		<div>
			<h2>Yours to arrange.</h2>
			<p>
				Each metric shows as a value, a graph, a gauge, or not at all. Drag to reorder. Pick a density
				and how often it updates.
			</p>
		</div>
		<div>
			<h2>Graphs that tell the truth.</h2>
			<p>
				Monotone curves, so smoothing never invents a peak. Rate graphs show their scale, and hovering
				reads back any past value.
			</p>
		</div>
		<div>
			<h2>Private.</h2>
			<p>
				No network access, no analytics, no helper tools, no root. It reads counters and draws them.
			</p>
		</div>
	</section>

	<section class="ruled">
		<h2>Where every number comes from.</h2>
		<p class="muted">Public, unprivileged kernel and IOKit sources only. No private APIs.</p>
		<table>
			<thead><tr><th>Metric</th><th>Source</th><th>Notes</th></tr></thead>
			<tbody>
				{#each sources as [metric, source, note] (metric)}
					<tr><td>{metric}</td><td><code>{source}</code></td><td>{note}</td></tr>
				{/each}
			</tbody>
		</table>
		<p class="muted">
			No temperatures or fans: Apple silicon has no public API for them, and a figure that's silently
			wrong is worse than none.
		</p>
	</section>

	{#if release}<WhatsNew tool={stats} {release} />{/if}
	<GetStarted tool={stats} />
	<MoreTools slug={stats.slug} />
</main>

<style>
	td:first-child {
		font-weight: 500;
		white-space: nowrap;
	}
	td code {
		word-break: break-all;
	}
</style>
