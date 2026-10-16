<script lang="ts">
	import Cursor from '../Cursor.svelte';
	import Glyph from './Glyph.svelte';
	import { frameAt, metrics } from './demo';

	let { time }: { time: number } = $props();

	const frame = $derived(frameAt(time));
	const notch = metrics.notch;
</script>

<div class="stage" style:opacity={frame.opacity}>
	<!-- A close-up of the right half of the screen, where the menu bar extras live. -->
	<div class="screen">
		<div class="menubar">
			<div class="menus">
				<span class="apple">{''}</span>
				<b>Notes</b><span>File</span><span>Edit</span><span>Format</span><span>View</span><span>Window</span
				><span>Help</span>
			</div>

			<!-- Status items can't be drawn left of the notch, so the area is clipped at its right edge. -->
			<div class="extras" style:left="{notch.right}px">
				<div class="track" style:transform="translateX({-notch.right}px)">
					{#each frame.icons as icon (icon.glyph)}
						<span
							class="icon"
							class:lifted={icon.lifted}
							style:left="{icon.x}px"
							style:opacity={icon.opacity}
						>
							<Glyph glyph={icon.glyph} />
						</span>
					{/each}
					{#if frame.always.opacity > 0}
						<span class="divider dotted" style:left="{frame.always.x}px" style:opacity={frame.always.opacity}
						></span>
					{/if}
					{#if frame.divider.opacity > 0}
						<span class="divider" style:left="{frame.divider.x}px" style:opacity={frame.divider.opacity}
						></span>
					{/if}
					<span class="chevron" style:left="{frame.chevron.x}px">{frame.chevron.open ? '›' : '‹'}</span>
				</div>
			</div>

			<div class="system">
				<svg width="18" height="14" viewBox="0 0 18 14" aria-hidden="true"
					><path d="M1 5 a12 12 0 0 1 16 0 M4 8 a7.5 7.5 0 0 1 10 0" class="s" /><circle
						cx="9"
						cy="11.5"
						r="1.8"
					/></svg
				>
				<svg width="26" height="13" viewBox="0 0 26 13" aria-hidden="true"
					><rect x="0.75" y="0.75" width="21" height="11.5" rx="3.2" class="s" /><rect
						x="3"
						y="3"
						width="16.5"
						height="7"
						rx="1.5"
					/><rect x="23" y="4.5" width="2" height="4" rx="1" /></svg
				>
				<svg width="18" height="14" viewBox="0 0 18 14" aria-hidden="true"
					><rect x="1" y="1" width="16" height="5" rx="2.5" class="s" /><rect
						x="1"
						y="8"
						width="16"
						height="5"
						rx="2.5"
						class="s"
					/><circle cx="4" cy="3.5" r="1.6" /><circle cx="14" cy="10.5" r="1.6" /></svg
				>
				<span class="clock">Thu 9:41</span>
			</div>
		</div>
		<div class="notch" style:left="{notch.left}px" style:width="{notch.right - notch.left}px"></div>

		<section class="window">
			<header><span class="lights"><i></i><i></i><i></i></span><span class="title">Notes</span></header>
			<div class="body">
				<p><b>Tidy up</b></p>
				<p>Fewer icons, same apps.</p>
			</div>
		</section>

		<Cursor x={frame.cursor.x} y={frame.cursor.y} pulse={frame.pulse} />
	</div>

	{#if frame.keys}
		<div class="keys" aria-label="Keys held"><kbd>{frame.keys}</kbd></div>
	{/if}

	{#if frame.caption}
		<p class="caption">{frame.caption}</p>
	{/if}
</div>

<style>
	.stage {
		position: relative;
		width: 1280px;
		height: 800px;
		overflow: hidden;
		background: linear-gradient(160deg, #c9d6ff 0%, #e4e4ea 55%, #f5d7c4 100%);
		font:
			15px/1.4 -apple-system,
			BlinkMacSystemFont,
			'SF Pro Text',
			sans-serif;
		color: #1d1d1f;
		-webkit-font-smoothing: antialiased;
	}
	.screen {
		position: absolute;
		inset: 0;
		transform: scale(1.7);
		transform-origin: top right;
	}
	.menubar {
		position: relative;
		height: 32px;
		background: rgba(246, 246, 246, 0.82);
		backdrop-filter: blur(20px);
		font-size: 14px;
	}
	.menus {
		position: absolute;
		left: 18px;
		top: 0;
		height: 32px;
		display: flex;
		align-items: center;
		gap: 20px;
	}
	.apple {
		font-size: 17px;
	}
	.extras {
		position: absolute;
		top: 0;
		right: 0;
		height: 32px;
		overflow: hidden;
	}
	.track {
		position: relative;
		height: 32px;
	}
	.icon {
		position: absolute;
		top: 7px;
		width: 30px;
		display: flex;
		justify-content: center;
	}
	.icon.lifted {
		top: 9px;
		filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
	}
	.divider {
		position: absolute;
		top: 8px;
		width: 14px;
		height: 16px;
	}
	.divider::after {
		content: '';
		position: absolute;
		left: 6px;
		top: 0;
		bottom: 0;
		width: 2px;
		border-radius: 1px;
		background: #1d1d1f;
	}
	.divider.dotted::after {
		background: none;
		border-left: 2px dotted #1d1d1f;
	}
	.chevron {
		position: absolute;
		top: 2px;
		width: 26px;
		text-align: center;
		font-size: 22px;
		font-weight: 600;
		line-height: 26px;
	}
	.system {
		position: absolute;
		right: 18px;
		top: 0;
		height: 32px;
		display: flex;
		align-items: center;
		gap: 14px;
	}
	.system svg {
		fill: #1d1d1f;
	}
	.system .s {
		fill: none;
		stroke: #1d1d1f;
		stroke-width: 1.5;
		stroke-linecap: round;
	}
	.clock {
		width: 64px;
		text-align: right;
	}
	.notch {
		position: absolute;
		top: 0;
		height: 32px;
		border-radius: 0 0 12px 12px;
		background: #000;
	}

	.window {
		position: absolute;
		left: 740px;
		top: 110px;
		width: 480px;
		height: 240px;
		border-radius: 14px;
		background: #fff;
		box-shadow:
			0 24px 70px rgba(0, 0, 0, 0.22),
			0 0 0 0.5px rgba(0, 0, 0, 0.18);
	}
	header {
		height: 44px;
		display: flex;
		align-items: center;
		padding: 0 16px;
		border-bottom: 1px solid rgba(0, 0, 0, 0.07);
	}
	.lights {
		display: flex;
		gap: 8px;
	}
	.lights i {
		width: 12px;
		height: 12px;
		border-radius: 50%;
		background: #ff5f57;
	}
	.lights i:nth-child(2) {
		background: #febc2e;
	}
	.lights i:nth-child(3) {
		background: #28c840;
	}
	.title {
		flex: 1;
		text-align: center;
		margin-right: 52px;
		font-weight: 600;
		font-size: 14px;
		color: #4a4a4f;
	}
	.body {
		padding: 26px 30px;
		font-size: 24px;
	}
	.body p {
		margin: 0 0 6px;
	}

	.keys {
		position: absolute;
		left: 40px;
		bottom: 40px;
	}
	.keys kbd {
		min-width: 52px;
		height: 52px;
		padding: 0 10px;
		display: grid;
		place-items: center;
		border-radius: 10px;
		background: rgba(255, 255, 255, 0.9);
		box-shadow:
			0 2px 0 rgba(0, 0, 0, 0.18),
			0 0 0 0.5px rgba(0, 0, 0, 0.15);
		font:
			500 26px/1 -apple-system,
			BlinkMacSystemFont,
			sans-serif;
		color: #3a3a3c;
	}
	.caption {
		position: absolute;
		left: 50%;
		bottom: 44px;
		transform: translateX(-50%);
		margin: 0;
		padding: 10px 20px;
		border-radius: 999px;
		background: rgba(29, 29, 31, 0.82);
		backdrop-filter: blur(12px);
		color: #f5f5f7;
		font-size: 20px;
		font-weight: 500;
		white-space: nowrap;
	}
</style>
