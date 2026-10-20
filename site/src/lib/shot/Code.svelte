<script lang="ts">
	// The editor's code pane at its own size, in the editor's default colours. The window draws it,
	// and so does every picture of the shot (the flight, the preview, the chat, the history), clipped.
	import { code, codeColours, lines, pane, tokenize } from './scene';

	let { dark }: { dark: boolean } = $props();

	const c = $derived(codeColours[dark ? 'dark' : 'light']);
</script>

<div
	class="shot-code"
	style:width="{pane.width}px"
	style:height="{pane.height}px"
	style:background={c.background}
	style:color={c.plain}
>
	{#each lines as line, i (i)}
		<span class="gutter" style:top="{code.top + i * code.line}px" style:color={c.gutter}>{i + 1}</span>
		<span class="line" style:left="{code.left}px" style:top="{code.top + i * code.line}px"
			>{#each tokenize(line) as token, j (j)}<span
					style:color={c[token.kind]}
					style:font-weight={token.kind === 'keyword' ? 600 : null}>{token.text}</span
				>{/each}</span
		>
	{/each}
</div>
