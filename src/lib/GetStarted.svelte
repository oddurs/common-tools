<script lang="ts">
	import { resolve } from '$app/paths';
	import { download, type Tool } from './tools';

	let { tool }: { tool: Tool } = $props();
</script>

<section class="ruled">
	<h2>Get started.</h2>
	<ol>
		<li>
			<b>Download</b>
			<span><a href={download(tool)}>{tool.asset}</a>, unzip it, and move {tool.name} to Applications.</span>
		</li>
		<li>
			<b>Open it</b>
			<span>
				The first time, macOS can't verify the developer: choose <b>Open Anyway</b> in System Settings › Privacy
				&amp; Security.
			</span>
		</li>
		<li>
			<b>Set it up</b>
			<span>{tool.firstRun}</span>
		</li>
	</ol>
	<p class="muted">
		Every step, with checksums and the command-line alternative, is in the <a
			href={resolve(`${tool.slug}/docs/`)}>docs</a
		>.
	</p>
</section>

<style>
	ol {
		margin: 16px 0;
		padding: 0;
		list-style: none;
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 40px;
		counter-reset: step;
	}
	li {
		counter-increment: step;
		display: flex;
		flex-direction: column;
		gap: 4px;
		font-size: 15px;
		color: var(--secondary);
	}
	li::before {
		content: counter(step);
		display: grid;
		place-items: center;
		width: 28px;
		height: 28px;
		margin-bottom: 6px;
		border-radius: 50%;
		background: var(--panel);
		color: var(--text);
		font-weight: 600;
	}
	li > b {
		color: var(--text);
		font-size: 17px;
	}
	@media (max-width: 760px) {
		ol {
			grid-template-columns: 1fr;
			gap: 20px;
		}
	}
</style>
