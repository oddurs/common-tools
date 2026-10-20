<script lang="ts">
	// Text with its keyboard shortcuts set as key caps: "Press ⌥Space" shows ⌥Space as a key. A shortcut
	// is one or more modifiers and a key, the way macOS writes them in menus.
	let { text }: { text: string } = $props();

	const shortcut = /([⌃⌥⇧⌘]+(?:Space|Return|Delete|Tab|Esc|[A-Z0-9,←→↑↓]))/;
	const parts = $derived(text.split(shortcut));
</script>

{#each parts as part, i (i)}{#if i % 2}<kbd>{part}</kbd>{:else}{part}{/if}{/each}
