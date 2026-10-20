<script lang="ts">
	// The editor's code pane at its own size, in the editor's default colours. The window draws it,
	// and so does every picture of the shot (the flight, the preview, the chat, the history), clipped.
	import { code, lines, pane } from './scene';

	const keywords = new Set(['public', 'static', 'let', 'func', 'enum', 'return']);
	const types = new Set(['CGFloat', 'CGPoint', 'CGRect', 'Geometry']);

	type Token = { text: string; kind: 'plain' | 'keyword' | 'type' | 'number' | 'comment' };

	function tokens(line: string): Token[] {
		const comment = line.indexOf('///');
		if (comment >= 0)
			return [
				{ text: line.slice(0, comment), kind: 'plain' },
				{ text: line.slice(comment), kind: 'comment' }
			];
		return line.split(/(\b\w+\b)/).map((text) => ({
			text,
			kind: keywords.has(text)
				? 'keyword'
				: types.has(text)
					? 'type'
					: /^\d+$/.test(text)
						? 'number'
						: 'plain'
		}));
	}
</script>

<div
	class="shot-code"
	style:width="{pane.width}px"
	style:height="{pane.height}px"
	style:font-size="{code.size}px"
>
	{#each lines as line, i (i)}
		<span class="gutter" style:top="{code.top + i * code.line}px">{i + 1}</span>
		<span class="line" style:left="{code.left}px" style:top="{code.top + i * code.line}px"
			>{#each tokens(line) as token, j (j)}<span class={token.kind}>{token.text}</span>{/each}</span
		>
	{/each}
</div>
