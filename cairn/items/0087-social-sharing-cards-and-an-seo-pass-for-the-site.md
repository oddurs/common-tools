---
id: 87
uid: a31ed9cb-26ec-4849-b774-36f9847345e9
title: Social sharing cards and an SEO pass for the site
type: feature
status: done
created: 2026-10-21
updated: 2026-10-21
closed_at: 2026-10-21
priority: p2
area: site
effort: m
---

## Problem

A shared link showed a 16:10 film poster, which link previews crop to 1.91:1, cutting off the menu bar. Titles used the taglines, which never say what an app is or that it's for the Mac. Seven descriptions ran past the 160 characters a result shows, and there was no structured data or sitemap.

## Proposal

A 1200 × 630 card per page, drawn on the site's tokens and photographed by `pnpm film cards`. Titles of the form "<name> — <what it is> for Mac". Descriptions that fit. SoftwareApplication JSON-LD on each app page, WebSite on the home page, and a `sitemap.xml`. All of it from `src/lib/seo.ts`, held by `seo.test.ts`.

## Acceptance criteria

- [x] The home page and every app have a card at 2400 × 1260, and every page's og:image points at one
- [x] Every title is at most 60 characters and names what the app is; every description is at most 160
- [x] App pages carry SoftwareApplication JSON-LD, and the home page WebSite
- [x] sitemap.xml lists the home page, every app, its docs, and the design page, and no film or card page
